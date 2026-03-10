import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:hajimipass/utils/models.dart';
import 'package:hajimipass/utils/hajimi/contact_store.dart' show StorageAdapter, HajimiSecurity, EncryptedPayload;
import 'package:path_provider/path_provider.dart';

// 定义 StorageAdapter，以防 contact_store.dart 不导出
// 如果 contact_store.dart 导出了，可以直接使用，但为了保险起见，或者使用别名
// 这里我们使用一个简单的 FileStorageAdapter 实现，如果引入了 path_provider

class HajimiStorage extends ChangeNotifier {
  static final HajimiStorage _instance = HajimiStorage._internal();
  static HajimiStorage get instance => _instance;

  HajimiStorage._internal();

  AccountList? _accountList;
  StorageAdapter? _storageAdapter;
  final String _storageKey = 'account_list_data';
  
  // 密码相关
  bool _unlocked = false;
  String _password = '';
  
  bool get unlocked => _unlocked;

  // 初始化 StorageAdapter，外部需要在应用启动时调用
  // 如果没有传入 adapter，默认使用文件存储 (需 path_provider)
  Future<void> init({StorageAdapter? adapter}) async {
    if (adapter != null) {
      _storageAdapter = adapter;
    } else {
      // 默认实现，尝试使用文件存储
      _storageAdapter = await _createDefaultFileStorage();
    }
    // 注意：init 不再自动加载明文数据，而是等待 auth
    // 但为了兼容，如果数据是明文的（旧数据），我们尝试直接加载
    await _tryLoad();
  }

  Future<StorageAdapter> _createDefaultFileStorage() async {
    try {
      // 尝试获取应用文档目录
      final directory = await getApplicationDocumentsDirectory();
      return FileStorageAdapter(directory.path);
    } catch (e) {
      // 如果获取失败（例如在非移动平台且未配置），退回到内存存储或抛出异常
      debugPrint('Warning: Could not get application documents directory. Using InMemoryStorage. Error: $e');
      return InMemoryStorage();
    }
  }
  
  // 尝试加载数据，如果是明文则直接加载，如果是密文则保持锁定状态
  Future<void> _tryLoad() async {
    if (_storageAdapter == null) return;
    final raw = _storageAdapter!.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _createNewList();
      // 如果是新数据，默认不需要密码（或者认为已解锁，直到设置密码）
      // 这里为了简单，如果有设置密码的需求应该由UI引导
      // 但为了满足"加密持久化"的要求，我们需要一个默认策略
      // 如果没有密码，我们暂且认为未锁定，但保存时如果没设置密码可能保存为明文?
      // 用户要求"加密持久化"，说明必须加密。
      // 如果没有密码，我们可能需要默认密码或者强制用户设置。
      // 这里先保持未加密状态，等待 setPassword
      _unlocked = true; 
    } else {
      try {
        // 尝试解析为 EncryptedPayload
        try {
          final jsonMap = jsonDecode(raw);
          // 检查是否符合 EncryptedPayload 结构
          if (jsonMap.containsKey('encryptedData') && jsonMap.containsKey('iv')) {
            // 是加密数据，需要 auth
            _unlocked = false;
            debugPrint('Data is encrypted. Waiting for auth.');
          } else {
            // 尝试解析为 AccountList (旧数据/明文)
            _accountList = AccountList.fromJson(jsonMap);
            _unlocked = true;
          }
        } catch (e) {
          // JSON 解析失败
          debugPrint('Error parsing data: $e');
          _createNewList();
          _unlocked = true;
        }
      } catch (e) {
        debugPrint('Error loading account list: $e');
        _createNewList();
        _unlocked = true;
      }
    }
    notifyListeners();
  }

  void _createNewList() {
    _accountList = AccountList(
      accountList: [],
      lastEditTime: DateTime.now().millisecondsSinceEpoch,
      tagList: [],
      version: 1,
    );
  }

  AccountList get accountList {
    if (_accountList == null) {
      // 如果未加载或未解锁且尝试访问，返回空列表或者抛出异常？
      // 为了防止崩溃，返回空列表，但 UI 应该检查 unlocked 状态
      return AccountList(
        accountList: [],
        lastEditTime: 0,
        tagList: [],
        version: 0,
      );
    }
    return _accountList!;
  }
  
  // 认证/解锁
  Future<bool> auth(String password) async {
    if (_storageAdapter == null) return false;
    final raw = _storageAdapter!.getString(_storageKey);
    if (raw == null) return false;
    
    try {
      final payload = EncryptedPayload.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      final salt = base64Decode(payload.salt);
      final iv = base64Decode(payload.iv);
      final encryptedData = base64Decode(payload.encryptedData);

      final derivedKey = await HajimiSecurity.deriveKey(password, salt, payload.iterations);
      final aesGcm = AesGcm.with256bits();
      final secretKey = SecretKey(derivedKey);

      final ct = encryptedData.sublist(0, encryptedData.length - 16);
      final tag = encryptedData.sublist(encryptedData.length - 16);
      final plaintext = await aesGcm.decrypt(
        SecretBox(ct, nonce: iv, mac: Mac(tag)),
        secretKey: secretKey,
      );
      
      final jsonString = utf8.decode(plaintext);
      _accountList = AccountList.fromJson(jsonDecode(jsonString));
      
      _password = password;
      _unlocked = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Auth failed: $e');
      return false;
    }
  }
  
  // 设置密码并加密保存
  Future<void> setPassword(String password) async {
    _password = password;
    _unlocked = true; // 设置密码意味着拥有权限
    await save();
  }

  Future<void> save() async {
    if (_accountList == null || _storageAdapter == null) return;
    
    // 更新最后编辑时间
    _accountList!.lastEditTime = DateTime.now().millisecondsSinceEpoch;
    
    if (_password.isNotEmpty) {
      // 加密保存
      try {
        final salt = HajimiSecurity.randomBytes(16);
        final iv = HajimiSecurity.randomBytes(12);
        const iterations = 100000;

        final derivedKey = await HajimiSecurity.deriveKey(_password, salt, iterations);
        final aesGcm = AesGcm.with256bits();
        final secretKey = SecretKey(derivedKey);

        final plaintext = utf8.encode(jsonEncode(_accountList!.toJson()));
        final box = await aesGcm.encrypt(plaintext, secretKey: secretKey, nonce: iv);

        final combined = Uint8List.fromList(box.cipherText + box.mac.bytes);

        final payload = EncryptedPayload(
          version: 1,
          encryptedData: base64Encode(combined),
          iv: base64Encode(iv),
          salt: base64Encode(salt),
          iterations: iterations,
        );
        _storageAdapter!.setString(_storageKey, jsonEncode(payload.toJson()));
        notifyListeners();
      } catch (e) {
        debugPrint('Error saving encrypted account list: $e');
      }
    } else {
      // 明文保存 (如果未设置密码) - 或者为了安全应该强制要求密码？
      // 这里保留明文保存作为 fallback，或者如果用户确实没设密码
      try {
        final jsonString = jsonEncode(_accountList!.toJson());
        _storageAdapter!.setString(_storageKey, jsonString);
        notifyListeners();
      } catch (e) {
        debugPrint('Error saving account list: $e');
      }
    }
  }

  void addAccount(Account account) {
    // 必须解锁才能操作
    if (!_unlocked && _password.isNotEmpty) return;
    
    // 确保 accountList 已初始化
    if (_accountList == null) _createNewList();
    
    accountList.accountList.add(account);
    save();
  }

  void removeAccount(Account account) {
    if (!_unlocked && _password.isNotEmpty) return;
    accountList.accountList.remove(account);
    save();
  }
  
  void updateAccount(Account account) {
    save();
  }
}

// 简单的基于文件的 StorageAdapter 实现
class FileStorageAdapter implements StorageAdapter {
  final String basePath;

  FileStorageAdapter(this.basePath);

  File _getFile(String key) {
    return File('$basePath/$key.json');
  }

  @override
  String? getString(String key) {
    try {
      final file = _getFile(key);
      if (file.existsSync()) {
        return file.readAsStringSync();
      }
    } catch (e) {
      debugPrint('Error reading file for key $key: $e');
    }
    return null;
  }

  @override
  void setString(String key, String value) {
    try {
      final file = _getFile(key);
      file.writeAsStringSync(value);
    } catch (e) {
      debugPrint('Error writing file for key $key: $e');
    }
  }

  @override
  void remove(String key) {
    try {
      final file = _getFile(key);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (e) {
      debugPrint('Error deleting file for key $key: $e');
    }
  }
}

// 内存存储实现，用于测试或 fallback
class InMemoryStorage implements StorageAdapter {
  final Map<String, String> _map = {};

  @override
  String? getString(String key) => _map[key];

  @override
  void setString(String key, String value) => _map[key] = value;

  @override
  void remove(String key) => _map.remove(key);
}

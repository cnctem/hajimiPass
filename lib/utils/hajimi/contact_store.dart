import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

import 'package:hajimipass/utils/hajimi/secure_chat_service.dart';

/// 本地加密缓存联系人对称密钥
///
/// @author WIFI连接超时
/// @version 1.0
/// CreateTime: 2025-08-03 03:06

const String _storageKey = 'encrypted_contacts';

typedef ResultStatus = String;
// 'success' | 'fail' | 'access_denied' | 'null_user' | 'duplicate_user'

class EncryptedPayload {
  final int version;
  final String encryptedData; // base64
  final String iv;
  final String salt;
  final int iterations;

  const EncryptedPayload({
    required this.version,
    required this.encryptedData,
    required this.iv,
    required this.salt,
    required this.iterations,
  });

  factory EncryptedPayload.fromJson(Map<String, dynamic> json) => EncryptedPayload(
        version: json['version'] as int,
        encryptedData: json['encryptedData'] as String,
        iv: json['iv'] as String,
        salt: json['salt'] as String,
        iterations: json['iterations'] as int,
      );

  Map<String, dynamic> toJson() => {
        'version': version,
        'encryptedData': encryptedData,
        'iv': iv,
        'salt': salt,
        'iterations': iterations,
      };
}

class HajimiSecurity {
  static Future<List<int>> deriveKey(String password, List<int> salt, int iterations) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    );
    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    return secretKey.extractBytes();
  }

  static List<int> randomBytes(int length) {
    final buf = Uint8List(length);
    // dart:math SecureRandom 不可用时用 cryptography 的
    final rng = SecureRandom.fast;
    for (var i = 0; i < length; i++) {
      buf[i] = rng.nextInt(256);
    }
    return buf;
  }
}

/// 联系人密钥存储，依赖外部 [storage] 实现持久化（SharedPreferences 或其他）
class ContactStore extends ChangeNotifier {
  final StorageAdapter _storage;

  bool _unlocked = false;
  String _password = '';
  final Map<String, Uint8List> _contactMap = {};
  String _currentContact = '';

  bool get unlocked => _unlocked;
  bool get hasClear => _storage.getString(_storageKey) == null;
  bool get hasAuth => _unlocked;
  String get currentContact => _currentContact;
  List<String> get contactList => _unlocked ? (List<String>.from(_contactMap.keys)..sort()) : [];

  ContactStore(StorageAdapter storage) : _storage = storage;

  /// 设置或修改密码
  /// 本地无数据时直接设置；有数据时必须先解锁才能修改
  Future<ResultStatus> setPassword(String pass, String confirm) async {
    final exists = _storage.getString(_storageKey);
    if (exists != null) {
      if (!_unlocked) return 'access_denied';
      if (pass != confirm) return 'fail';
      _password = pass;
      await _save();
      return 'success';
    } else {
      if (pass != confirm) return 'fail';
      _password = pass;
      _unlocked = true;
      _contactMap.clear();
      await _save();
      notifyListeners();
      return 'success';
    }
  }

  /// 用密码解锁，加载联系人数据
  Future<ResultStatus> auth(String pass) async {
    final raw = _storage.getString(_storageKey);
    if (raw == null) return 'fail';

    try {
      final payload = EncryptedPayload.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      final salt = base64Decode(payload.salt);
      final iv = base64Decode(payload.iv);
      final encryptedData = base64Decode(payload.encryptedData);

      final derivedKey = await HajimiSecurity.deriveKey(pass, salt, payload.iterations);
      final aesGcm = AesGcm.with256bits();
      final secretKey = SecretKey(derivedKey);

      // AES-GCM: 末尾 16 字节是 tag，前面是密文
      final ct = encryptedData.sublist(0, encryptedData.length - 16);
      final tag = encryptedData.sublist(encryptedData.length - 16);
      final plaintext = await aesGcm.decrypt(
        SecretBox(ct, nonce: iv, mac: Mac(tag)),
        secretKey: secretKey,
      );

      final obj = jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>;
      _contactMap.clear();
      for (final entry in obj.entries) {
        _contactMap[entry.key] = SecureChatService.hexToUint8Array(entry.value as String);
      }

      _password = pass;
      _unlocked = true;
      _currentContact = _contactMap.keys.isNotEmpty ? _contactMap.keys.first : '';
      notifyListeners();
      return 'success';
    } catch (_) {
      return 'fail';
    }
  }

  /// 获取联系人对称密钥
  Object getSecretKey(String nickname) {
    if (!_unlocked) return 'access_denied';
    return _contactMap[nickname] ?? 'null_user';
  }

  /// 添加联系人及其对称密钥
  Future<ResultStatus> setSecretKey(String nickname, Uint8List key) async {
    if (!_unlocked) return 'access_denied';
    if (_contactMap.containsKey(nickname)) return 'duplicate_user';
    _contactMap[nickname] = key;
    await _save();
    _currentContact = nickname;
    notifyListeners();
    return 'success';
  }

  /// 重命名联系人
  Future<ResultStatus> rename(String oldName, String newName) async {
    if (!_unlocked) return 'access_denied';
    if (!_contactMap.containsKey(oldName)) return 'null_user';
    final value = _contactMap.remove(oldName)!;
    _contactMap[newName] = value;
    await _save();
    notifyListeners();
    return 'success';
  }

  /// 删除联系人
  Future<ResultStatus> remove(String nickname) async {
    if (!_unlocked) return 'access_denied';
    if (!_contactMap.containsKey(nickname)) return 'null_user';
    _contactMap.remove(nickname);
    await _save();
    notifyListeners();
    return 'success';
  }

  /// 清空本地所有数据
  void clear() {
    _storage.remove(_storageKey);
    _contactMap.clear();
    _unlocked = false;
    _password = '';
    _currentContact = '';
    notifyListeners();
  }

  /// 导出加密 payload（用于备份/迁移）
  String exportRaw() => _storage.getString(_storageKey) ?? '';

  /// 导入加密 payload
  ResultStatus importRaw(String payload) {
    try {
      final parsed = jsonDecode(payload) as Map<String, dynamic>;
      if (parsed['version'] is int &&
          parsed['encryptedData'] is String &&
          parsed['iv'] is String &&
          parsed['salt'] is String &&
          parsed['iterations'] is int) {
        _storage.setString(_storageKey, payload);
        return 'success';
      }
      return 'fail';
    } catch (_) {
      return 'fail';
    }
  }

  // --- 内部 ---

  Future<void> _save() async {
    final salt = HajimiSecurity.randomBytes(16);
    final iv = HajimiSecurity.randomBytes(12);
    const iterations = 100000;

    final derivedKey = await HajimiSecurity.deriveKey(_password, salt, iterations);
    final aesGcm = AesGcm.with256bits();
    final secretKey = SecretKey(derivedKey);

    final obj = {
      for (final e in _contactMap.entries)
        e.key: SecureChatService.uint8ArrayToHex(e.value),
    };
    final plaintext = utf8.encode(jsonEncode(obj));
    final box = await aesGcm.encrypt(plaintext, secretKey: secretKey, nonce: iv);

    // 存储格式：ciphertext + tag（16字节）拼接后 base64
    final combined = Uint8List.fromList(box.cipherText + box.mac.bytes);

    final payload = EncryptedPayload(
      version: 1,
      encryptedData: base64Encode(combined),
      iv: base64Encode(iv),
      salt: base64Encode(salt),
      iterations: iterations,
    );
    _storage.setString(_storageKey, jsonEncode(payload.toJson()));
  }
}

/// 存储适配器接口，解耦 SharedPreferences 依赖
abstract class StorageAdapter {
  String? getString(String key);
  void setString(String key, String value);
  void remove(String key);
}

/// 基于 Map 的内存实现（测试用）
class InMemoryStorage implements StorageAdapter {
  final Map<String, String> _map = {};

  @override
  String? getString(String key) => _map[key];

  @override
  void setString(String key, String value) => _map[key] = value;

  @override
  void remove(String key) => _map.remove(key);
}

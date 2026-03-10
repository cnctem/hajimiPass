import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hajimipass/utils/models.dart';
import 'package:hajimipass/utils/hajimi/contact_store.dart' show StorageAdapter;
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

  // 初始化 StorageAdapter，外部需要在应用启动时调用
  // 如果没有传入 adapter，默认使用文件存储 (需 path_provider)
  Future<void> init({StorageAdapter? adapter}) async {
    if (adapter != null) {
      _storageAdapter = adapter;
    } else {
      // 默认实现，尝试使用文件存储
      _storageAdapter = await _createDefaultFileStorage();
    }
    await _load();
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

  Future<void> _load() async {
    if (_storageAdapter == null) return;
    final jsonString = _storageAdapter!.getString(_storageKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final jsonMap = jsonDecode(jsonString);
        _accountList = AccountList.fromJson(jsonMap);
      } catch (e) {
        debugPrint('Error loading account list: $e');
        _createNewList();
      }
    } else {
      _createNewList();
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
      _createNewList();
    }
    return _accountList!;
  }

  Future<void> save() async {
    if (_accountList == null || _storageAdapter == null) return;
    
    // 更新最后编辑时间
    _accountList!.lastEditTime = DateTime.now().millisecondsSinceEpoch;
    
    try {
      final jsonString = jsonEncode(_accountList!.toJson());
      _storageAdapter!.setString(_storageKey, jsonString);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving account list: $e');
    }
  }

  void addAccount(Account account) {
    accountList.accountList.add(account);
    save();
  }

  void removeAccount(Account account) {
    accountList.accountList.remove(account);
    save();
  }
  
  void updateAccount(Account account) {
    // 因为是引用传递，直接修改对象属性后调用 save 即可
    // 这里提供一个显式方法方便语义理解
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

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class JsonSettingStorage {
  final String filePath;
  Map<String, dynamic> _data = {};

  JsonSettingStorage(this.filePath);

  Future<void> load() async {
    final file = File(filePath);
    if (file.existsSync()) {
      try {
        final content = file.readAsStringSync();
        _data = Map<String, dynamic>.from(jsonDecode(content));
      } catch (e) {
        debugPrint('Error loading settings: $e');
        _data = {};
      }
    } else {
      _data = {};
    }
  }

  Future<void> save() async {
    final file = File(filePath);
    await file.writeAsString(jsonEncode(_data));
  }

  T get<T>(String key, {required T defaultValue}) {
    final value = _data[key];
    if (value == null) return defaultValue;
    return value as T;
  }

  Future<void> put(String key, dynamic value) async {
    _data[key] = value;
    await save();
  }

  Future<void> putAll(Map<String, dynamic> values) async {
    _data.addAll(values);
    await save();
  }

  Future<void> replaceAll(Map<String, dynamic> values) async {
    _data = Map<String, dynamic>.from(values);
    await save();
  }

  Future<void> clear() async {
    _data.clear();
    await save();
  }

  Future<void> delete(String key) async {
    _data.remove(key);
    await save();
  }

  Set<String> get keys => _data.keys.toSet();

  Map<String, dynamic> getAll() => Map<String, dynamic>.from(_data);
}

abstract final class GStorage {
  static late final JsonSettingStorage setting;
  static late final JsonSettingStorage localCache;

  static Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      setting = JsonSettingStorage('${dir.path}/setting.json');
      localCache = JsonSettingStorage('${dir.path}/localCache.json');
      await Future.wait([setting.load(), localCache.load()]);
    } catch (e) {
      debugPrint('GStorage init error: $e. Using in-memory storage.');
      // 使用临时目录作为 fallback
      setting = JsonSettingStorage('/tmp/setting.json');
      localCache = JsonSettingStorage('/tmp/localCache.json');
      await Future.wait([setting.load(), localCache.load()]);
    }
  }
}

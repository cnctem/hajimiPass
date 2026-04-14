import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hajimipass/utils/hajimi/contact_store.dart';
import 'package:hajimipass/utils/models.dart';
import 'package:hajimipass/utils/storage/hajimi_storage.dart';
import 'package:hajimipass/utils/storage/storage.dart';
import 'package:hajimipass/utils/storage/storage_key.dart';
import 'package:hajimipass/utils/theme/theme_types.dart';

enum ImportMode { overwrite, merge }

enum ImportResult { success, cancelled, error, passwordRequired }

class ImportResultData {
  final ImportResult result;
  final String? message;
  final AccountImportSummary? accountSummary;
  final int? appliedSettingsCount;

  const ImportResultData({
    required this.result,
    this.message,
    this.accountSummary,
    this.appliedSettingsCount,
  });
}

class ImportService {
  static final ImportService _instance = ImportService._internal();
  static ImportService get instance => _instance;

  ImportService._internal();

  VoidCallback? _onThemeRefresh;

  void setThemeRefreshCallback(VoidCallback callback) {
    _onThemeRefresh = callback;
  }

  Future<ImportResultData> importAccountsFromContent({
    required String content,
    required ImportMode mode,
    String? password,
  }) async {
    try {
      final storage = HajimiStorage.instance;
      if (!storage.unlocked) {
        return const ImportResultData(
          result: ImportResult.error,
          message: '请先解锁账号数据',
        );
      }

      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        return const ImportResultData(
          result: ImportResult.error,
          message: '导入文件格式错误',
        );
      }

      AccountList accountList;
      if (_isEncryptedPayload(decoded)) {
        if (password == null || password.isEmpty) {
          return const ImportResultData(result: ImportResult.passwordRequired);
        }
        accountList = await _decryptAccountList(decoded, password);
      } else {
        if (!_isPlainAccountPayload(decoded)) {
          return const ImportResultData(
            result: ImportResult.error,
            message: '导入失败：不是账号数据格式',
          );
        }
        accountList = AccountList.fromJson(decoded);
      }

      final summary = await storage.importAccounts(
        accountList,
        overwrite: mode == ImportMode.overwrite,
      );

      return ImportResultData(
        result: ImportResult.success,
        accountSummary: summary,
      );
    } catch (e) {
      debugPrint('Import accounts error: $e');
      return ImportResultData(result: ImportResult.error, message: '导入失败: $e');
    }
  }

  Future<ImportResultData> importSettingsFromContent({
    required String content,
    required ImportMode mode,
  }) async {
    try {
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        return const ImportResultData(
          result: ImportResult.error,
          message: '导入文件格式错误',
        );
      }

      final settings = _extractSettingsMap(decoded);
      if (settings == null) {
        return const ImportResultData(
          result: ImportResult.error,
          message: '导入失败：不是设置数据格式',
        );
      }

      final normalized = _normalizeSettings(settings);
      if (normalized.isEmpty) {
        return const ImportResultData(
          result: ImportResult.error,
          message: '导入失败：未识别到有效设置项',
        );
      }
      if (mode == ImportMode.overwrite) {
        await GStorage.setting.replaceAll(normalized);
      } else {
        await GStorage.setting.putAll(normalized);
      }

      _refreshThemeController();

      return ImportResultData(
        result: ImportResult.success,
        appliedSettingsCount: normalized.length,
      );
    } catch (e) {
      debugPrint('Import settings error: $e');
      return ImportResultData(result: ImportResult.error, message: '导入失败: $e');
    }
  }

  Future<String?> pickJsonTextFromFile() async {
    const typeGroup = XTypeGroup(
      label: 'json',
      extensions: ['json'],
      mimeTypes: ['application/json', 'text/plain'],
      webWildCards: ['json'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return null;
    return file.readAsString();
  }

  Future<String?> readTextFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    return (text == null || text.isEmpty) ? null : text;
  }

  bool _isEncryptedPayload(Map<String, dynamic> data) {
    return data['encryptedData'] is String &&
        data['iv'] is String &&
        data['salt'] is String &&
        data['iterations'] is int;
  }

  bool _isPlainAccountPayload(Map<String, dynamic> data) {
    // 导出的账号明文至少包含 accountList 字段，避免把任意 JSON 当成账号数据。
    return data['accountList'] is List;
  }

  Future<AccountList> _decryptAccountList(
    Map<String, dynamic> encrypted,
    String password,
  ) async {
    final payload = EncryptedPayload.fromJson(encrypted);
    final salt = base64Decode(payload.salt);
    final iv = base64Decode(payload.iv);
    final encryptedData = base64Decode(payload.encryptedData);

    final derivedKey = await HajimiSecurity.deriveKey(
      password,
      salt,
      payload.iterations,
    );
    final aesGcm = AesGcm.with256bits();
    final secretKey = SecretKey(derivedKey);

    final ct = encryptedData.sublist(0, encryptedData.length - 16);
    final tag = encryptedData.sublist(encryptedData.length - 16);
    final plaintext = await aesGcm.decrypt(
      SecretBox(ct, nonce: iv, mac: Mac(tag)),
      secretKey: secretKey,
    );

    return AccountList.fromJson(
      jsonDecode(utf8.decode(plaintext)) as Map<String, dynamic>,
    );
  }

  Map<String, dynamic>? _extractSettingsMap(Map<String, dynamic> data) {
    // 账号格式直接拦截，避免误导入。
    if (data['accountList'] is List<dynamic>) {
      return null;
    }

    if (data['settings'] is Map) {
      final nested = Map<String, dynamic>.from(data['settings'] as Map);
      return _containsKnownSettingKey(nested) ? nested : null;
    }

    if (_containsKnownSettingKey(data)) {
      return Map<String, dynamic>.from(data);
    }

    return null;
  }

  Map<String, dynamic> _normalizeSettings(Map<String, dynamic> input) {
    final normalized = <String, dynamic>{};
    for (final entry in input.entries) {
      final key = entry.key;
      final value = _normalizeSettingValue(key, entry.value);
      if (value != null) {
        normalized[key] = value;
      }
    }
    return normalized;
  }

  dynamic _normalizeSettingValue(String key, dynamic value) {
    switch (key) {
      case SettingBoxKey.themeMode:
        if (value is num) {
          final index = value.toInt();
          if (index >= 0 && index < ThemeType.values.length) {
            return index;
          }
        }
        return null;
      case SettingBoxKey.isPureBlackTheme:
      case SettingBoxKey.dynamicColor:
      case SettingBoxKey.darkVideoPage:
        return value is bool ? value : null;
      case SettingBoxKey.schemeVariant:
      case SettingBoxKey.customColor:
      case SettingBoxKey.appFontWeight:
        return value is num ? value.toInt() : null;
      case SettingBoxKey.defaultTextScale:
        return value is num ? value.toDouble() : null;
      case SettingBoxKey.passwordHint:
      case SettingBoxKey.webdavUri:
      case SettingBoxKey.webdavUsername:
      case SettingBoxKey.webdavPassword:
      case SettingBoxKey.webdavDirectory:
        return value is String ? value : null;
      default:
        return value;
    }
  }

  bool _containsKnownSettingKey(Map<String, dynamic> data) {
    for (final key in _knownSettingKeys) {
      if (data.containsKey(key)) return true;
    }
    return false;
  }

  static const Set<String> _knownSettingKeys = {
    SettingBoxKey.themeMode,
    SettingBoxKey.isPureBlackTheme,
    SettingBoxKey.schemeVariant,
    SettingBoxKey.dynamicColor,
    SettingBoxKey.defaultTextScale,
    SettingBoxKey.customColor,
    SettingBoxKey.passwordHint,
    SettingBoxKey.appFontWeight,
    SettingBoxKey.darkVideoPage,
    SettingBoxKey.webdavUri,
    SettingBoxKey.webdavUsername,
    SettingBoxKey.webdavPassword,
    SettingBoxKey.webdavDirectory,
  };

  void _refreshThemeController() {
    _onThemeRefresh?.call();
  }
}

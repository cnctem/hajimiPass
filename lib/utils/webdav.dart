import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hajimipass/utils/constants.dart';
import 'package:hajimipass/utils/export/import_service.dart';
import 'package:hajimipass/utils/storage/hajimi_storage.dart';
import 'package:hajimipass/utils/storage/storage.dart';
import 'package:hajimipass/utils/storage/storage_pref.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

class WebDavResult {
  final bool success;
  final String? message;

  const WebDavResult({required this.success, this.message});
}

class WebDavService {
  WebDavService._internal();
  static final WebDavService instance = WebDavService._internal();

  webdav.Client? _client;
  String _remoteDirectory = '/';

  Future<WebDavResult> initFromPref() async {
    final uri = Pref.webdavUri.trim();
    final username = Pref.webdavUsername.trim();
    final password = Pref.webdavPassword;
    var directory = Pref.webdavDirectory.trim();

    if (uri.isEmpty) {
      return const WebDavResult(success: false, message: '请先填写 WebDAV 地址');
    }

    if (directory.isEmpty) {
      directory = '/';
    }
    if (!directory.startsWith('/')) {
      directory = '/$directory';
    }
    if (!directory.endsWith('/')) {
      directory = '$directory/';
    }
    _remoteDirectory = '${directory}hajimipass';

    try {
      _client = null;
      final client = webdav.newClient(uri, user: username, password: password)
        ..setHeaders({'accept-charset': 'utf-8'})
        ..setConnectTimeout(12000)
        ..setReceiveTimeout(12000)
        ..setSendTimeout(12000);

      await client.mkdirAll(_remoteDirectory);
      _client = client;
      return const WebDavResult(success: true);
    } catch (e) {
      return WebDavResult(success: false, message: e.toString());
    }
  }

  Future<WebDavResult> testConnection() async {
    final result = await initFromPref();
    if (!result.success) {
      SmartDialog.showToast('连接失败: ${result.message}');
      return result;
    }
    SmartDialog.showToast('连接成功');
    return result;
  }

  Future<WebDavResult> backupSettings() async {
    final ready = await _ensureClient();
    if (!ready.success) {
      SmartDialog.showToast('备份设置失败: ${ready.message}');
      return ready;
    }

    try {
      final payload = {
        'version': 1,
        'exportTime': DateTime.now().toIso8601String(),
        'settings': GStorage.setting.getAll(),
      };
      final data = jsonEncode(payload);
      final path = '$_remoteDirectory/${_settingsFileName()}';
      await _write(path, data);
      SmartDialog.showToast('WebDAV 备份设置成功');
      return const WebDavResult(success: true);
    } catch (e) {
      SmartDialog.showToast('备份设置失败: $e');
      return WebDavResult(success: false, message: e.toString());
    }
  }

  Future<WebDavResult> restoreSettings({required ImportMode mode}) async {
    final ready = await _ensureClient();
    if (!ready.success) {
      SmartDialog.showToast('恢复设置失败: ${ready.message}');
      return ready;
    }

    try {
      final path = '$_remoteDirectory/${_settingsFileName()}';
      final bytes = await _client!.read(path);
      final content = utf8.decode(bytes);
      final result = await ImportService.instance.importSettingsFromContent(
        content: content,
        mode: mode,
      );
      if (result.result == ImportResult.success) {
        SmartDialog.showToast(
          'WebDAV 恢复设置成功，应用 ${result.appliedSettingsCount ?? 0} 项',
        );
        return const WebDavResult(success: true);
      }

      SmartDialog.showToast(result.message ?? '恢复设置失败');
      return WebDavResult(success: false, message: result.message);
    } catch (e) {
      SmartDialog.showToast('恢复设置失败: $e');
      return WebDavResult(success: false, message: e.toString());
    }
  }

  Future<WebDavResult> backupAccounts() async {
    final ready = await _ensureClient();
    if (!ready.success) {
      SmartDialog.showToast('备份账号失败: ${ready.message}');
      return ready;
    }

    final storage = HajimiStorage.instance;
    if (!storage.unlocked) {
      SmartDialog.showToast('请先解锁账号数据后再进行 WebDAV 备份');
      return const WebDavResult(success: false, message: '账号未解锁');
    }

    try {
      final data = storage.exportRawAccountPayload();
      if (data.isEmpty) {
        SmartDialog.showToast('备份账号失败：本地账号数据为空');
        return const WebDavResult(success: false, message: '本地账号数据为空');
      }
      final path = '$_remoteDirectory/${_accountsFileName()}';
      await _write(path, data);
      SmartDialog.showToast('WebDAV 备份账号成功');
      return const WebDavResult(success: true);
    } catch (e) {
      SmartDialog.showToast('备份账号失败: $e');
      return WebDavResult(success: false, message: e.toString());
    }
  }

  Future<WebDavResult> restoreAccounts({required ImportMode mode}) async {
    final ready = await _ensureClient();
    if (!ready.success) {
      SmartDialog.showToast('恢复账号失败: ${ready.message}');
      return ready;
    }

    try {
      final path = '$_remoteDirectory/${_accountsFileName()}';
      final bytes = await _client!.read(path);
      final content = utf8.decode(bytes);
      if (mode == ImportMode.overwrite) {
        await HajimiStorage.instance.importRawAccountPayload(content);
        SmartDialog.showToast('WebDAV 恢复账号成功：已覆盖本地账号数据');
        return const WebDavResult(success: true);
      }

      final summary = await HajimiStorage.instance.mergeFromRawAccountPayload(
        content,
      );
      SmartDialog.showToast(
        'WebDAV 恢复账号成功：新增 ${summary.addedCount}，更新 ${summary.updatedCount}，跳过 ${summary.skippedCount}',
      );
      return const WebDavResult(success: true);
    } catch (e) {
      SmartDialog.showToast('恢复账号失败: $e');
      return WebDavResult(success: false, message: e.toString());
    }
  }

  Future<WebDavResult> _ensureClient() async {
    if (kIsWeb) {
      return const WebDavResult(success: false, message: 'Web 平台暂不支持 WebDAV');
    }
    if (_client != null) {
      return const WebDavResult(success: true);
    }
    return initFromPref();
  }

  Future<void> _write(String path, String data) async {
    try {
      await _client!.remove(path);
    } catch (_) {}
    await _client!.write(path, utf8.encode(data));
  }

  String _settingsFileName() => '${Constants.appName}_settings.json';
  String _accountsFileName() => '${Constants.appName}_accounts.json';
}

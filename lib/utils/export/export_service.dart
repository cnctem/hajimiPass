import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hajimipass/utils/hajimi/contact_store.dart';
import 'package:hajimipass/utils/models.dart';
import 'package:hajimipass/utils/storage/hajimi_storage.dart';
import 'package:hajimipass/utils/storage/storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

enum ExportType {
  accountPlaintextJson,
  accountPlaintextTxt,
  accountEncryptedJson,
  settingsJson,
  settingsClipboard,
}

enum ExportResult {
  success,
  cancelled,
  error,
}

class ExportResultData {
  final ExportResult result;
  final String? filePath;
  final String? errorMessage;

  const ExportResultData({
    required this.result,
    this.filePath,
    this.errorMessage,
  });
}

class ExportService {
  static final ExportService _instance = ExportService._internal();
  static ExportService get instance => _instance;

  ExportService._internal();

  Future<ExportResultData> exportAccounts({
    required ExportType type,
    String? password,
  }) async {
    try {
      final hajimiStorage = HajimiStorage.instance;
      if (!hajimiStorage.unlocked) {
        return const ExportResultData(
          result: ExportResult.error,
          errorMessage: '请先解锁账号数据',
        );
      }

      final accountList = hajimiStorage.accountList;
      String content;
      String fileName;
      String mimeType;

      switch (type) {
        case ExportType.accountPlaintextJson:
          content = const JsonEncoder.withIndent('  ').convert(
            accountList.toJson(),
          );
          fileName = _generateFileName('accounts', 'json');
          mimeType = 'application/json';
          break;

        case ExportType.accountPlaintextTxt:
          content = _accountListToTxt(accountList);
          fileName = _generateFileName('accounts', 'txt');
          mimeType = 'text/plain';
          break;

        case ExportType.accountEncryptedJson:
          if (password == null || password.isEmpty) {
            return const ExportResultData(
              result: ExportResult.error,
              errorMessage: '请输入加密密码',
            );
          }
          content = await _encryptAccountList(accountList, password);
          fileName = _generateFileName('accounts_encrypted', 'json');
          mimeType = 'application/json';
          break;

        default:
          return const ExportResultData(
            result: ExportResult.error,
            errorMessage: '不支持的导出类型',
          );
      }

      return await _saveFile(
        content: content,
        fileName: fileName,
        mimeType: mimeType,
      );
    } catch (e) {
      debugPrint('Export accounts error: $e');
      return ExportResultData(
        result: ExportResult.error,
        errorMessage: '导出失败: $e',
      );
    }
  }

  Future<ExportResultData> exportSettings({
    required ExportType type,
  }) async {
    try {
      switch (type) {
        case ExportType.settingsJson:
          final settingsData = await _getSettingsData();
          final content = const JsonEncoder.withIndent('  ').convert(
            settingsData,
          );
          final fileName = _generateFileName('settings', 'json');
          return await _saveFile(
            content: content,
            fileName: fileName,
            mimeType: 'application/json',
          );

        case ExportType.settingsClipboard:
          final settingsData = await _getSettingsData();
          final content = const JsonEncoder.withIndent('  ').convert(
            settingsData,
          );
          await Clipboard.setData(ClipboardData(text: content));
          return const ExportResultData(result: ExportResult.success);

        default:
          return const ExportResultData(
            result: ExportResult.error,
            errorMessage: '不支持的导出类型',
          );
      }
    } catch (e) {
      debugPrint('Export settings error: $e');
      return ExportResultData(
        result: ExportResult.error,
        errorMessage: '导出失败: $e',
      );
    }
  }

  Future<Map<String, dynamic>> _getSettingsData() async {
    return {
      'version': 1,
      'exportTime': DateTime.now().toIso8601String(),
      'settings': GStorage.setting.getAll(),
    };
  }

  String _accountListToTxt(AccountList accountList) {
    final buffer = StringBuffer();
    buffer.writeln('=== HajimiPass 账号导出 ===');
    buffer.writeln('导出时间: ${DateTime.now().toLocal()}');
    buffer.writeln('账号数量: ${accountList.accountList.length}');
    buffer.writeln('');

    for (var i = 0; i < accountList.accountList.length; i++) {
      final account = accountList.accountList[i];
      buffer.writeln('--- 账号 ${i + 1} ---');
      buffer.writeln('名称: ${account.name}');
      buffer.writeln('收藏: ${account.favorite ? '是' : '否'}');
      if (account.tagList.isNotEmpty) {
        buffer.writeln(
          '标签: ${account.tagList.map((t) => t.tagName).join(', ')}',
        );
      }
      buffer.writeln('字段:');
      for (final item in account.accountItemList) {
        buffer.writeln('  ${item.itemName}: ${item.itemValue}');
      }
      buffer.writeln('');
    }

    return buffer.toString();
  }

  Future<String> _encryptAccountList(
    AccountList accountList,
    String password,
  ) async {
    final salt = HajimiSecurity.randomBytes(16);
    final iv = HajimiSecurity.randomBytes(12);
    const iterations = 100000;

    final derivedKey = await HajimiSecurity.deriveKey(
      password,
      salt,
      iterations,
    );
    final aesGcm = AesGcm.with256bits();
    final secretKey = SecretKey(derivedKey);

    final plaintext = utf8.encode(jsonEncode(accountList.toJson()));
    final box = await aesGcm.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: iv,
    );

    final combined = Uint8List.fromList(box.cipherText + box.mac.bytes);

    final payload = EncryptedPayload(
      version: 1,
      encryptedData: base64Encode(combined),
      iv: base64Encode(iv),
      salt: base64Encode(salt),
      iterations: iterations,
    );

    return jsonEncode(payload.toJson());
  }

  String _generateFileName(String prefix, String extension) {
    final now = DateTime.now();
    final timestamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    return '${prefix}_$timestamp.$extension';
  }

  Future<ExportResultData> _saveFile({
    required String content,
    required String fileName,
    required String mimeType,
  }) async {
    if (kIsWeb) {
      return const ExportResultData(
        result: ExportResult.error,
        errorMessage: 'Web平台暂不支持文件导出',
      );
    }

    if (Platform.isAndroid || Platform.isIOS) {
      return await _saveFileMobile(content, fileName, mimeType);
    } else {
      return await _saveFileDesktop(content, fileName);
    }
  }

  Future<ExportResultData> _saveFileMobile(
    String content,
    String fileName,
    String mimeType,
  ) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File(p.join(tempDir.path, fileName));
      await file.writeAsString(content);

      return ExportResultData(
        result: ExportResult.success,
        filePath: file.path,
      );
    } catch (e) {
      debugPrint('Mobile save error: $e');
      return ExportResultData(
        result: ExportResult.error,
        errorMessage: '保存文件失败: $e',
      );
    }
  }

  Future<ExportResultData> _saveFileDesktop(
    String content,
    String fileName,
  ) async {
    try {
      String? savePath;

      if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
        savePath = await _showSaveDialog(fileName);
      }

      if (savePath == null) {
        return const ExportResultData(result: ExportResult.cancelled);
      }

      final file = File(savePath);
      await file.writeAsString(content);

      return ExportResultData(
        result: ExportResult.success,
        filePath: savePath,
      );
    } catch (e) {
      debugPrint('Desktop save error: $e');
      return ExportResultData(
        result: ExportResult.error,
        errorMessage: '保存文件失败: $e',
      );
    }
  }

  Future<String?> _showSaveDialog(String defaultFileName) async {
    final result = await Process.run(
      'osascript',
      [
        '-e',
        '''
        set defaultName to "$defaultFileName"
        set theFile to choose file name default name defaultName
        return POSIX path of theFile
        ''',
      ],
    );

    if (result.exitCode == 0) {
      return (result.stdout as String).trim();
    }
    return null;
  }
}

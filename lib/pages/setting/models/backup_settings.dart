import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hajimipass/pages/setting/models/model.dart';
import 'package:hajimipass/utils/export/export_service.dart';
import 'package:hajimipass/utils/export/import_service.dart';
import 'package:hajimipass/utils/platform_utils.dart';

enum _ImportSource { file, clipboard, manual }

enum _ImportTarget { accounts, settings }

List<SettingsModel> get backupSettings {
  return [
    NormalModel(
      title: '导出账号信息',
      subtitle: '导出所有账号数据',
      leading: const Icon(Icons.account_box_outlined),
      onTap: (context, setState) => _showAccountExportDialog(context),
    ),
    NormalModel(
      title: '导出设置项',
      subtitle: '导出应用设置',
      leading: const Icon(Icons.settings_outlined),
      onTap: (context, setState) => _showSettingsExportDialog(context),
    ),
    NormalModel(
      title: '导入账号信息',
      subtitle: '支持覆盖导入和合并导入',
      leading: const Icon(Icons.account_circle_outlined),
      onTap: (context, setState) => _showAccountImportDialog(context),
    ),
    NormalModel(
      title: '导入设置项',
      subtitle: '支持覆盖导入和合并导入',
      leading: const Icon(Icons.settings_backup_restore_outlined),
      onTap: (context, setState) => _showSettingsImportDialog(context),
    ),
  ];
}

void _showAccountExportDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            title: Text(
              '导出账号信息',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('明文导出 (JSON)'),
            subtitle: const Text('导出为JSON格式，数据可读'),
            onTap: () {
              Navigator.pop(context);
              _exportAccounts(context, ExportType.accountPlaintextJson);
            },
          ),
          ListTile(
            leading: const Icon(Icons.text_snippet_outlined),
            title: const Text('明文导出 (TXT)'),
            subtitle: const Text('导出为文本格式，方便阅读'),
            onTap: () {
              Navigator.pop(context);
              _exportAccounts(context, ExportType.accountPlaintextTxt);
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('密文导出 (JSON)'),
            subtitle: const Text('加密导出，需要输入密码'),
            onTap: () {
              Navigator.pop(context);
              _showEncryptPasswordDialog(context);
            },
          ),
        ],
      ),
    ),
  );
}

void _showSettingsExportDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            title: Text('导出设置项', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('导出为JSON'),
            subtitle: const Text('导出为JSON格式文件'),
            onTap: () {
              Navigator.pop(context);
              _exportSettings(context, ExportType.settingsJson);
            },
          ),
          ListTile(
            leading: const Icon(Icons.content_copy),
            title: const Text('复制到剪贴板'),
            subtitle: const Text('将设置复制到剪贴板'),
            onTap: () async {
              Navigator.pop(context);
              final result = await ExportService.instance.exportSettings(
                type: ExportType.settingsClipboard,
              );
              if (result.result == ExportResult.success) {
                SmartDialog.showToast('已复制到剪贴板');
              } else {
                SmartDialog.showToast(result.errorMessage ?? '导出失败');
              }
            },
          ),
        ],
      ),
    ),
  );
}

void _showAccountImportDialog(BuildContext context) {
  final parentContext = context;
  showModalBottomSheet(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            title: Text(
              '导入账号信息',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('支持明文JSON和密文JSON'),
          ),
          ListTile(
            leading: const Icon(Icons.file_open_outlined),
            title: const Text('从文件导入'),
            subtitle: const Text('选择JSON文件'),
            onTap: () {
              Navigator.pop(sheetContext);
              _startImport(
                parentContext,
                _ImportTarget.accounts,
                _ImportSource.file,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.content_paste_outlined),
            title: const Text('从剪贴板导入'),
            subtitle: const Text('读取剪贴板中的JSON'),
            onTap: () {
              Navigator.pop(sheetContext);
              _startImport(
                parentContext,
                _ImportTarget.accounts,
                _ImportSource.clipboard,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_note_outlined),
            title: const Text('手动粘贴JSON'),
            subtitle: const Text('直接输入或粘贴JSON文本'),
            onTap: () {
              Navigator.pop(sheetContext);
              _startImport(
                parentContext,
                _ImportTarget.accounts,
                _ImportSource.manual,
              );
            },
          ),
        ],
      ),
    ),
  );
}

void _showSettingsImportDialog(BuildContext context) {
  final parentContext = context;
  showModalBottomSheet(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            title: Text('导入设置项', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('支持设置导出JSON或纯设置JSON'),
          ),
          ListTile(
            leading: const Icon(Icons.file_open_outlined),
            title: const Text('从文件导入'),
            subtitle: const Text('选择JSON文件'),
            onTap: () {
              Navigator.pop(sheetContext);
              _startImport(
                parentContext,
                _ImportTarget.settings,
                _ImportSource.file,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.content_paste_outlined),
            title: const Text('从剪贴板导入'),
            subtitle: const Text('读取剪贴板中的JSON'),
            onTap: () {
              Navigator.pop(sheetContext);
              _startImport(
                parentContext,
                _ImportTarget.settings,
                _ImportSource.clipboard,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_note_outlined),
            title: const Text('手动粘贴JSON'),
            subtitle: const Text('直接输入或粘贴JSON文本'),
            onTap: () {
              Navigator.pop(sheetContext);
              _startImport(
                parentContext,
                _ImportTarget.settings,
                _ImportSource.manual,
              );
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> _startImport(
  BuildContext context,
  _ImportTarget target,
  _ImportSource source,
) async {
  var loadingShown = false;
  try {
    if (!context.mounted) {
      SmartDialog.showToast('页面已关闭，导入已取消');
      return;
    }

    final content = await _readImportContent(context, source);
    if (!context.mounted) {
      SmartDialog.showToast('页面已关闭，导入已取消');
      return;
    }
    if (content == null || content.trim().isEmpty) {
      SmartDialog.showToast('导入失败：未获取到可导入内容');
      return;
    }

    final mode = await _showImportModeDialog(context, target);
    if (!context.mounted) {
      SmartDialog.showToast('页面已关闭，导入已取消');
      return;
    }
    if (mode == null) {
      SmartDialog.showToast('已取消导入');
      return;
    }

    SmartDialog.showLoading(msg: '正在导入...');
    loadingShown = true;

    if (target == _ImportTarget.accounts) {
      var result = await ImportService.instance.importAccountsFromContent(
        content: content,
        mode: mode,
      );

      if (result.result == ImportResult.passwordRequired) {
        SmartDialog.dismiss();
        loadingShown = false;
        if (!context.mounted) {
          SmartDialog.showToast('页面已关闭，导入已取消');
          return;
        }
        final password = await _showPasswordDialog(context, '请输入导入文件密码');
        if (!context.mounted) {
          SmartDialog.showToast('页面已关闭，导入已取消');
          return;
        }
        if (password == null || password.isEmpty) {
          SmartDialog.showToast('已取消导入');
          return;
        }
        SmartDialog.showLoading(msg: '正在导入...');
        loadingShown = true;
        result = await ImportService.instance.importAccountsFromContent(
          content: content,
          mode: mode,
          password: password,
        );
      }

      _handleAccountImportResult(result, mode);
      return;
    }

    final result = await ImportService.instance.importSettingsFromContent(
      content: content,
      mode: mode,
    );

    _handleSettingsImportResult(result, mode);
  } catch (e) {
    SmartDialog.showToast('导入失败: $e');
  } finally {
    if (loadingShown) {
      SmartDialog.dismiss();
    }
  }
}

Future<String?> _readImportContent(BuildContext context, _ImportSource source) {
  switch (source) {
    case _ImportSource.file:
      return ImportService.instance.pickJsonTextFromFile();
    case _ImportSource.clipboard:
      return ImportService.instance.readTextFromClipboard();
    case _ImportSource.manual:
      return _showManualInputDialog(context);
  }
}

Future<ImportMode?> _showImportModeDialog(
  BuildContext context,
  _ImportTarget target,
) {
  return showDialog<ImportMode>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(target == _ImportTarget.accounts ? '账号导入模式' : '设置导入模式'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.file_download_done_outlined),
            title: const Text('覆盖导入'),
            subtitle: Text(
              target == _ImportTarget.accounts ? '本地账号将被替换' : '本地设置将被替换',
            ),
            onTap: () => Navigator.pop(dialogContext, ImportMode.overwrite),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.merge_type_outlined),
            title: const Text('合并导入'),
            subtitle: Text(
              target == _ImportTarget.accounts
                  ? '按名称合并，较新数据覆盖旧数据'
                  : '仅更新导入内包含的设置项',
            ),
            onTap: () => Navigator.pop(dialogContext, ImportMode.merge),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('取消'),
        ),
      ],
    ),
  );
}

Future<String?> _showManualInputDialog(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('粘贴JSON内容'),
      content: TextField(
        controller: controller,
        maxLines: 10,
        minLines: 6,
        decoration: const InputDecoration(
          hintText: '请粘贴完整JSON',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, controller.text),
          child: const Text('导入'),
        ),
      ],
    ),
  );
}

Future<String?> _showPasswordDialog(BuildContext context, String title) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        obscureText: true,
        decoration: const InputDecoration(labelText: '密码'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, controller.text),
          child: const Text('确定'),
        ),
      ],
    ),
  );
}

void _handleAccountImportResult(ImportResultData result, ImportMode mode) {
  switch (result.result) {
    case ImportResult.success:
      final summary = result.accountSummary;
      if (summary == null) {
        SmartDialog.showToast('导入成功');
        return;
      }
      if (mode == ImportMode.overwrite) {
        SmartDialog.showToast('导入成功，已覆盖 ${summary.addedCount} 条账号');
      } else {
        SmartDialog.showToast(
          '导入成功：新增 ${summary.addedCount}，更新 ${summary.updatedCount}，跳过 ${summary.skippedCount}',
        );
      }
      return;
    case ImportResult.cancelled:
      SmartDialog.showToast('已取消');
      return;
    case ImportResult.passwordRequired:
      SmartDialog.showToast('需要密码');
      return;
    case ImportResult.error:
      SmartDialog.showToast(result.message ?? '导入失败');
      return;
  }
}

void _handleSettingsImportResult(ImportResultData result, ImportMode mode) {
  switch (result.result) {
    case ImportResult.success:
      final count = result.appliedSettingsCount ?? 0;
      final modeText = mode == ImportMode.overwrite ? '覆盖' : '合并';
      SmartDialog.showToast('导入成功（$modeText），应用 $count 项设置');
      return;
    case ImportResult.cancelled:
      SmartDialog.showToast('已取消');
      return;
    case ImportResult.passwordRequired:
      SmartDialog.showToast('设置导入不需要密码');
      return;
    case ImportResult.error:
      SmartDialog.showToast(result.message ?? '导入失败');
      return;
  }
}

void _showEncryptPasswordDialog(BuildContext context) {
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('设置加密密码'),
      content: TextField(
        controller: controller,
        obscureText: true,
        decoration: const InputDecoration(labelText: '密码', hintText: '请输入加密密码'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            final password = controller.text.trim();
            if (password.length < 6) {
              SmartDialog.showToast('加密密码长度不能少于6位');
              return;
            }
            Navigator.pop(context);
            _exportAccounts(
              context,
              ExportType.accountEncryptedJson,
              password: password,
            );
          },
          child: const Text('确定'),
        ),
      ],
    ),
  );
}

Future<void> _exportAccounts(
  BuildContext context,
  ExportType type, {
  String? password,
}) async {
  SmartDialog.showLoading(msg: '正在导出...');

  final result = await ExportService.instance.exportAccounts(
    type: type,
    password: password,
  );

  SmartDialog.dismiss();

  switch (result.result) {
    case ExportResult.success:
      await _handleFileResult(result.filePath);
      break;
    case ExportResult.cancelled:
      SmartDialog.showToast('已取消');
      break;
    case ExportResult.error:
      SmartDialog.showToast(result.errorMessage ?? '导出失败');
      break;
  }
}

Future<void> _exportSettings(BuildContext context, ExportType type) async {
  SmartDialog.showLoading(msg: '正在导出...');

  final result = await ExportService.instance.exportSettings(type: type);

  SmartDialog.dismiss();

  switch (result.result) {
    case ExportResult.success:
      await _handleFileResult(result.filePath);
      break;
    case ExportResult.cancelled:
      SmartDialog.showToast('已取消');
      break;
    case ExportResult.error:
      SmartDialog.showToast(result.errorMessage ?? '导出失败');
      break;
  }
}

Future<void> _handleFileResult(String? filePath) async {
  if (Platform.isAndroid || Platform.isIOS || PlatformUtils.isHarmony) {
    SmartDialog.showToast('已打开系统分享，请按系统提示完成导出');
    return;
  }

  if (filePath != null && filePath.isNotEmpty) {
    SmartDialog.showToast('导出成功: $filePath');
    return;
  }

  SmartDialog.showToast('导出成功');
}

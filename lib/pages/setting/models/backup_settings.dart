import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hajimipass/pages/setting/models/model.dart';
import 'package:hajimipass/utils/export/export_service.dart';

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
            Navigator.pop(context);
            _exportAccounts(
              context,
              ExportType.accountEncryptedJson,
              password: controller.text,
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
      if (result.filePath != null) {
        await _handleFileResult(result.filePath!);
      } else {
        SmartDialog.showToast('导出成功');
      }
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
      if (result.filePath != null) {
        await _handleFileResult(result.filePath!);
      } else {
        SmartDialog.showToast('导出成功');
      }
      break;
    case ExportResult.cancelled:
      SmartDialog.showToast('已取消');
      break;
    case ExportResult.error:
      SmartDialog.showToast(result.errorMessage ?? '导出失败');
      break;
  }
}

Future<void> _handleFileResult(String filePath) async {
  SmartDialog.showToast('导出成功: $filePath');
}

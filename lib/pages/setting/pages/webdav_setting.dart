import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hajimipass/utils/webdav.dart';
import 'package:hajimipass/utils/export/import_service.dart';
import 'package:hajimipass/utils/storage/storage.dart';
import 'package:hajimipass/utils/storage/storage_key.dart';
import 'package:hajimipass/utils/storage/storage_pref.dart';

class WebDavSettingPage extends StatefulWidget {
  const WebDavSettingPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<WebDavSettingPage> createState() => _WebDavSettingPageState();
}

class _WebDavSettingPageState extends State<WebDavSettingPage> {
  final _uriCtr = TextEditingController(text: Pref.webdavUri);
  final _usernameCtr = TextEditingController(text: Pref.webdavUsername);
  final _passwordCtr = TextEditingController(text: Pref.webdavPassword);
  final _directoryCtr = TextEditingController(text: Pref.webdavDirectory);
  bool _obscureText = true;
  bool _loading = false;

  @override
  void dispose() {
    _uriCtr.dispose();
    _usernameCtr.dispose();
    _passwordCtr.dispose();
    _directoryCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showAppBar = widget.showAppBar;
    final padding = MediaQuery.viewPaddingOf(context);

    return Scaffold(
      appBar: showAppBar ? AppBar(title: const Text('WebDAV 设置')) : null,
      body: ListView(
        padding: EdgeInsets.only(
          top: 16,
          left: 16 + (showAppBar ? padding.left : 0),
          right: 16 + (showAppBar ? padding.right : 0),
          bottom: padding.bottom + 24,
        ),
        children: [
          TextField(
            controller: _uriCtr,
            decoration: const InputDecoration(
              labelText: '地址',
              hintText: '如: https://dav.example.com/dav',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _usernameCtr,
            decoration: const InputDecoration(
              labelText: '用户',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordCtr,
            obscureText: _obscureText,
            decoration: InputDecoration(
              labelText: '密码',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscureText = !_obscureText),
                icon: _obscureText
                    ? const Icon(Icons.visibility)
                    : const Icon(Icons.visibility_off),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _directoryCtr,
            decoration: const InputDecoration(
              labelText: '路径',
              hintText: '如: /backup 或 /',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '说明：会在你填写的路径下创建 `hajimipass` 目录，分别存储设置和账号 JSON。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: _loading ? null : _saveAndTest,
                  child: const Text('保存并测试连接'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: _loading ? null : _backupSettings,
                  child: const Text('备份设置'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: _loading ? null : _restoreSettings,
                  child: const Text('恢复设置'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _loading ? null : _backupAccounts,
                  child: const Text('备份账号'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _loading ? null : _restoreAccounts,
                  child: const Text('恢复账号'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveConfig() async {
    await GStorage.setting.putAll({
      SettingBoxKey.webdavUri: _uriCtr.text.trim(),
      SettingBoxKey.webdavUsername: _usernameCtr.text.trim(),
      SettingBoxKey.webdavPassword: _passwordCtr.text,
      SettingBoxKey.webdavDirectory: _directoryCtr.text.trim(),
    });
  }

  Future<void> _saveAndTest() async {
    await _runTask(() async {
      await _saveConfig();
      await WebDavService.instance.testConnection();
    });
  }

  Future<void> _backupSettings() async {
    await _runTask(() async {
      await _saveConfig();
      await WebDavService.instance.backupSettings();
    });
  }

  Future<void> _restoreSettings() async {
    final mode = await _showImportModeDialog('设置恢复模式');
    if (mode == null) {
      SmartDialog.showToast('已取消恢复设置');
      return;
    }

    await _runTask(() async {
      await _saveConfig();
      await WebDavService.instance.restoreSettings(mode: mode);
    });
  }

  Future<void> _backupAccounts() async {
    final password = await _showPasswordDialog(
      '设置备份加密密码',
      validator: (value) {
        if (value.trim().length < 6) {
          return '加密密码长度不能少于6位';
        }
        return null;
      },
    );
    if (password == null || password.isEmpty) {
      SmartDialog.showToast('已取消备份账号');
      return;
    }
    await _runTask(() async {
      await _saveConfig();
      await WebDavService.instance.backupAccounts(password: password);
    });
  }

  Future<void> _restoreAccounts() async {
    final mode = await _showImportModeDialog('账号恢复模式');
    if (mode == null) {
      SmartDialog.showToast('已取消恢复账号');
      return;
    }

    final password = await _showPasswordDialog('输入备份文件密码');
    if (password == null || password.isEmpty) {
      SmartDialog.showToast('已取消恢复账号');
      return;
    }

    await _runTask(() async {
      await _saveConfig();
      await WebDavService.instance.restoreAccounts(
        mode: mode,
        password: password,
      );
    });
  }

  Future<String?> _showPasswordDialog(
    String title, {
    String? Function(String)? validator,
  }) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String? errorText;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(title),
            content: TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                labelText: '密码',
                errorText: errorText,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  final text = controller.text;
                  if (validator != null) {
                    final error = validator(text);
                    if (error != null) {
                      setState(() => errorText = error);
                      return;
                    }
                  }
                  Navigator.pop(dialogContext, text);
                },
                child: const Text('确定'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<ImportMode?> _showImportModeDialog(String title) {
    return showDialog<ImportMode>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.file_download_done_outlined),
              title: const Text('覆盖恢复'),
              subtitle: const Text('远端数据覆盖本地数据'),
              onTap: () => Navigator.pop(dialogContext, ImportMode.overwrite),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.merge_type_outlined),
              title: const Text('合并恢复'),
              subtitle: const Text('仅更新远端包含的条目'),
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

  Future<void> _runTask(Future<void> Function() action) async {
    if (_loading) return;
    setState(() => _loading = true);
    SmartDialog.showLoading(msg: '处理中...');
    try {
      await action();
    } catch (e) {
      SmartDialog.showToast('操作失败: $e');
    } finally {
      SmartDialog.dismiss();
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}

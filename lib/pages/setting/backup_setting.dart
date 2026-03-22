import 'package:flutter/material.dart';
import 'package:hajimipass/pages/setting/models/backup_settings.dart';

class BackupSetting extends StatefulWidget {
  const BackupSetting({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<BackupSetting> createState() => _BackupSettingState();
}

class _BackupSettingState extends State<BackupSetting> {
  final settings = backupSettings;

  @override
  Widget build(BuildContext context) {
    final showAppBar = widget.showAppBar;
    final padding = MediaQuery.viewPaddingOf(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: showAppBar ? AppBar(title: const Text('备份设置')) : null,
      body: ListView(
        padding: EdgeInsets.only(
          left: showAppBar ? padding.left : 0,
          right: showAppBar ? padding.right : 0,
          bottom: padding.bottom + 100,
        ),
        children: settings.map((item) => item.widget).toList(),
      ),
    );
  }
}

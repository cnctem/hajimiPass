import 'package:flutter/material.dart';
import 'package:hajimipass/pages/setting/models/security_settings.dart';

class SecuritySetting extends StatefulWidget {
  const SecuritySetting({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<SecuritySetting> createState() => _SecuritySettingState();
}

class _SecuritySettingState extends State<SecuritySetting> {
  final settings = securitySettings;

  @override
  Widget build(BuildContext context) {
    final showAppBar = widget.showAppBar;
    final padding = MediaQuery.viewPaddingOf(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: showAppBar ? AppBar(title: const Text('安全设置')) : null,
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

import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:hajimipass/pages/setting/models/setting_type.dart';
import 'package:hajimipass/pages/setting/security_setting.dart';
import 'package:hajimipass/pages/setting/style_setting.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: SettingType.values.map((type) {
          return ListTile(
            title: Text(type.title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              switch (type) {
                case SettingType.securitySettings:
                  Get.to(() => const SecuritySetting());
                  break;
                case SettingType.styleSetting:
                  Get.to(() => const StyleSetting());
                  break;
                case SettingType.extraSetting:
                case SettingType.backupSetting:
                case SettingType.about:
                  // 暂未实现
                  // Get.snackbar('提示', '${type.title} 正在开发中');
                  SmartDialog.showToast('${type.title} 正在开发中');
                  break;
              }
            },
          );
        }).toList(),
      ),
    );
  }
}

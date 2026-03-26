import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hajimipass/utils/theme/theme_controller.dart';
import 'package:hajimipass/pages/setting/models/style_settings.dart';

class StyleSetting extends StatefulWidget {
  const StyleSetting({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<StyleSetting> createState() => _StyleSettingState();
}

class _StyleSettingState extends State<StyleSetting> {
  @override
  Widget build(BuildContext context) {
    final showAppBar = widget.showAppBar;
    final padding = MediaQuery.viewPaddingOf(context);
    final controller = Get.find<ThemeController>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: showAppBar ? AppBar(title: const Text('外观设置')) : null,
      body: Obx(() {
        // Explicitly access observable properties to trigger rebuilds
        // This registers the listener so the Obx widget rebuilds when these change
        controller.themeType.value;
        controller.dynamicColor.value;
        controller.isPureBlackTheme.value;
        controller.currentTextScale.value;
        controller.customColor.value;
        controller.schemeVariant.value;

        // Now get the settings list which uses these values in its callbacks
        final settings = styleSettings;
        return ListView(
          padding: EdgeInsets.only(
            left: showAppBar ? padding.left : 0,
            right: showAppBar ? padding.right : 0,
            bottom: padding.bottom + 100,
          ),
          children: settings.map((item) => item.widget).toList(),
        );
      }),
    );
  }
}

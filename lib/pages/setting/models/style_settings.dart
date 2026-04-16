import 'package:flex_seed_scheme/flex_seed_scheme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hajimipass/utils/theme/theme_controller.dart';
import 'package:hajimipass/utils/theme/theme_types.dart';
import 'package:hajimipass/pages/setting/models/model.dart';
import 'package:hajimipass/pages/setting/widgets/color_palette.dart';
import 'package:hajimipass/pages/setting/widgets/select_dialog.dart';
import 'package:hajimipass/utils/storage/storage_key.dart';

List<SettingsModel> get styleSettings {
  final controller = Get.find<ThemeController>();
  return [
    NormalModel(
      onTap: (context, setState) async {
        final result = await showDialog<ThemeType>(
          context: context,
          builder: (context) {
            return SelectDialog<ThemeType>(
              title: '主题模式',
              value: controller.themeType.value,
              values: ThemeType.values.map((e) => (e, e.desc)).toList(),
            );
          },
        );
        if (result != null) {
          controller.themeType.value = result;
        }
      },
      leading: const Icon(Icons.flashlight_on_outlined),
      title: '主题模式',
      getSubtitle: () => '当前模式：${controller.themeType.value.desc}',
    ),
    SwitchModel(
      leading: const Icon(Icons.invert_colors),
      title: '纯黑主题',
      setKey: SettingBoxKey.isPureBlackTheme,
      defaultVal: false,
      onChanged: (value) {
        controller.isPureBlackTheme.value = value;
      },
    ),
    NormalModel(
      onTap: (context, setState) => Get.toNamed('/colorSetting'),
      leading: const Icon(Icons.color_lens_outlined),
      title: '应用主题',
      getSubtitle: () =>
          '当前主题：${controller.dynamicColor.value ? '动态取色' : '指定颜色'}',
      getTrailing: () => controller.dynamicColor.value
          ? Icon(Icons.color_lens_rounded, color: Get.theme.colorScheme.primary)
          : SizedBox.square(
              dimension: 32,
              child: ColorPalette(
                colorScheme: SeedColorScheme.fromSeeds(
                  primaryKey:
                      colorThemeTypes[controller.customColor.value].color,
                  variant:
                      FlexSchemeVariant.values[controller.schemeVariant.value],
                  brightness: Get.theme.brightness,
                ),
                selected: false,
                showBgColor: false,
              ),
            ),
    ),
    NormalModel(
      onTap: (context, setState) async {
        await Get.toNamed('/fontSizeSetting');
      },
      title: '字体大小',
      leading: const Icon(Icons.format_size_outlined),
      getSubtitle: () => controller.currentTextScale.value == 1.0
          ? '默认'
          : controller.currentTextScale.value.toString(),
    ),
    SwitchModel(
      leading: const Icon(Icons.view_sidebar_outlined),
      title: '标签栏左置',
      subtitle: '关闭后标签栏移至顶部横排',
      setKey: SettingBoxKey.tagLayoutLeft,
      defaultVal: true,
      onChanged: (value) {
        controller.tagLayoutLeft.value = value;
      },
    ),
    SwitchModel(
      leading: const Icon(Icons.wrap_text_outlined),
      title: '单行截断',
      subtitle: '超长内容不换行，末尾显示省略号',
      setKey: SettingBoxKey.noLineWrap,
      defaultVal: true,
      onChanged: (value) {
        controller.noLineWrap.value = value;
      },
    ),
  ];
}

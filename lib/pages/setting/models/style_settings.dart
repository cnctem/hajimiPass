import 'package:flex_seed_scheme/flex_seed_scheme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hajimipass/utils/theme/theme_notifier.dart';
import 'package:hajimipass/utils/theme/theme_types.dart';
import 'package:hajimipass/pages/setting/models/model.dart';
import 'package:hajimipass/pages/setting/widgets/color_palette.dart';
import 'package:hajimipass/pages/setting/widgets/select_dialog.dart';
import 'package:hajimipass/utils/storage/storage_key.dart';

List<SettingsModel> styleSettings(
  BuildContext context,
  ThemeState theme,
  ThemeNotifier notifier,
) {
  return [
    NormalModel(
      onTap: (context, setState) async {
        final result = await showDialog<ThemeType>(
          context: context,
          builder: (context) {
            return SelectDialog<ThemeType>(
              title: '主题模式',
              value: theme.themeType,
              values: ThemeType.values.map((e) => (e, e.desc)).toList(),
            );
          },
        );
        if (result != null) {
          notifier.setThemeType(result);
        }
      },
      leading: const Icon(Icons.flashlight_on_outlined),
      title: '主题模式',
      getSubtitle: () => '当前模式：${theme.themeType.desc}',
    ),
    SwitchModel(
      leading: const Icon(Icons.invert_colors),
      title: '纯黑主题',
      setKey: SettingBoxKey.isPureBlackTheme,
      defaultVal: false,
      onChanged: (value) {
        notifier.setIsPureBlackTheme(value);
      },
    ),
    NormalModel(
      onTap: (context, setState) => context.push('/colorSetting'),
      leading: const Icon(Icons.color_lens_outlined),
      title: '应用主题',
      getSubtitle: () =>
          '当前主题：${theme.dynamicColor ? '动态取色' : '指定颜色'}',
      getTrailing: () => theme.dynamicColor
          ? Icon(
              Icons.color_lens_rounded,
              color: Theme.of(context).colorScheme.primary,
            )
          : SizedBox.square(
              dimension: 32,
              child: ColorPalette(
                colorScheme: SeedColorScheme.fromSeeds(
                  primaryKey: colorThemeTypes[theme.customColor].color,
                  variant: FlexSchemeVariant.values[theme.schemeVariant],
                  brightness: Theme.of(context).brightness,
                ),
                selected: false,
                showBgColor: false,
              ),
            ),
    ),
    NormalModel(
      onTap: (context, setState) async {
        await context.push('/fontSizeSetting');
      },
      title: '字体大小',
      leading: const Icon(Icons.format_size_outlined),
      getSubtitle: () => theme.currentTextScale == 1.0
          ? '默认'
          : theme.currentTextScale.toString(),
    ),
  ];
}

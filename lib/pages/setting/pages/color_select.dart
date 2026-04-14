import 'package:flex_seed_scheme/flex_seed_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajimipass/utils/theme/theme_notifier.dart';
import 'package:hajimipass/utils/theme/theme_types.dart';
import 'package:hajimipass/pages/setting/widgets/color_palette.dart';
import 'dart:io' show Platform;

class ColorSelectPage extends ConsumerWidget {
  const ColorSelectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final notifier = ref.read(themeProvider.notifier);
    final appTheme = Theme.of(context);
    final padding = MediaQuery.viewPaddingOf(context).copyWith(top: 0, bottom: 0);
    final schemeVariant = FlexSchemeVariant.values[theme.schemeVariant];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('选择应用主题')),
      body: ListView(
        children: [
          ListTile(
            enabled: !theme.dynamicColor,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('调色板风格'),
                PopupMenuButton<FlexSchemeVariant>(
                  enabled: !theme.dynamicColor,
                  initialValue: schemeVariant,
                  onSelected: (item) => notifier.setSchemeVariant(item.index),
                  itemBuilder: (context) => FlexSchemeVariant.values
                      .map(
                        (item) => PopupMenuItem<FlexSchemeVariant>(
                          value: item,
                          child: Text(item.variantName),
                        ),
                      )
                      .toList(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        schemeVariant.variantName,
                        style: TextStyle(
                          height: 1,
                          fontSize: 13,
                          color: theme.dynamicColor
                              ? appTheme.colorScheme.outline.withValues(alpha: 0.8)
                              : appTheme.colorScheme.secondary,
                        ),
                        strutStyle: const StrutStyle(leading: 0, height: 1),
                      ),
                      Icon(
                        Icons.keyboard_arrow_right,
                        size: 20,
                        color: theme.dynamicColor
                            ? appTheme.colorScheme.outline.withValues(alpha: 0.8)
                            : appTheme.colorScheme.secondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            leading: Container(
              width: 40,
              alignment: Alignment.center,
              child: const Icon(Icons.palette_outlined),
            ),
            subtitle: Text(
              schemeVariant.description,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          if (!Platform.isIOS && theme.dynamicColor)
            CheckboxListTile(
              title: const Text('动态取色'),
              controlAffinity: ListTileControlAffinity.leading,
              value: theme.dynamicColor,
              onChanged: (val) {
                if (val != null) notifier.setDynamicColor(val);
              },
            ),
          Padding(
            padding: padding,
            child: AnimatedSize(
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              duration: const Duration(milliseconds: 200),
              child: theme.dynamicColor
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 22,
                        runSpacing: 18,
                        children: List.generate(colorThemeTypes.length, (index) {
                          final type = colorThemeTypes[index];
                          return GestureDetector(
                            onTap: () => notifier.setCustomColor(index),
                            child: ColorPalette(
                              colorScheme: SeedColorScheme.fromSeeds(
                                primaryKey: type.color,
                                variant: schemeVariant,
                                brightness: appTheme.brightness,
                              ),
                              selected: theme.customColor == index,
                            ),
                          );
                        }),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

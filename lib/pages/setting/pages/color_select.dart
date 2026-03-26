import 'package:flex_seed_scheme/flex_seed_scheme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hajimipass/utils/theme/theme_controller.dart';
import 'package:hajimipass/utils/theme/theme_types.dart';
import 'package:hajimipass/pages/setting/widgets/color_palette.dart';
import 'dart:io' show Platform;

class ColorSelectPage extends StatefulWidget {
  const ColorSelectPage({super.key});

  @override
  State<ColorSelectPage> createState() => _ColorSelectPageState();
}

class _ColorSelectPageState extends State<ColorSelectPage> {
  final ctr = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = MediaQuery.viewPaddingOf(
      context,
    ).copyWith(top: 0, bottom: 0);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('选择应用主题')),
      body: Obx(() {
        final schemeVariant = FlexSchemeVariant.values[ctr.schemeVariant.value];
        return ListView(
          children: [
            ListTile(
              enabled: !ctr.dynamicColor.value,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('调色板风格'),
                  PopupMenuButton<FlexSchemeVariant>(
                    enabled: !ctr.dynamicColor.value,
                    initialValue: schemeVariant,
                    onSelected: (item) {
                      ctr.schemeVariant.value = item.index;
                    },
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
                            color: ctr.dynamicColor.value
                                ? theme.colorScheme.outline.withValues(
                                    alpha: 0.8,
                                  )
                                : theme.colorScheme.secondary,
                          ),
                          strutStyle: const StrutStyle(leading: 0, height: 1),
                        ),
                        Icon(
                          Icons.keyboard_arrow_right,
                          size: 20,
                          color: ctr.dynamicColor.value
                              ? theme.colorScheme.outline.withValues(alpha: 0.8)
                              : theme.colorScheme.secondary,
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
            if (!Platform.isIOS && ctr.dynamicColor.value)
              CheckboxListTile(
                title: const Text('动态取色'),
                controlAffinity: ListTileControlAffinity.leading,
                value: ctr.dynamicColor.value,
                onChanged: (val) {
                  if (val != null) {
                    ctr.dynamicColor.value = val;
                  }
                },
              ),
            Padding(
              padding: padding,
              child: AnimatedSize(
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                duration: const Duration(milliseconds: 200),
                child: ctr.dynamicColor.value
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 22,
                          runSpacing: 18,
                          children: List.generate(colorThemeTypes.length, (
                            index,
                          ) {
                            final type = colorThemeTypes[index];
                            return GestureDetector(
                              onTap: () => ctr.customColor.value = index,
                              child: ColorPalette(
                                colorScheme: SeedColorScheme.fromSeeds(
                                  primaryKey: type.color,
                                  variant: schemeVariant,
                                  brightness: theme.brightness,
                                ),
                                selected: ctr.customColor.value == index,
                              ),
                            );
                          }),
                        ),
                      ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

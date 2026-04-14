import 'package:flex_seed_scheme/flex_seed_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:hajimipass/utils/constants.dart';
import 'package:hajimipass/utils/export/import_service.dart';
import 'package:hajimipass/utils/extension/theme_ext.dart';
import 'package:hajimipass/utils/platform_utils.dart';
import 'package:hajimipass/utils/router.dart';
import 'package:hajimipass/utils/storage/hajimi_storage.dart';
import 'package:hajimipass/utils/storage/storage.dart';
import 'package:hajimipass/utils/theme/theme_notifier.dart';
import 'package:hajimipass/utils/theme/theme_types.dart';
import 'package:hajimipass/utils/theme/theme_utils.dart';
import 'package:hajimipass/utils/widgets/mouse_back.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final tasks = <Future<void>>[
      HajimiStorage.instance.init(),
      GStorage.init(),
    ];
    if (PlatformUtils.isHarmony) {
      tasks.add(PlatformUtils.initHarmonyDeviceType());
    }
    await Future.wait(tasks);
  } catch (e) {
    debugPrint('Initialization error: $e');
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  static ColorScheme? _light, _dark;

  static void _onBack(GoRouter router) {
    if (SmartDialog.checkExist()) {
      SmartDialog.dismiss();
      return;
    }
    if (router.canPop()) {
      router.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    // Register theme refresh callback for import service
    ImportService.instance.setThemeRefreshCallback(
      () => ref.read(themeProvider.notifier).refreshFromPrefs(),
    );

    final dynamicColor =
        theme.dynamicColor && _light != null && _dark != null;
    final brandColor = colorThemeTypes[theme.customColor].color;
    final variant = FlexSchemeVariant.values[theme.schemeVariant];

    return MaterialApp.router(
      title: Constants.appName,
      theme: ThemeUtils.getThemeData(
        colorScheme: dynamicColor
            ? _light!
            : brandColor.asColorSchemeSeed(variant, Brightness.light),
        isDynamic: dynamicColor,
      ),
      darkTheme: ThemeUtils.getThemeData(
        isDark: true,
        colorScheme: dynamicColor
            ? _dark!
            : brandColor.asColorSchemeSeed(variant, Brightness.dark),
        isDynamic: dynamicColor,
      ),
      themeMode: theme.themeType.toThemeMode,
      routerConfig: router,
      builder: (context, child) {
        final newChild = MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(theme.currentTextScale),
          ),
          child: child!,
        );
        final dialogChild = FlutterSmartDialog.init()(context, newChild);

        if (PlatformUtils.isDesktop) {
          return Focus(
            canRequestFocus: false,
            onKeyEvent: (_, event) {
              if (event.logicalKey == LogicalKeyboardKey.escape &&
                  event is KeyDownEvent) {
                _onBack(router);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: MouseBackDetector(
              onTapDown: () => _onBack(router),
              child: dialogChild,
            ),
          );
        }
        return dialogChild;
      },
    );
  }
}

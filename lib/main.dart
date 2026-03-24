import 'package:flex_seed_scheme/flex_seed_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:hajimipass/controllers/theme_controller.dart';
import 'package:hajimipass/utils/constants.dart';
import 'package:hajimipass/models/theme_types.dart';
import 'package:hajimipass/pages/creat/view.dart';
import 'package:hajimipass/pages/home/view.dart';
import 'package:hajimipass/pages/login/view.dart';
import 'package:hajimipass/pages/search/view.dart';
import 'package:hajimipass/pages/setting/pages/color_select.dart';
import 'package:hajimipass/pages/setting/pages/font_size_select.dart';
import 'package:hajimipass/pages/setting/pages/key_init.dart';
import 'package:hajimipass/pages/setting/view.dart';
import 'package:hajimipass/utils/extension/theme_ext.dart';
import 'package:hajimipass/utils/platform_utils.dart';
import 'package:hajimipass/utils/storage/hajimi_storage.dart';
import 'package:hajimipass/utils/storage/storage.dart';
import 'package:hajimipass/utils/storage/storage_pref.dart';
import 'package:hajimipass/utils/theme_utils.dart';
import 'package:hajimipass/utils/widgets/mouse_back.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Future.wait([HajimiStorage.instance.init(), GStorage.init()]);
  } catch (e) {
    debugPrint('Initialization error: $e');
  }
  Get.put(ThemeController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static ColorScheme? _light, _dark;

  static ThemeData? darkThemeData;

  String _getInitialRoute() {
    if (Pref.passwordHint.isEmpty) {
      return '/keyInit';
    }
    if (!HajimiStorage.instance.unlocked) {
      return '/login';
    }
    return '/';
  }

  static void _onBack() {
    if (SmartDialog.checkExist()) {
      SmartDialog.dismiss();
      return;
    }

    if (Get.routing.route is! GetPageRoute) {
      Get.back();
      return;
    }

    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColor = Pref.dynamicColor && _light != null && _dark != null;
    late final brandColor = colorThemeTypes[Pref.customColor].color;
    late final variant = FlexSchemeVariant.values[Pref.schemeVariant];
    return GetMaterialApp(
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
      themeMode: Pref.themeType.toThemeMode,
      navigatorObservers: [FlutterSmartDialog.observer],
      builder: (context, child) {
        final newChild = MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(Pref.defaultTextScale)),
          child: child!,
        );
        final dialogChild = FlutterSmartDialog.init()(context, newChild);

        if (PlatformUtils.isDesktop) {
          return Focus(
            canRequestFocus: false,
            onKeyEvent: (_, event) {
              if (event.logicalKey == LogicalKeyboardKey.escape &&
                  event is KeyDownEvent) {
                _onBack();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: MouseBackDetector(onTapDown: _onBack, child: dialogChild),
          );
        }
        return dialogChild;
      },
      initialRoute: _getInitialRoute(),
      getPages: [
        GetPage(name: '/', page: () => const HomePage()),
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(name: '/creat', page: () => const CreatePage()),
        GetPage(name: '/search', page: () => const SearchPage()),
        GetPage(name: '/setting', page: () => const SettingPage()),
        GetPage(name: '/colorSetting', page: () => const ColorSelectPage()),
        GetPage(
          name: '/fontSizeSetting',
          page: () => const FontSizeSelectPage(),
        ),
        GetPage(name: '/keyInit', page: () => const KeyInitPage()),
      ],
    );
  }
}

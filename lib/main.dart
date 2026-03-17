import 'package:dynamic_color/dynamic_color.dart';
import 'package:flex_seed_scheme/flex_seed_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:hajimipass/controllers/theme_controller.dart';
import 'package:hajimipass/models/theme_types.dart';
import 'package:hajimipass/pages/creat/view.dart';
import 'package:hajimipass/pages/home/view.dart';
import 'package:hajimipass/pages/login/view.dart';
import 'package:hajimipass/pages/search/view.dart';
import 'package:hajimipass/pages/setting/pages/color_select.dart';
import 'package:hajimipass/pages/setting/pages/font_size_select.dart';
import 'package:hajimipass/pages/setting/pages/key_init.dart';
import 'package:hajimipass/pages/setting/view.dart';
import 'package:hajimipass/utils/storage/hajimi_storage.dart';
import 'package:hajimipass/utils/storage/storage.dart';
import 'package:hajimipass/utils/storage/storage_pref.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Future.wait([HajimiStorage.instance.init(), GStorage.init()]);
  } catch (e) {
    debugPrint('Initialization error: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  String _getInitialRoute() {
    if (Pref.passwordHint.isEmpty) {
      return '/keyInit';
    }
    if (!HajimiStorage.instance.unlocked) {
      return '/login';
    }
    return '/';
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.put(ThemeController());

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return Obx(() {
          final isDynamic = themeController.dynamicColor.value;
          final customColor =
              colorThemeTypes[themeController.customColor.value].color;
          final schemeVariant =
              FlexSchemeVariant.values[themeController.schemeVariant.value];
          final isPureBlack = themeController.isPureBlackTheme.value;
          final textScale = themeController.currentTextScale.value;

          final lightScheme = isDynamic && lightDynamic != null
              ? SeedColorScheme.fromSeeds(
                  primaryKey: lightDynamic.primary,
                  variant: schemeVariant,
                  brightness: Brightness.light,
                )
              : SeedColorScheme.fromSeeds(
                  primaryKey: customColor,
                  variant: schemeVariant,
                  brightness: Brightness.light,
                );

          final darkScheme = isDynamic && darkDynamic != null
              ? SeedColorScheme.fromSeeds(
                  primaryKey: darkDynamic.primary,
                  variant: schemeVariant,
                  brightness: Brightness.dark,
                )
              : SeedColorScheme.fromSeeds(
                  primaryKey: customColor,
                  variant: schemeVariant,
                  brightness: Brightness.dark,
                );

          final lightTheme = ThemeData(
            colorScheme: lightScheme,
            useMaterial3: true,
          );

          final darkTheme = ThemeData(
            colorScheme: isPureBlack
                ? darkScheme.copyWith(surface: Colors.black)
                : darkScheme,
            useMaterial3: true,
            scaffoldBackgroundColor: isPureBlack ? Colors.black : null,
          );

          return GetMaterialApp(
            title: '哈基密码本',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeController.themeType.value.toThemeMode,
            navigatorObservers: [FlutterSmartDialog.observer],
            builder: (context, child) {
              final newChild = MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!,
              );
              return FlutterSmartDialog.init()(context, newChild);
            },
            initialRoute: _getInitialRoute(),
            getPages: [
              GetPage(name: '/', page: () => const HomePage()),
              GetPage(name: '/login', page: () => const LoginPage()),
              GetPage(name: '/creat', page: () => const CreatePage()),
              GetPage(name: '/search', page: () => const SearchPage()),
              GetPage(name: '/setting', page: () => const SettingPage()),
              GetPage(
                name: '/colorSetting',
                page: () => const ColorSelectPage(),
              ),
              GetPage(
                name: '/fontSizeSetting',
                page: () => const FontSizeSelectPage(),
              ),
              GetPage(name: '/keyInit', page: () => const KeyInitPage()),
            ],
          );
        });
      },
    );
  }
}

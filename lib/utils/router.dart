import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:hajimipass/pages/creat/view.dart';
import 'package:hajimipass/pages/home/view.dart';
import 'package:hajimipass/pages/login/view.dart';
import 'package:hajimipass/pages/search/view.dart';
import 'package:hajimipass/pages/setting/about_page.dart';
import 'package:hajimipass/pages/setting/backup_setting.dart';
import 'package:hajimipass/pages/setting/pages/color_select.dart';
import 'package:hajimipass/pages/setting/pages/font_size_select.dart';
import 'package:hajimipass/pages/setting/pages/key_init.dart';
import 'package:hajimipass/pages/setting/pages/webdav_setting.dart';
import 'package:hajimipass/pages/setting/security_setting.dart';
import 'package:hajimipass/pages/setting/style_setting.dart';
import 'package:hajimipass/pages/setting/view.dart';
import 'package:hajimipass/utils/storage/hajimi_storage.dart';
import 'package:hajimipass/utils/storage/storage_pref.dart';

String _getInitialLocation() {
  if (Pref.passwordHint.isEmpty) return '/keyInit';
  if (!HajimiStorage.instance.unlocked) return '/login';
  return '/';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: _getInitialLocation(),
    observers: [FlutterSmartDialog.observer],
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomePage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/creat', builder: (_, __) => const CreatePage()),
      GoRoute(path: '/search', builder: (_, __) => const SearchPage()),
      GoRoute(path: '/setting', builder: (_, __) => const SettingPage()),
      GoRoute(
        path: '/securitySetting',
        builder: (_, __) => const SecuritySetting(),
      ),
      GoRoute(
        path: '/styleSetting',
        builder: (_, __) => const StyleSetting(),
      ),
      GoRoute(
        path: '/backupSetting',
        builder: (_, __) => const BackupSetting(),
      ),
      GoRoute(path: '/about', builder: (_, __) => const AboutPage()),
      GoRoute(
        path: '/colorSetting',
        builder: (_, __) => const ColorSelectPage(),
      ),
      GoRoute(
        path: '/fontSizeSetting',
        builder: (_, __) => const FontSizeSelectPage(),
      ),
      GoRoute(path: '/keyInit', builder: (_, __) => const KeyInitPage()),
      GoRoute(
        path: '/webdavSetting',
        builder: (_, __) => const WebDavSettingPage(),
      ),
    ],
  );
});

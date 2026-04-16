import 'package:hajimipass/utils/theme/theme_types.dart';
import 'package:hajimipass/utils/storage/storage.dart';
import 'package:hajimipass/utils/storage/storage_key.dart';

abstract final class Pref {
  static final JsonSettingStorage _setting = GStorage.setting;

  static int get _themeTypeInt => _setting.get(
    SettingBoxKey.themeMode,
    defaultValue: ThemeType.system.index,
  );

  static ThemeType get themeType => ThemeType.values[_themeTypeInt];

  static bool get isPureBlackTheme =>
      _setting.get(SettingBoxKey.isPureBlackTheme, defaultValue: false);
  static int get schemeVariant =>
      _setting.get(SettingBoxKey.schemeVariant, defaultValue: 10);
  static bool get dynamicColor =>
      _setting.get(SettingBoxKey.dynamicColor, defaultValue: false);
  static double get defaultTextScale =>
      _setting.get(SettingBoxKey.defaultTextScale, defaultValue: 1.0);
  static int get customColor =>
      _setting.get(SettingBoxKey.customColor, defaultValue: 5);
  static String get passwordHint =>
      _setting.get(SettingBoxKey.passwordHint, defaultValue: '');
  static set passwordHint(String value) =>
      _setting.put(SettingBoxKey.passwordHint, value);
  static int get appFontWeight =>
      _setting.get(SettingBoxKey.appFontWeight, defaultValue: -1);
  static bool get darkVideoPage =>
      _setting.get(SettingBoxKey.darkVideoPage, defaultValue: false);
  static String get webdavUri =>
      _setting.get(SettingBoxKey.webdavUri, defaultValue: '');
  static String get webdavUsername =>
      _setting.get(SettingBoxKey.webdavUsername, defaultValue: '');
  static String get webdavPassword =>
      _setting.get(SettingBoxKey.webdavPassword, defaultValue: '');
  static String get webdavDirectory =>
      _setting.get(SettingBoxKey.webdavDirectory, defaultValue: '/');
  static bool get tagLayoutLeft =>
      _setting.get(SettingBoxKey.tagLayoutLeft, defaultValue: true);
  static bool get noLineWrap =>
      _setting.get(SettingBoxKey.noLineWrap, defaultValue: true);
}

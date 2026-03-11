import 'package:hajimipass/models/theme_types.dart';
import 'package:hajimipass/utils/storage/storage.dart';
import 'package:hajimipass/utils/storage/storage_key.dart';

abstract final class Pref {
  static ThemeType get themeType =>
      ThemeType.values[GStorage.setting.get(
        SettingBoxKey.themeMode,
        defaultValue: 0,
      )];
  static bool get isPureBlackTheme =>
      GStorage.setting.get(SettingBoxKey.isPureBlackTheme, defaultValue: false);
  static int get schemeVariant =>
      GStorage.setting.get(SettingBoxKey.schemeVariant, defaultValue: 0);
  static bool get dynamicColor =>
      GStorage.setting.get(SettingBoxKey.dynamicColor, defaultValue: true);
  static double get defaultTextScale =>
      GStorage.setting.get(SettingBoxKey.defaultTextScale, defaultValue: 1.0);
  static int get customColor =>
      GStorage.setting.get(SettingBoxKey.customColor, defaultValue: 0);
}

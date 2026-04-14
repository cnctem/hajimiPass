import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajimipass/utils/storage/storage.dart';
import 'package:hajimipass/utils/storage/storage_key.dart';
import 'package:hajimipass/utils/storage/storage_pref.dart';
import 'package:hajimipass/utils/theme/theme_types.dart';

class ThemeState {
  final ThemeType themeType;
  final bool dynamicColor;
  final bool isPureBlackTheme;
  final double currentTextScale;
  final int customColor;
  final int schemeVariant;

  const ThemeState({
    required this.themeType,
    required this.dynamicColor,
    required this.isPureBlackTheme,
    required this.currentTextScale,
    required this.customColor,
    required this.schemeVariant,
  });

  ThemeState copyWith({
    ThemeType? themeType,
    bool? dynamicColor,
    bool? isPureBlackTheme,
    double? currentTextScale,
    int? customColor,
    int? schemeVariant,
  }) {
    return ThemeState(
      themeType: themeType ?? this.themeType,
      dynamicColor: dynamicColor ?? this.dynamicColor,
      isPureBlackTheme: isPureBlackTheme ?? this.isPureBlackTheme,
      currentTextScale: currentTextScale ?? this.currentTextScale,
      customColor: customColor ?? this.customColor,
      schemeVariant: schemeVariant ?? this.schemeVariant,
    );
  }
}

class ThemeNotifier extends Notifier<ThemeState> {
  @override
  ThemeState build() {
    return ThemeState(
      themeType: Pref.themeType,
      dynamicColor: Pref.dynamicColor,
      isPureBlackTheme: Pref.isPureBlackTheme,
      currentTextScale: Pref.defaultTextScale,
      customColor: Pref.customColor,
      schemeVariant: Pref.schemeVariant,
    );
  }

  final _setting = GStorage.setting;

  void setThemeType(ThemeType value) {
    _setting.put(SettingBoxKey.themeMode, value.index);
    state = state.copyWith(themeType: value);
  }

  void setDynamicColor(bool value) {
    _setting.put(SettingBoxKey.dynamicColor, value);
    state = state.copyWith(dynamicColor: value);
  }

  void setIsPureBlackTheme(bool value) {
    _setting.put(SettingBoxKey.isPureBlackTheme, value);
    state = state.copyWith(isPureBlackTheme: value);
  }

  void setCurrentTextScale(double value) {
    _setting.put(SettingBoxKey.defaultTextScale, value);
    state = state.copyWith(currentTextScale: value);
  }

  void setCustomColor(int value) {
    _setting.put(SettingBoxKey.customColor, value);
    state = state.copyWith(customColor: value);
  }

  void setSchemeVariant(int value) {
    _setting.put(SettingBoxKey.schemeVariant, value);
    state = state.copyWith(schemeVariant: value);
  }

  void refreshFromPrefs() {
    state = ThemeState(
      themeType: Pref.themeType,
      dynamicColor: Pref.dynamicColor,
      isPureBlackTheme: Pref.isPureBlackTheme,
      currentTextScale: Pref.defaultTextScale,
      customColor: Pref.customColor,
      schemeVariant: Pref.schemeVariant,
    );
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(
  ThemeNotifier.new,
);

import 'package:flutter/material.dart';

enum ThemeType {
  system,
  light,
  dark;

  String get desc => switch (this) {
    ThemeType.system => '跟随系统',
    ThemeType.light => '浅色模式',
    ThemeType.dark => '深色模式',
  };

  ThemeMode get toThemeMode => switch (this) {
    ThemeType.system => ThemeMode.system,
    ThemeType.light => ThemeMode.light,
    ThemeType.dark => ThemeMode.dark,
  };
}

class ThemeColorType {
  final Color color;
  final String name;

  const ThemeColorType(this.color, this.name);
}

const List<ThemeColorType> colorThemeTypes = [
  ThemeColorType(Color(0xFF6750A4), 'Purple'),
  ThemeColorType(Color(0xFF386A20), 'Green'),
  ThemeColorType(Color(0xFF0061A4), 'Blue'),
  ThemeColorType(Color(0xFFBF0031), 'Red'),
  ThemeColorType(Color(0xFF006874), 'Cyan'),
  ThemeColorType(Color(0xFF825500), 'Orange'),
];

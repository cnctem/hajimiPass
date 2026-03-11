import 'package:flutter/material.dart';

class ColorPalette extends StatelessWidget {
  final ColorScheme colorScheme;
  final bool selected;
  final bool showBgColor;

  const ColorPalette({
    super.key,
    required this.colorScheme,
    this.selected = false,
    this.showBgColor = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        shape: BoxShape.circle,
        border: selected
            ? Border.all(color: colorScheme.primary, width: 2)
            : null,
      ),
      child: Center(
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

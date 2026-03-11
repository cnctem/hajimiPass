import 'package:flutter/material.dart';

class SelectDialog<T> extends StatelessWidget {
  final T? value;
  final String title;
  final List<(T, String)> values;
  final Widget Function(BuildContext, int)? subtitleBuilder;
  final bool toggleable;

  const SelectDialog({
    super.key,
    this.value,
    required this.values,
    required this.title,
    this.subtitleBuilder,
    this.toggleable = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleMedium = TextTheme.of(context).titleMedium!;
    return AlertDialog(
      clipBehavior: Clip.hardEdge,
      title: Text(title),
      constraints: subtitleBuilder != null
          ? const BoxConstraints(maxWidth: 320, minWidth: 320)
          : null,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      content: Material(
        type: MaterialType.transparency,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(values.length, (index) {
              final item = values[index];
              return RadioListTile<T>(
                toggleable: toggleable,
                dense: true,
                value: item.$1,
                groupValue: value,
                onChanged: (v) => Navigator.of(context).pop(v ?? value),
                title: Text(item.$2, style: titleMedium),
                subtitle: subtitleBuilder?.call(context, index),
              );
            }),
          ),
        ),
      ),
    );
  }
}

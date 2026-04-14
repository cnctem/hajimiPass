import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hajimipass/utils/theme/theme_notifier.dart';
import 'package:hajimipass/pages/setting/models/style_settings.dart';

class StyleSetting extends ConsumerWidget {
  const StyleSetting({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final notifier = ref.read(themeProvider.notifier);
    final padding = MediaQuery.viewPaddingOf(context);
    final settings = styleSettings(context, theme, notifier);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: showAppBar ? AppBar(title: const Text('外观设置')) : null,
      body: ListView(
        padding: EdgeInsets.only(
          left: showAppBar ? padding.left : 0,
          right: showAppBar ? padding.right : 0,
          bottom: padding.bottom + 100,
        ),
        children: settings.map((item) => item.widget).toList(),
      ),
    );
  }
}

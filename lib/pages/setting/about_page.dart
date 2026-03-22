import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hajimipass/build_config.dart';
import 'package:hajimipass/utils/constants.dart';
import 'package:hajimipass/utils/date_utils.dart';
import 'package:hajimipass/utils/page_utils.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outline = theme.colorScheme.outline;
    final subTitleStyle = TextStyle(fontSize: 13, color: outline);
    final padding = MediaQuery.viewPaddingOf(context);
    const versionTag = '${BuildConfig.versionTag}+${BuildConfig.versionCode}';

    return Scaffold(
      appBar: showAppBar ? AppBar(title: const Text('关于')) : null,
      resizeToAvoidBottomInset: false,
      body: ListView(
        padding: EdgeInsets.only(
          left: showAppBar ? padding.left : 0,
          right: showAppBar ? padding.right : 0,
          bottom: padding.bottom + 100,
        ),
        children: [
          const SizedBox(height: 24),
          Center(
            child: Icon(
              Icons.lock_outlined,
              size: 80,
              color: theme.colorScheme.primary,
            ),
          ),
          ListTile(
            title: Text(
              Constants.appName,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium!.copyWith(height: 2),
            ),
            subtitle: Text(
              '基于哈基米加密的密码本',
              textAlign: TextAlign.center,
              style: TextStyle(color: outline),
            ),
          ),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.commit_outlined),
            title: const Text('当前版本'),
            trailing: Text(versionTag, style: subTitleStyle),
            onLongPress: () => _copyText(versionTag),
          ),
          if (BuildConfig.buildTime != 0)
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(
                'Build Time: ${DateFormatUtils.format(BuildConfig.buildTime)}\n'
                'Commit: ${BuildConfig.commitHash}',
                style: const TextStyle(fontSize: 14),
              ),
              onTap: () => PageUtils.launchURL(
                '${Constants.sourceCodeUrl}/commit/'
                '${BuildConfig.commitHash == 'N/A' ? 'HEAD' : BuildConfig.commitHash}',
              ),
              onLongPress: () => _copyText(BuildConfig.commitHash),
            ),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('源代码'),
            subtitle: Text(Constants.sourceCodeUrl, style: subTitleStyle),
            trailing: Icon(Icons.arrow_forward, size: 16, color: outline),
            onTap: () => PageUtils.launchURL(Constants.sourceCodeUrl),
          ),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('问题反馈'),
            trailing: Icon(Icons.arrow_forward, size: 16, color: outline),
            onTap: () =>
                PageUtils.launchURL('${Constants.sourceCodeUrl}/issues'),
          ),
        ],
      ),
    );
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    SmartDialog.showToast('已复制到剪贴板');
  }
}

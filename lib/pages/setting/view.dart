import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hajimipass/pages/setting/about_page.dart';
import 'package:hajimipass/pages/setting/backup_setting.dart';
import 'package:hajimipass/pages/setting/models/setting_type.dart';
import 'package:hajimipass/pages/setting/security_setting.dart';
import 'package:hajimipass/pages/setting/style_setting.dart';

class _SettingItem {
  final SettingType type;
  final Icon icon;
  final String? subtitle;

  const _SettingItem({required this.type, required this.icon, this.subtitle});
}

const _items = [
  _SettingItem(
    type: SettingType.securitySettings,
    icon: Icon(Icons.lock_outline),
    subtitle: '密码、密钥管理',
  ),
  _SettingItem(
    type: SettingType.styleSetting,
    icon: Icon(Icons.palette_outlined),
    subtitle: '主题、字号、颜色',
  ),
  _SettingItem(
    type: SettingType.backupSetting,
    icon: Icon(Icons.backup_outlined),
    subtitle: '导入、导出数据',
  ),
  _SettingItem(
    type: SettingType.extraSetting,
    icon: Icon(Icons.extension_outlined),
    subtitle: '其它功能设置',
  ),
  _SettingItem(type: SettingType.about, icon: Icon(Icons.info_outline)),
];

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late SettingType _type = _items.first.type;
  late bool _isPortrait;

  void _toPage(SettingType type) {
    if (_isPortrait) {
      switch (type) {
        case SettingType.securitySettings:
          context.push('/securitySetting');
        case SettingType.styleSetting:
          context.push('/styleSetting');
        case SettingType.backupSetting:
          context.push('/backupSetting');
        case SettingType.extraSetting:
          break;
        case SettingType.about:
          context.push('/about');
      }
    } else {
      setState(() => _type = type);
    }
  }

  Color? _tileColor(ThemeData theme, SettingType type) =>
      !_isPortrait && type == _type ? theme.colorScheme.onInverseSurface : null;

  Widget _buildDetail() => switch (_type) {
    SettingType.securitySettings => const SecuritySetting(showAppBar: false),
    SettingType.styleSetting => const StyleSetting(showAppBar: false),
    SettingType.backupSetting => const BackupSetting(showAppBar: false),
    SettingType.extraSetting => const SizedBox.shrink(),
    SettingType.about => const AboutPage(showAppBar: false),
  };

  Widget _buildList(ThemeData theme) {
    final padding = MediaQuery.viewPaddingOf(context);
    final titleStyle = theme.textTheme.titleMedium!;
    final subtitleStyle = theme.textTheme.labelMedium!.copyWith(
      color: theme.colorScheme.outline,
    );
    return ListView(
      padding: EdgeInsets.only(bottom: padding.bottom + 100),
      children: _items.map((item) {
        return ListTile(
          tileColor: _tileColor(theme, item.type),
          leading: item.icon,
          title: Text(item.type.title, style: titleStyle),
          subtitle: item.subtitle != null
              ? Text(item.subtitle!, style: subtitleStyle)
              : null,
          trailing: _isPortrait ? const Icon(Icons.chevron_right) : null,
          onTap: () => _toPage(item.type),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _isPortrait =
        MediaQuery.sizeOf(context).width < MediaQuery.sizeOf(context).height;
    return Scaffold(
      appBar: AppBar(title: Text(_isPortrait ? '设置' : _type.title)),
      body: _isPortrait
          ? _buildList(theme)
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: _buildList(theme)),
                VerticalDivider(
                  width: 1,
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
                Expanded(flex: 6, child: _buildDetail()),
              ],
            ),
    );
  }
}

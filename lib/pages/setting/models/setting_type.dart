enum SettingType {
  securitySettings('安全设置'),
  styleSetting('外观设置'),
  tagSetting('标签管理'),
  extraSetting('其它设置'),
  backupSetting('备份设置'),
  about('关于');

  final String title;
  const SettingType(this.title);
}

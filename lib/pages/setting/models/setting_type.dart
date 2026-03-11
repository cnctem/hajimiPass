enum SettingType {
  styleSetting('外观设置'),
  extraSetting('其它设置'),
  backupSetting('备份设置'),
  about('关于');

  final String title;
  const SettingType(this.title);
}

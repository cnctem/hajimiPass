import 'package:get/get.dart';
import 'package:hajimipass/utils/storage/storage.dart';
import 'package:hajimipass/utils/storage/storage_key.dart';
import 'package:hajimipass/utils/storage/storage_pref.dart';

class ThemeController extends GetxController {
  final setting = GStorage.setting;

  final themeType = Pref.themeType.obs;
  final dynamicColor = Pref.dynamicColor.obs;
  final isPureBlackTheme = Pref.isPureBlackTheme.obs;
  final currentTextScale = Pref.defaultTextScale.obs;
  final customColor = Pref.customColor.obs;
  final schemeVariant = Pref.schemeVariant.obs;

  @override
  void onInit() {
    super.onInit();
    // 监听变化并保存
    ever(themeType, (callback) {
      setting.put(SettingBoxKey.themeMode, callback.index);
      Get.changeThemeMode(callback.toThemeMode);
    });
    ever(dynamicColor, (callback) {
      setting.put(SettingBoxKey.dynamicColor, callback);
      Get.forceAppUpdate();
    });
    ever(isPureBlackTheme, (callback) {
      setting.put(SettingBoxKey.isPureBlackTheme, callback);
      Get.forceAppUpdate();
    });
    ever(currentTextScale, (callback) {
      setting.put(SettingBoxKey.defaultTextScale, callback);
      Get.forceAppUpdate();
    });
    ever(customColor, (callback) {
      setting.put(SettingBoxKey.customColor, callback);
      Get.forceAppUpdate();
    });
    ever(schemeVariant, (callback) {
      setting.put(SettingBoxKey.schemeVariant, callback);
      Get.forceAppUpdate();
    });
  }
}

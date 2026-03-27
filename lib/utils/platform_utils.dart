import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

abstract final class PlatformUtils {
  static final isHarmony = Platform.operatingSystem == "ohos";
  static String? _harmonyDeviceType;

  static Future<void> initHarmonyDeviceType() async {
    if (!isHarmony || _harmonyDeviceType != null) {
      return;
    }
    final type = (await DeviceInfoPlugin().ohosInfo).deviceType;
    if (type == null) {
      throw Exception("Failed to init device type");
    }
    _harmonyDeviceType = type;
    debugPrint('Harmony device type: $type');
  }

  static String? get harmonyDeviceType => _harmonyDeviceType;

  static bool get isMobile {
    if (Platform.isAndroid || Platform.isIOS) {
      return true;
    }

    if (!isHarmony) {
      return false;
    }

    final type = _harmonyDeviceType;
    return type == 'phone' || type == 'tablet';
  }

  static bool get isDesktop => !isMobile;
}

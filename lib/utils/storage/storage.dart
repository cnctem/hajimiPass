import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

abstract final class GStorage {
  static late final Box<dynamic> setting;
  static late final Box<dynamic> localCache;

  static Future<void> init() async {
    // 获取应用支持目录
    final dir = await getApplicationSupportDirectory();
    await Hive.initFlutter(path.join(dir.path, 'hive'));

    await Future.wait([
      // 设置
      Hive.openBox('setting').then((res) => setting = res),
      // 本地缓存
      Hive.openBox(
        'localCache',
        compactionStrategy: (int entries, int deletedEntries) {
          return deletedEntries > 4;
        },
      ).then((res) => localCache = res),
    ]);
  }
}

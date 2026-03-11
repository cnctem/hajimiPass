import 'package:flutter/material.dart';
import 'package:hajimipass/utils/models.dart';
import 'package:hajimipass/utils/storage/hajimi_storage.dart';

class HomeController extends ChangeNotifier {
  List<Account> _accounts = [];

  List<Account> get accounts => _accounts;

  HomeController() {
    _loadAccounts();
    // 监听数据变化，当HajimiStorage数据变化时重新加载
    HajimiStorage.instance.addListener(_loadAccounts);
  }

  @override
  void dispose() {
    HajimiStorage.instance.removeListener(_loadAccounts);
    super.dispose();
  }

  void _loadAccounts() {
    // 获取所有账号
    final list = List<Account>.from(
      HajimiStorage.instance.accountList.accountList,
    );

    // 根据名称排序
    list.sort((a, b) => a.name.compareTo(b.name));

    _accounts = list;
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'package:hajimipass/utils/models.dart';
import 'package:hajimipass/utils/storage/hajimi_storage.dart';

class HomeController extends ChangeNotifier {
  List<Account> _allAccounts = [];
  String _selectedTag = '全部';

  List<Account> get accounts {
    if (_selectedTag == '收藏') {
      return _allAccounts.where((a) => a.favorite).toList();
    }
    if (_selectedTag == '全部') return _allAccounts;
    return _allAccounts
        .where((a) => a.tagList.any((t) => t.tagName == _selectedTag))
        .toList();
  }

  List<String> get tags => [
    '收藏',
    '全部',
    ...HajimiStorage.instance.accountList.tagList.map((t) => t.tagName),
  ];

  String get selectedTag => _selectedTag;

  void selectTag(String tag) {
    _selectedTag = tag;
    notifyListeners();
  }

  HomeController() {
    _loadAccounts();
    HajimiStorage.instance.addListener(_loadAccounts);
  }

  @override
  void dispose() {
    HajimiStorage.instance.removeListener(_loadAccounts);
    super.dispose();
  }

  void _loadAccounts() {
    final list = List<Account>.from(
      HajimiStorage.instance.accountList.accountList,
    );
    list.sort((a, b) => a.name.compareTo(b.name));
    _allAccounts = list;
    notifyListeners();
  }

  Future<void> deleteAccount(Account account) async {
    HajimiStorage.instance.removeAccount(account);
    _loadAccounts();
  }
}

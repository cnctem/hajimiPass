import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hajimipass/utils/models.dart';
import 'package:hajimipass/utils/storage/hajimi_storage.dart';

class HomeController extends ChangeNotifier {
  List<Account> _allAccounts = [];
  String _selectedTag = '全部';
  bool _isReorderMode = false;

  bool get isReorderMode => _isReorderMode;

  List<Account> get accounts {
    if (_isReorderMode) return _allAccounts;
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

  void toggleReorderMode() {
    _isReorderMode = !_isReorderMode;
    SmartDialog.showToast(_isReorderMode ? '再次点击退出排序模式' : '已完成排序');
    notifyListeners();
  }

  void reorderAccounts(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final account = _allAccounts.removeAt(oldIndex);
    _allAccounts.insert(newIndex, account);
    HajimiStorage.instance.accountList.accountList
      ..clear()
      ..addAll(_allAccounts);
    HajimiStorage.instance.save();
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
    if (!_isReorderMode) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
    _allAccounts = list;
    notifyListeners();
  }

  Future<void> deleteAccount(Account account) async {
    HajimiStorage.instance.removeAccount(account);
    _loadAccounts();
  }
}

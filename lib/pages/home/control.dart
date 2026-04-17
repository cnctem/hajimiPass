import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hajimipass/utils/models.dart';
import 'package:hajimipass/utils/storage/hajimi_storage.dart';

const favoriteTag = '收藏';
const allTag = '全部';
const uncategorizedTag = '无分类';

class HomeController extends ChangeNotifier {
  static const _virtualTags = {favoriteTag, allTag, uncategorizedTag};

  List<Account> _allAccounts = [];
  String _selectedTag = allTag;
  bool _isReorderMode = false;

  bool get isReorderMode => _isReorderMode;

  List<Account> get accounts {
    if (_isReorderMode) return _allAccounts;
    if (_selectedTag == favoriteTag) {
      return _allAccounts.where((a) => a.favorite).toList();
    }
    if (_selectedTag == allTag) return _allAccounts;
    if (_selectedTag == uncategorizedTag) {
      return _allAccounts.where((a) => a.tagList.isEmpty).toList();
    }
    return _allAccounts
        .where((a) => a.tagList.any((t) => t.tagName == _selectedTag))
        .toList();
  }

  List<String> get tags => [
    favoriteTag,
    allTag,
    uncategorizedTag,
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
    final availableTags = HajimiStorage.instance.accountList.tagList
        .map((tag) => tag.tagName)
        .toSet();

    if (!_virtualTags.contains(_selectedTag) &&
        !availableTags.contains(_selectedTag)) {
      _selectedTag = allTag;
    }

    if (!_isReorderMode) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }
    _allAccounts = list;
    notifyListeners();
  }

  Future<void> deleteAccount(Account account) async {
    await HajimiStorage.instance.removeAccount(account);
    _loadAccounts();
  }
}

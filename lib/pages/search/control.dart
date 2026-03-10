import 'package:flutter/material.dart';
import 'package:hajimipass/utils/models.dart';
import 'package:hajimipass/utils/storage/hajimi_storage.dart';

class HajimiSearchController extends ChangeNotifier {
  List<Account> _accounts = [];
  String _query = '';
  bool _searchNameOnly = false; // Default to full text search

  List<Account> get accounts => _accounts;
  bool get searchNameOnly => _searchNameOnly;

  HajimiSearchController() {
    // 监听数据变化，当HajimiStorage数据变化时重新加载
    HajimiStorage.instance.addListener(_filterAccounts);
  }

  @override
  void dispose() {
    HajimiStorage.instance.removeListener(_filterAccounts);
    super.dispose();
  }

  void updateQuery(String query) {
    _query = query;
    _filterAccounts();
  }

  void toggleSearchMode() {
    _searchNameOnly = !_searchNameOnly;
    _filterAccounts();
  }

  void _filterAccounts() {
    if (_query.isEmpty) {
      _accounts = [];
      notifyListeners();
      return;
    }

    final queryLower = _query.toLowerCase();
    
    // 获取所有账号
    final allAccounts = HajimiStorage.instance.accountList.accountList;
    
    // 过滤账号
    final filtered = allAccounts.where((account) {
      // 匹配账号名称
      if (account.name.toLowerCase().contains(queryLower)) {
        return true;
      }

      // 如果只搜名称，不匹配其他字段
      if (_searchNameOnly) {
        return false;
      }
      
      // 匹配账号项
      for (final item in account.accountItemList) {
        if (item.itemName.toLowerCase().contains(queryLower) ||
            item.itemValue.toLowerCase().contains(queryLower)) {
          return true;
        }
      }
      
      // 匹配标签
      for (final tag in account.tagList) {
        if (tag.tagName.toLowerCase().contains(queryLower)) {
          return true;
        }
      }
      
      return false;
    }).toList();
    
    // 根据名称排序
    filtered.sort((a, b) => a.name.compareTo(b.name));
    
    _accounts = filtered;
    notifyListeners();
  }
}

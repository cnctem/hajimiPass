import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hajimipass/utils/models.dart';
import 'package:hajimipass/utils/storage/hajimi_storage.dart';

class EditController extends ChangeNotifier {
  late Account account;
  final Account? _originalAccount;
  late TextEditingController nameController;
  final List<AccountItemController> itemControllers = [];
  bool isSaving = false;
  String? nameError;

  EditController({Account? initialAccount})
    : _originalAccount = initialAccount {
    if (initialAccount != null) {
      account = _copyAccount(initialAccount);
    } else {
      account = Account(
        accountItemList: [],
        favorite: false,
        lastEditTime: DateTime.now().millisecondsSinceEpoch,
        name: '',
        tagList: [],
      );
    }
    _initControllers();
  }

  void _initControllers() {
    nameController = TextEditingController(text: account.name);
    for (var item in account.accountItemList) {
      itemControllers.add(AccountItemController(item));
    }
  }

  static Account _copyAccount(Account account) {
    return Account(
      accountItemList: account.accountItemList
          .map(
            (item) =>
                AccountItem(itemName: item.itemName, itemValue: item.itemValue),
          )
          .toList(),
      favorite: account.favorite,
      lastEditTime: account.lastEditTime,
      name: account.name,
      tagList: account.tagList.map((tag) => Tag(tagName: tag.tagName)).toList(),
    );
  }

  bool _isNameDuplicate(String name) {
    final accounts = HajimiStorage.instance.accountList.accountList;
    for (final a in accounts) {
      if (a.name == name && a.name != account.name) {
        return true;
      }
    }
    return false;
  }

  bool validateName() {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      nameError = '账号名称不能为空';
      SmartDialog.showToast('账号名称不能为空');
      notifyListeners();
      return false;
    }
    if (_isNameDuplicate(name)) {
      nameError = '账号名称已存在';
      SmartDialog.showToast('账号名称已存在');
      notifyListeners();
      return false;
    }
    nameError = null;
    notifyListeners();
    return true;
  }

  void clearNameError([_]) {
    if (nameError != null) {
      nameError = null;
      notifyListeners();
    }
  }

  void updateName(String name) {
    account.name = name;
    account.lastEditTime = DateTime.now().millisecondsSinceEpoch;
    notifyListeners();
  }

  void toggleFavorite() {
    account.favorite = !account.favorite;
    account.lastEditTime = DateTime.now().millisecondsSinceEpoch;
    notifyListeners();
  }

  List<String> get availableTags {
    final allTags = HajimiStorage.instance.accountList.tagList
        .map((t) => t.tagName)
        .toSet();
    final currentTags = account.tagList.map((t) => t.tagName).toSet();
    return allTags.difference(currentTags).toList()..sort();
  }

  void addTag(String tagName) {
    final normalized = tagName.trim();
    if (normalized.isEmpty) return;
    if (account.tagList.any((t) => t.tagName == normalized)) return;
    account.tagList.add(Tag(tagName: normalized));
    account.lastEditTime = DateTime.now().millisecondsSinceEpoch;
    notifyListeners();
  }

  void removeTag(int index) {
    if (index >= 0 && index < account.tagList.length) {
      account.tagList.removeAt(index);
      account.lastEditTime = DateTime.now().millisecondsSinceEpoch;
      notifyListeners();
    }
  }

  void addAccountItem() {
    final newItem = AccountItem(itemName: '', itemValue: '');
    account.accountItemList.add(newItem);
    itemControllers.add(AccountItemController(newItem));
    account.lastEditTime = DateTime.now().millisecondsSinceEpoch;
    notifyListeners();
  }

  void removeAccountItem(int index) {
    if (index >= 0 && index < account.accountItemList.length) {
      account.accountItemList.removeAt(index);
      itemControllers[index].dispose();
      itemControllers.removeAt(index);
      account.lastEditTime = DateTime.now().millisecondsSinceEpoch;
      notifyListeners();
    }
  }

  // 从UI控制器更新Account对象数据
  @protected
  void updateFromControllers() {
    account.name = nameController.text;
    // 同步Item的值
    for (var i = 0; i < itemControllers.length; i++) {
      account.accountItemList[i].itemName =
          itemControllers[i].nameController.text;
      account.accountItemList[i].itemValue =
          itemControllers[i].valueController.text;
    }
    account.lastEditTime = DateTime.now().millisecondsSinceEpoch;
  }

  void _commitToOriginalAccount() {
    if (_originalAccount == null) return;

    _originalAccount.name = account.name;
    _originalAccount.favorite = account.favorite;
    _originalAccount.lastEditTime = account.lastEditTime;
    _originalAccount.accountItemList = account.accountItemList
        .map(
          (item) =>
              AccountItem(itemName: item.itemName, itemValue: item.itemValue),
        )
        .toList();
    _originalAccount.tagList = account.tagList
        .map((tag) => Tag(tagName: tag.tagName))
        .toList();
  }

  // 保存逻辑
  Future<bool> save() async {
    if (!validateName()) return false;

    isSaving = true;
    notifyListeners();

    updateFromControllers();
    _commitToOriginalAccount();
    final original = _originalAccount;
    if (original != null) {
      await HajimiStorage.instance.updateAccount(original);
    } else {
      await HajimiStorage.instance.save();
    }

    isSaving = false;
    notifyListeners();

    debugPrint('Saved Account: ${account.toJson()}');
    SmartDialog.showToast('保存成功');
    return true;
  }

  @override
  void dispose() {
    nameController.dispose();
    for (var controller in itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}

class AccountItemController {
  final AccountItem item;
  late TextEditingController nameController;
  late TextEditingController valueController;

  AccountItemController(this.item) {
    nameController = TextEditingController(text: item.itemName);
    valueController = TextEditingController(text: item.itemValue);
  }

  void dispose() {
    nameController.dispose();
    valueController.dispose();
  }
}

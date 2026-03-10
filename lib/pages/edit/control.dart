import 'package:flutter/material.dart';
import 'package:hajimipass/utils/models.dart';
import 'package:hajimipass/utils/storage/hajimi_storage.dart';

class EditController extends ChangeNotifier {
  late Account account;
  late TextEditingController nameController;
  final List<AccountItemController> itemControllers = [];

  EditController({Account? initialAccount}) {
    if (initialAccount != null) {
      account = initialAccount;
    } else {
      // 默认空账户，如果不传initialAccount应该由子类或外部处理
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
      account.accountItemList[i].itemName = itemControllers[i].nameController.text;
      account.accountItemList[i].itemValue = itemControllers[i].valueController.text;
    }
    account.lastEditTime = DateTime.now().millisecondsSinceEpoch;
  }

  // 保存逻辑
  Future<void> save() async {
    updateFromControllers();
    
    // 调用持久化存储保存
    await HajimiStorage.instance.save();
    
    debugPrint('Saved Account: ${account.toJson()}');
    notifyListeners();
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

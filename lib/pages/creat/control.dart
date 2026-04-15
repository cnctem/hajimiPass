import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hajimipass/pages/edit/control.dart';
import 'package:hajimipass/utils/models.dart';
import 'package:hajimipass/utils/storage/hajimi_storage.dart';

class CreateController extends EditController {
  CreateController() : super(initialAccount: _createDefaultAccount());

  static Account _createDefaultAccount() {
    return Account(
      accountItemList: [
        AccountItem(itemName: '账号', itemValue: ''),
        AccountItem(itemName: '密码', itemValue: ''),
      ],
      favorite: false,
      lastEditTime: DateTime.now().millisecondsSinceEpoch,
      name: '',
      tagList: [],
    );
  }

  @override
  Future<bool> save() async {
    if (!validateName()) return false;

    updateFromControllers();
    await HajimiStorage.instance.addAccount(account);

    debugPrint('Created new Account: ${account.toJson()}');
    SmartDialog.showToast('创建成功');

    notifyListeners();
    return true;
  }
}

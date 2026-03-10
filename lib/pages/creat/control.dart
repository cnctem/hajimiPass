import 'package:hajimipass/pages/edit/control.dart';
import 'package:hajimipass/utils/models.dart';
import 'package:hajimipass/utils/storage/hajimi_storage.dart';

class CreateController extends EditController {
  CreateController() : super(initialAccount: _createDefaultAccount());

  static Account _createDefaultAccount() {
    return Account(
      accountItemList: [
        AccountItem(itemName: '密码', itemValue: ''),
      ],
      favorite: false,
      lastEditTime: DateTime.now().millisecondsSinceEpoch,
      name: '',
      tagList: [],
    );
  }

  // 重写保存逻辑如果需要特殊的创建后处理
  @override
  Future<void> save() async {
    // 1. 更新 Account 对象的数据
    updateFromControllers();
    
    // 2. 将新创建的 Account 添加到全局列表并保存
    // addAccount 内部会调用 save() 持久化
    HajimiStorage.instance.addAccount(account);
    
    print('Created new Account: ${account.toJson()}');
    notifyListeners();
  }
}

class AccountList {
  List<Account> accountList;
  int lastEditTime;
  List<Tag> tagList;
  int version;

  AccountList({
    required this.accountList,
    required this.lastEditTime,
    required this.tagList,
    required this.version,
  });

  factory AccountList.fromJson(Map<String, dynamic> json) {
    return AccountList(
      accountList:
          (json['accountList'] as List<dynamic>?)
              ?.map((e) => Account.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastEditTime: json['lastEditTime'] as int? ?? 0,
      tagList:
          (json['tagList'] as List<dynamic>?)
              ?.map((e) => Tag.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      version: json['version'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountList': accountList.map((e) => e.toJson()).toList(),
      'lastEditTime': lastEditTime,
      'tagList': tagList.map((e) => e.toJson()).toList(),
      'version': version,
    };
  }
}

class Account {
  List<AccountItem> accountItemList;
  bool favorite;
  int lastEditTime;
  String name;
  List<Tag> tagList;

  Account({
    required this.accountItemList,
    required this.favorite,
    required this.lastEditTime,
    required this.name,
    required this.tagList,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      accountItemList:
          (json['accountItemList'] as List<dynamic>?)
              ?.map((e) => AccountItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      favorite: json['favorite'] as bool? ?? false,
      lastEditTime: json['lastEditTime'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      tagList:
          (json['tagList'] as List<dynamic>?)
              ?.map((e) => Tag.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountItemList': accountItemList.map((e) => e.toJson()).toList(),
      'favorite': favorite,
      'lastEditTime': lastEditTime,
      'name': name,
      'tagList': tagList.map((e) => e.toJson()).toList(),
    };
  }
}

class AccountItem {
  String itemName;
  String itemValue;

  AccountItem({required this.itemName, required this.itemValue});

  factory AccountItem.fromJson(Map<String, dynamic> json) {
    return AccountItem(
      itemName: json['itemName'] as String? ?? '',
      itemValue: json['itemValue'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'itemName': itemName, 'itemValue': itemValue};
  }
}

class Tag {
  String tagName;

  Tag({required this.tagName});

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(tagName: json['tagName'] as String? ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'tagName': tagName};
  }
}

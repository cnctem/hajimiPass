import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hajimipass/pages/setting/models/model.dart';
import 'package:hajimipass/utils/storage/storage_pref.dart';

List<SettingsModel> get securitySettings {
  return [
    NormalModel(
      onTap: (context, setState) async {
        await context.push('/keyInit');
        setState();
      },
      getTitle: () => Pref.passwordHint.isEmpty ? '初始化密钥' : '更改密钥',
      getSubtitle: () =>
          Pref.passwordHint.isEmpty ? null : '提示: ${Pref.passwordHint}',
      leading: const Icon(Icons.vpn_key_outlined),
    ),
  ];
}

// ignore_for_file: avoid_print
import 'package:hajimipass/utils/translate.dart';

void main() {
  // 1. 创建密钥（任意字符串作为 seed，生成专属字符表）
  const String key = '我的专属密钥';
  final String haJimiWords = getHaJimiWords(key);
  print('密钥字符表: $haJimiWords');

  // 2. 加密
  const String plainText = '你好，世界！';
  final String encrypted = humanToHaJimi(plainText, key);
  print('加密结果: $encrypted');

  // 3. 解密
  final String decrypted = haJimiToHuman(encrypted, key);
  print('解密结果: $decrypted');

  assert(decrypted == plainText, '解密结果与原文不符');
}

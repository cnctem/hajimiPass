import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:hajimipass/utils/hajimi/secure_chat_service.dart';
import 'package:hajimipass/utils/hajimi/contact_store.dart';

void main() {
  group('SecureChatService — ECDH + ChaCha20 加盐加密全流程', () {
    late SecureChatService alice;
    late SecureChatService bob;

    setUp(() async {
      alice = SecureChatService();
      bob = SecureChatService();
      await alice.init();
      await bob.init();
    });

    test('ECDH 密钥协商：双方共享密钥一致', () async {
      final alicePub = await alice.x25519PublicKey;
      final bobPub = await bob.x25519PublicKey;

      final aliceShared = await alice.computeSharedKey(bobPub);
      final bobShared = await bob.computeSharedKey(alicePub);

      expect(aliceShared, equals(bobShared));
    });

    test('Ed25519 签名验证：防中间人攻击', () async {
      final aliceEd = await alice.ed25519PublicKey;
      final aliceDhPub = await alice.x25519PublicKey;
      final sig = await alice.signDHPublicKey();

      final valid = await SecureChatService.verifyDHSignature(aliceDhPub, sig, aliceEd);
      expect(valid, isTrue);
    });

    test('Ed25519 签名验证：篡改公钥后验证失败', () async {
      final aliceEd = await alice.ed25519PublicKey;
      final aliceDhPub = await alice.x25519PublicKey;
      final sig = await alice.signDHPublicKey();

      // 篡改 DH 公钥
      final tampered = Uint8List.fromList(aliceDhPub..[0] ^= 0xFF);
      final valid = await SecureChatService.verifyDHSignature(tampered, sig, aliceEd);
      expect(valid, isFalse);
    });

    test('AEAD 加密解密：每次 nonce 不同（加盐），密文不同', () async {
      final bobPub = await bob.x25519PublicKey;
      await alice.computeSharedKey(bobPub);
      await bob.computeSharedKey(await alice.x25519PublicKey);

      const plaintext = '你好，哈基米！';
      final enc1 = await alice.encryptAEAD(plaintext);
      final enc2 = await alice.encryptAEAD(plaintext);

      // 随机 nonce 保证每次密文不同
      expect(enc1.nonce, isNot(equals(enc2.nonce)));
      expect(enc1.ciphertext, isNot(equals(enc2.ciphertext)));

      // 双方均可解密
      final dec1 = await bob.decryptAEAD(enc1.ciphertext, enc1.nonce);
      final dec2 = await bob.decryptAEAD(enc2.ciphertext, enc2.nonce);
      expect(dec1, equals(plaintext));
      expect(dec2, equals(plaintext));
    });

    test('AEAD 静态方法：encryptByKeyAEAD / decryptByKeyAEAD', () async {
      final bobPub = await bob.x25519PublicKey;
      final sharedKey = await alice.computeSharedKey(bobPub);

      const plaintext = '密码本测试消息';
      final enc = await SecureChatService.encryptByKeyAEAD(plaintext, sharedKey);
      final dec = await SecureChatService.decryptByKeyAEAD(enc.ciphertext, enc.nonce, sharedKey);

      expect(dec, equals(plaintext));
    });

    test('Raw ChaCha20 加密解密：8 字节随机 nonce', () async {
      final bobPub = await bob.x25519PublicKey;
      await alice.computeSharedKey(bobPub);
      await bob.computeSharedKey(await alice.x25519PublicKey);

      const plaintext = 'ChaCha20 流加密测试';
      final enc = await alice.encryptRaw(plaintext);
      final dec = await bob.decryptRaw(enc.ciphertext, enc.nonce);

      expect(dec, equals(plaintext));
    });

    test('固定 nonce ChaCha20：相同明文密文相同（极限压缩模式）', () async {
      final bobPub = await bob.x25519PublicKey;
      await alice.computeSharedKey(bobPub);
      await bob.computeSharedKey(await alice.x25519PublicKey);

      const plaintext = '固定nonce测试';
      final ct1 = await alice.encryptRawFixedNonce(plaintext);
      final ct2 = await alice.encryptRawFixedNonce(plaintext);
      expect(ct1, equals(ct2)); // 固定 nonce，结果确定

      final dec = await bob.decryptRawFixedNonce(ct1);
      expect(dec, equals(plaintext));
    });

    test('Hex 工具：uint8ArrayToHex / hexToUint8Array 互转', () {
      final bytes = Uint8List.fromList([0x00, 0xAB, 0xFF, 0x12]);
      final hex = SecureChatService.uint8ArrayToHex(bytes);
      expect(hex, equals('00abff12'));
      expect(SecureChatService.hexToUint8Array(hex), equals(bytes));
    });
  });

  group('ContactStore — PBKDF2 + AES-GCM 本地加密存储', () {
    late ContactStore store;

    setUp(() {
      store = ContactStore(InMemoryStorage());
    });

    test('首次设置密码成功', () async {
      final result = await store.setPassword('mypassword', 'mypassword');
      expect(result, equals('success'));
      expect(store.unlocked, isTrue);
    });

    test('两次密码不一致返回 fail', () async {
      final result = await store.setPassword('abc', 'xyz');
      expect(result, equals('fail'));
    });

    test('添加联系人密钥并读取', () async {
      await store.setPassword('pass', 'pass');
      final key = Uint8List.fromList(List.generate(32, (i) => i));
      final r = await store.setSecretKey('Alice', key);
      expect(r, equals('success'));

      final got = store.getSecretKey('Alice');
      expect(got, equals(key));
    });

    test('重复添加同名联系人返回 duplicate_user', () async {
      await store.setPassword('pass', 'pass');
      final key = Uint8List(32);
      await store.setSecretKey('Bob', key);
      final r = await store.setSecretKey('Bob', key);
      expect(r, equals('duplicate_user'));
    });

    test('auth 解锁：加密存储后用正确密码解锁可读取数据', () async {
      await store.setPassword('secret', 'secret');
      final key = Uint8List.fromList(List.generate(32, (i) => i * 2));
      await store.setSecretKey('Charlie', key);

      // 新建 store 模拟重启，共享同一 storage
      final storage = InMemoryStorage();
      final store2 = ContactStore(storage);
      await store2.setPassword('secret', 'secret');
      await store2.setSecretKey('Charlie', key);

      final store3 = ContactStore(storage);
      final authResult = await store3.auth('secret');
      expect(authResult, equals('success'));
      expect(store3.getSecretKey('Charlie'), equals(key));
    });

    test('auth 解锁：错误密码返回 fail', () async {
      final storage = InMemoryStorage();
      final s = ContactStore(storage);
      await s.setPassword('correct', 'correct');

      final s2 = ContactStore(storage);
      final r = await s2.auth('wrong');
      expect(r, equals('fail'));
    });

    test('未解锁时操作返回 access_denied', () {
      final r = store.getSecretKey('anyone');
      expect(r, equals('access_denied'));
    });

    test('exportRaw / importRaw 往返', () async {
      await store.setPassword('pw', 'pw');
      final key = Uint8List.fromList(List.generate(32, (i) => i));
      await store.setSecretKey('Dave', key);

      final raw = store.exportRaw();
      expect(raw, isNotEmpty);

      final store2 = ContactStore(InMemoryStorage());
      final importResult = store2.importRaw(raw);
      expect(importResult, equals('success'));

      final authResult = await store2.auth('pw');
      expect(authResult, equals('success'));
      expect(store2.getSecretKey('Dave'), equals(key));
    });

    test('rename 联系人', () async {
      await store.setPassword('pw', 'pw');
      final key = Uint8List(32);
      await store.setSecretKey('OldName', key);
      final r = await store.rename('OldName', 'NewName');
      expect(r, equals('success'));
      expect(store.getSecretKey('OldName'), equals('null_user'));
      expect(store.getSecretKey('NewName'), equals(key));
    });

    test('remove 联系人', () async {
      await store.setPassword('pw', 'pw');
      final key = Uint8List(32);
      await store.setSecretKey('Eve', key);
      final r = await store.remove('Eve');
      expect(r, equals('success'));
      expect(store.getSecretKey('Eve'), equals('null_user'));
    });

    test('clear 清空所有数据', () async {
      await store.setPassword('pw', 'pw');
      store.clear();
      expect(store.unlocked, isFalse);
      expect(store.hasClear, isTrue);
    });
  });
}

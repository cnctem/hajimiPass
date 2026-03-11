import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// 暂时用不到

/// 哈基密语端到端加密通信服务
///
/// @author WIFI连接超时
/// @version 1.0
/// Create Time 2025/7/29_00:55

class PublicIdentity {
  final Uint8List ed25519PublicKey;
  final Uint8List dhPublicKey;
  final Uint8List dhSignature;

  const PublicIdentity({
    required this.ed25519PublicKey,
    required this.dhPublicKey,
    required this.dhSignature,
  });
}

class EncryptedMessage {
  final Uint8List nonce;
  final Uint8List ciphertext;

  const EncryptedMessage({required this.nonce, required this.ciphertext});
}

class SecureChatService {
  // Ed25519 签名密钥对：身份认证和签名
  SimpleKeyPair? _ed25519;

  // X25519 密钥对：Diffie-Hellman 密钥交换
  SimpleKeyPair? _x25519;

  // 对称加密密钥（ECDH 协商结果）
  Uint8List? _sharedKey;

  bool _isReady = false;

  // 写死的 nonce，只在追求极限压缩的时候用
  static final Uint8List _fixedNonce = Uint8List(8);

  static final _ed25519Algo = Ed25519();
  static final _x25519Algo = X25519();
  static final _chacha20Aead = Chacha20.poly1305Aead();
  static final _chacha20Raw = Chacha20(macAlgorithm: MacAlgorithm.empty);

  /// 初始化，生成 Ed25519 和 X25519 密钥对
  Future<void> init() async {
    if (_isReady) return;
    _ed25519 = await _ed25519Algo.newKeyPair();
    _x25519 = await _x25519Algo.newKeyPair();
    _isReady = true;
  }

  void _assertReady() {
    if (!_isReady) throw StateError('尚未初始化：请先调用 init()');
  }

  void _assertSharedKey() {
    if (_sharedKey == null) throw StateError('共享密钥未建立：请先调用 computeSharedKey()');
  }

  /// 获取 Ed25519 公钥（用于身份认证对外公布）
  Future<Uint8List> get ed25519PublicKey async {
    _assertReady();
    final pub = await _ed25519!.extractPublicKey();
    return Uint8List.fromList(pub.bytes);
  }

  /// 获取 X25519 公钥（用于共享密钥协商）
  Future<Uint8List> get x25519PublicKey async {
    _assertReady();
    final pub = await _x25519!.extractPublicKey();
    return Uint8List.fromList(pub.bytes);
  }

  /// 签名自己的 X25519 公钥，防止中间人攻击
  Future<Uint8List> signDHPublicKey() async {
    _assertReady();
    final dhPub = await _x25519!.extractPublicKey();
    final sig = await _ed25519Algo.sign(dhPub.bytes, keyPair: _ed25519!);
    return Uint8List.fromList(sig.bytes);
  }

  /// 计算共享密钥（X25519 ECDH）
  Future<Uint8List> computeSharedKey(Uint8List peerPublicKeyBytes) async {
    _assertReady();
    final peerPub = SimplePublicKey(
      peerPublicKeyBytes,
      type: KeyPairType.x25519,
    );
    final sharedSecret = await _x25519Algo.sharedSecretKey(
      keyPair: _x25519!,
      remotePublicKey: peerPub,
    );
    _sharedKey = Uint8List.fromList(await sharedSecret.extractBytes());
    return _sharedKey!;
  }

  /// ChaCha20-Poly1305 AEAD 加密（带认证，防篡改）
  /// 随机 12 字节 nonce
  Future<EncryptedMessage> encryptAEAD(String message) {
    _assertSharedKey();
    return _encryptAEADWithKey(message, _sharedKey!);
  }

  /// ChaCha20-Poly1305 AEAD 解密
  Future<String> decryptAEAD(Uint8List ciphertext, Uint8List nonce) {
    _assertSharedKey();
    return _decryptAEADWithKey(ciphertext, nonce, _sharedKey!);
  }

  /// ChaCha20 流加密，无认证，随机 8 字节 nonce
  Future<EncryptedMessage> encryptRaw(String message) {
    _assertSharedKey();
    return _encryptRawWithKey(message, _sharedKey!);
  }

  /// ChaCha20 流解密，无认证
  Future<String> decryptRaw(Uint8List ciphertext, Uint8List nonce) {
    _assertSharedKey();
    return _decryptRawWithKey(ciphertext, nonce, _sharedKey!);
  }

  /// 固定 nonce 的 ChaCha20 加密（极限压缩用，无认证）
  Future<Uint8List> encryptRawFixedNonce(String message) async {
    _assertSharedKey();
    final plaintext = utf8.encode(message);
    final key = SecretKey(_sharedKey!);
    final box = await _chacha20Raw.encrypt(
      plaintext,
      secretKey: key,
      nonce: _fixedNonce,
    );
    return Uint8List.fromList(box.cipherText);
  }

  /// 固定 nonce 的 ChaCha20 解密
  Future<String> decryptRawFixedNonce(Uint8List ciphertext) async {
    _assertSharedKey();
    final key = SecretKey(_sharedKey!);
    final box = SecretBox(ciphertext, nonce: _fixedNonce, mac: Mac.empty);
    final plaintext = await _chacha20Raw.decrypt(box, secretKey: key);
    return utf8.decode(plaintext);
  }

  /// 导出身份信息（用于群聊广播等）
  Future<PublicIdentity> exportPublicIdentity() async {
    _assertReady();
    return PublicIdentity(
      ed25519PublicKey: await ed25519PublicKey,
      dhPublicKey: await x25519PublicKey,
      dhSignature: await signDHPublicKey(),
    );
  }

  /// 静态：验证对方 DH 公钥签名
  static Future<bool> verifyDHSignature(
    Uint8List dhPublicKey,
    Uint8List signature,
    Uint8List ed25519PublicKeyBytes,
  ) {
    final pub = SimplePublicKey(
      ed25519PublicKeyBytes,
      type: KeyPairType.ed25519,
    );
    final sig = Signature(signature, publicKey: pub);
    return _ed25519Algo.verify(dhPublicKey, signature: sig);
  }

  /// 静态：ChaCha20-Poly1305 AEAD 加密（传入共享密钥，支持 String 或 `List<int>`）
  static Future<EncryptedMessage> encryptByKeyAEAD(
    Object message,
    Uint8List sharedKey,
  ) {
    final bytes = message is String
        ? utf8.encode(message)
        : message as List<int>;
    return _encryptAEADWithKey(null, sharedKey, rawBytes: bytes);
  }

  /// 静态：ChaCha20-Poly1305 AEAD 解密（传入共享密钥）
  static Future<Object> decryptByKeyAEAD(
    Uint8List ciphertext,
    Uint8List nonce,
    Uint8List sharedKey, {
    bool raw = false,
  }) async {
    final result = await _decryptAEADWithKey(ciphertext, nonce, sharedKey);
    if (raw) return utf8.encode(result);
    return result;
  }

  /// Uint8List 转 Hex
  static String uint8ArrayToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Hex 转 Uint8List
  static Uint8List hexToUint8Array(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }

  // --- 内部实现 ---

  static Future<EncryptedMessage> _encryptAEADWithKey(
    String? message,
    Uint8List sharedKey, {
    List<int>? rawBytes,
  }) async {
    final plaintext = rawBytes ?? utf8.encode(message!);
    final nonce = _randomBytes(12);
    final key = SecretKey(sharedKey);
    final box = await _chacha20Aead.encrypt(
      plaintext,
      secretKey: key,
      nonce: nonce,
    );
    // ciphertext + 16-byte Poly1305 MAC
    final combined = Uint8List.fromList(box.cipherText + box.mac.bytes);
    return EncryptedMessage(
      nonce: Uint8List.fromList(nonce),
      ciphertext: combined,
    );
  }

  static Future<String> _decryptAEADWithKey(
    Uint8List ciphertext,
    Uint8List nonce,
    Uint8List sharedKey,
  ) async {
    final key = SecretKey(sharedKey);
    // 末尾 16 字节是 MAC
    final mac = Mac(ciphertext.sublist(ciphertext.length - 16));
    final ct = ciphertext.sublist(0, ciphertext.length - 16);
    final box = SecretBox(ct, nonce: nonce, mac: mac);
    final plaintext = await _chacha20Aead.decrypt(box, secretKey: key);
    return utf8.decode(plaintext);
  }

  static Future<EncryptedMessage> _encryptRawWithKey(
    String message,
    Uint8List sharedKey,
  ) async {
    final plaintext = utf8.encode(message);
    final nonce = _randomBytes(8);
    final key = SecretKey(sharedKey);
    final box = await _chacha20Raw.encrypt(
      plaintext,
      secretKey: key,
      nonce: nonce,
    );
    return EncryptedMessage(
      nonce: Uint8List.fromList(nonce),
      ciphertext: Uint8List.fromList(box.cipherText),
    );
  }

  static Future<String> _decryptRawWithKey(
    Uint8List ciphertext,
    Uint8List nonce,
    Uint8List sharedKey,
  ) async {
    final key = SecretKey(sharedKey);
    final box = SecretBox(ciphertext, nonce: nonce, mac: Mac.empty);
    final plaintext = await _chacha20Raw.decrypt(box, secretKey: key);
    return utf8.decode(plaintext);
  }

  static List<int> _randomBytes(int length) {
    final buf = Uint8List(length);
    final rng = SecureRandom.fast;
    for (var i = 0; i < length; i++) {
      buf[i] = rng.nextInt(256);
    }
    return buf;
  }
}

// 懒汉式单例
SecureChatService? _instance;

SecureChatService getSecureChatService() {
  _instance ??= SecureChatService();
  return _instance!;
}

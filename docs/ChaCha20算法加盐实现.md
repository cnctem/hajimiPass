**加盐实现**

- 聊天加密的“盐”就是随机 nonce：在 SecureChatService.encryptByKeyAEAD 中用 libsodium 生成随机 nonce（12 字节），与密文一起返回；在 UI 层将 nonce 编码后拼到密文前面输出成哈基密语文本，[SecureChatService.encryptByKeyAEAD](/lib/utils/service/SecureChatService.ts#L222-L243)、[HaJimiTextArea.encryptToHaJimi](/lib/utils/views/index/components/content/HaJimiTextArea.vue#L177-L194)。
- 普通流加密也用随机 nonce 作为“盐”：encryptRaw 中生成 8 字节 nonce，解密时必须传回同一 nonce，[SecureChatService.encryptRaw](/lib/utils/service/SecureChatService.ts#L139-L167)。
- 本地密钥存储使用 PBKDF2 的盐：保存联系人密钥时随机生成 16 字节 salt，参与 PBKDF2 派生 AES-GCM 密钥并写入 payload；认证时读取 payload 的 salt 再派生密钥解密，[contactStore.save/auth](/lib/utils/stores/contactStore.ts#L85-L189)。

**流程小结**

- 消息加密：随机 nonce（盐） → 加密 → nonce + ciphertext 编码输出。  
- 本地缓存加密：随机 salt → PBKDF2 派生密钥 → AES-GCM 加密 → salt/iv/iterations 存储。

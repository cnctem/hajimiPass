# hajimiPass

[中文版本](./README.md)

## Introduction

hajimiPass is a password management tool developed with Flutter, inspired by the [Ha-Jimi language](https://github.com/wifi504/translate-ha-jimi). It provides a clean and intuitive interface to help users securely store and manage various account credentials.

## Supported Platforms

- [x] Android: `.apk`
- [x] iOS: `.ipa`
- [x] macOS: `.dmg`
- [x] Windows: `.zip`->`.exe`
- [x] Linux: `.tar.gz`
- [x] HarmonyOS: `.hap`

## Features

- 🔐 **Secure Storage** - Protects your password data with encryption
- 📱 **Cross-Platform** - Supports multiple operating systems
- ⭐ **Favorites** - Quickly mark and access frequently used accounts
- 🔍 **Quick Search** - Convenient search function to find accounts quickly
- 🎨 **Theme Customization** - Customizable theme colors and font sizes
- 📋 **One-Click Copy** - Tap to copy account information
- 🌙 **Dark Mode** - Supports light/dark theme switching

## Download

You can download the latest version from the [Releases](https://github.com/cnctem/hajimiPass/releases) page.

## Security

This application uses industry-standard encryption algorithms to protect your password data:

- **ChaCha20-Poly1305** - For data encryption, providing authenticated encryption (AEAD)
- **PBKDF2** - For key derivation, enhanced with random salt values
- **Implicit Verification** - Verifies password correctness by attempting decryption, without storing password hashes

For detailed technical implementation, please refer to:
- [ChaCha20 Algorithm Salt Implementation](./ChaCha20算法加盐实现.md)
- [Key Verification Mechanism](./密钥验证机制.md)

For more algorithm details, see the [Ha-Jimi repository](https://github.com/wifi504/translate-ha-jimi)

This repository is not responsible for the security of password data. Users are responsible for keeping their master password safe.

## Disclaimer

This project is for educational and communication purposes only. Please comply with local laws and regulations. The developers are not responsible for any direct or indirect losses caused by using this software.

## Acknowledgments

- [translate-ha-jimi](https://github.com/wifi504/translate-ha-jimi) - Project inspiration
- [Flutter](https://flutter.dev/) - Cross-platform development framework
- [Flutter ohos](https://gitcode.com/openharmony-tpc/flutter_flutter) - Flutter HarmonyOS adaptation

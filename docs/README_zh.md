# 哈基密码本

[English Version](./README_en.md)

## 简介

hajimiPass 是一款基于 Flutter 开发的密码管理工具，灵感来源于[哈基密语](https://github.com/wifi504/translate-ha-jimi)。它提供了简洁直观的界面，帮助用户安全地存储和管理各类账号密码信息。

## 适配平台

- [x] Android: `.apk`
- [x] iOS: `.ipa`
- [x] macOS: `.dmg`
- [x] Windows: `.zip`->`.exe`
- [x] Linux: `.tar.gz`
- [x] HarmonyOS: `.hap`

## 功能

- 🔐 **安全存储** - 使用加密技术保护您的密码数据
- 📱 **跨平台** - 支持多种操作系统，数据可在多设备间同步
- ⭐ **收藏管理** - 快速标记和访问常用账号
- 🔍 **快速搜索** - 便捷的搜索功能，快速找到所需账号
- 🎨 **主题定制** - 支持自定义主题颜色和字体大小
- 📋 **一键复制** - 点击即可复制账号信息
- 🌙 **深色模式** - 支持浅色/深色主题切换

## 下载

您可以在 [Releases](https://github.com/cnctem/hajimiPass/releases) 页面下载最新版本：

## 安全性说明

本应用采用业界标准的加密算法保护您的密码数据：

- **ChaCha20-Poly1305** - 用于数据加密，提供认证加密（AEAD）
- **PBKDF2** - 用于密钥派生，配合随机盐值增强安全性
- **隐式验证机制** - 通过尝试解密验证密码正确性，无需存储密码哈希

详细技术实现请参考：

- [ChaCha20 算法加盐实现](./ChaCha20算法加盐实现.md)
- [密钥验证机制](./密钥验证机制.md)

更多算法详情详见 [哈基密语仓库](https://github.com/wifi504/translate-ha-jimi)

本仓库不对密码数据的安全性负责，用户需自行保管主密码。

## 声明

本项目仅供学习交流使用，请遵守当地法律法规。开发者不对因使用本软件而产生的任何直接或间接损失负责。

## 致谢

- [translate-ha-jimi](https://github.com/wifi504/translate-ha-jimi) - 项目灵感来源
- [Flutter](https://flutter.dev/) - 跨平台开发框架
- [Flutter ohos](https://gitcode.com/openharmony-tpc/flutter_flutter) - Flutter 鸿蒙适配

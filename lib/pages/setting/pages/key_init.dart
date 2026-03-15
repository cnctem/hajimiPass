import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:hajimipass/utils/storage/hajimi_storage.dart';
import 'package:hajimipass/utils/storage/storage_pref.dart';

class KeyInitPage extends StatefulWidget {
  const KeyInitPage({super.key});

  @override
  State<KeyInitPage> createState() => _KeyInitPageState();
}

class _KeyInitPageState extends State<KeyInitPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _newPasswordConfirmController = TextEditingController();
  final _hintController = TextEditingController();

  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureNewPasswordConfirm = true;
  bool _isLoading = false;

  bool get _isChangeMode => Pref.passwordHint.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_isChangeMode) {
      _hintController.text = Pref.passwordHint;
    }
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _newPasswordConfirmController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final storage = HajimiStorage.instance;
      final oldPassword = _oldPasswordController.text;
      final newPassword = _newPasswordController.text;
      final hint = _hintController.text.trim();

      if (_isChangeMode) {
        final authSuccess = await storage.auth(oldPassword);
        if (!authSuccess) {
          SmartDialog.showToast('原密钥验证失败');
          setState(() => _isLoading = false);
          return;
        }
      }

      await storage.setPassword(newPassword);
      Pref.passwordHint = hint;

      SmartDialog.showToast(_isChangeMode ? '密钥更改成功' : '密钥初始化成功');
      Get.offAllNamed('/');
    } catch (e) {
      SmartDialog.showToast('操作失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: _isChangeMode,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(_isChangeMode ? '更改密钥' : '初始化密钥'),
          automaticallyImplyLeading: _isChangeMode,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isChangeMode) ...[
                  Text(
                    '原密钥',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _oldPasswordController,
                    obscureText: _obscureOldPassword,
                    decoration: InputDecoration(
                      labelText: '输入原密钥',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureOldPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureOldPassword = !_obscureOldPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (_isChangeMode && (value == null || value.isEmpty)) {
                        return '请输入原密钥';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                ],
                Text(
                  '新密钥',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: '输入新密钥',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入新密钥';
                    }
                    if (value.length < 6) {
                      return '密钥长度至少6位';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newPasswordConfirmController,
                  obscureText: _obscureNewPasswordConfirm,
                  decoration: InputDecoration(
                    labelText: '重复新密钥',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPasswordConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureNewPasswordConfirm =
                              !_obscureNewPasswordConfirm;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请重复新密钥';
                    }
                    if (value != _newPasswordController.text) {
                      return '两次输入的新密钥不一致';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  '密钥提示',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _hintController,
                  decoration: const InputDecoration(
                    labelText: '输入密钥提示（必填）',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入密钥提示';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isChangeMode ? '确认更改' : '确认初始化'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

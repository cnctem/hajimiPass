import 'package:flutter/material.dart';
import 'package:hajimipass/pages/edit/control.dart';

class EditPage extends StatefulWidget {
  final EditController? controller;
  final String? title;

  const EditPage({super.key, this.controller, this.title});

  @override
  State<EditPage> createState() => EditPageState();
}

class EditPageState extends State<EditPage> {
  late EditController controller;

  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? EditController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title ?? '编辑账号'),
            actions: [
              IconButton(
                tooltip: '添加项',
                icon: const Icon(Icons.add),
                onPressed: controller.addAccountItem,
              ),
              IconButton(
                tooltip: controller.account.favorite ? '取消收藏' : '收藏',
                icon: Icon(
                  controller.account.favorite ? Icons.star : Icons.star_border,
                ),
                onPressed: controller.toggleFavorite,
              ),
              IconButton(
                tooltip: '保存',
                icon: controller.isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                onPressed: controller.isSaving
                    ? null
                    : () async {
                        await controller.save();
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 32.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldCard(
                  context: context,
                  label: Text(
                    '账号名称',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  controller: controller.nameController,
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.itemControllers.length,
                  itemBuilder: (context, index) {
                    final itemCtrl = controller.itemControllers[index];
                    return _buildFieldCard(
                      context: context,
                      label: TextField(
                        controller: itemCtrl.nameController,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          hintText: '请输入项名称',
                        ),
                      ),
                      controller: itemCtrl.valueController,
                      onDelete: () => controller.removeAccountItem(index),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFieldCard({
    required BuildContext context,
    required Widget label,
    required TextEditingController controller,
    VoidCallback? onDelete,
  }) {
    // 移除了 Card 和背景色，仅使用 Padding 保持间距
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: label),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onDelete,
                ),
            ],
          ),
          TextField(
            controller: controller,
            style: const TextStyle(fontSize: 16),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.only(top: 8, bottom: 8),
              // 默认使用 UnderlineInputBorder
            ),
          ),
        ],
      ),
    );
  }
}

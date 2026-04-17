import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hajimipass/pages/setting/models/model.dart';
import 'package:hajimipass/utils/storage/hajimi_storage.dart';

class EditableTag {
  EditableTag(this.originalName) : currentName = originalName;

  final String originalName;
  String currentName;
  bool markedForDeletion = false;

  String get normalizedName => HajimiStorage.normalizeTagName(currentName);
}

List<SettingsModel> tagSettings({
  required List<EditableTag> tags,
  required bool showAppBar,
  required bool isSaving,
  required bool hasPendingChanges,
  required Future<void> Function() onSave,
  required VoidCallback refresh,
}) {
  final items = <SettingsModel>[];

  if (!showAppBar) {
    items.addAll([
      const NormalModel(
        title: '标签管理',
        subtitle: '可批量重命名或删除现有标签',
        leading: Icon(Icons.label_outline),
      ),
      NormalModel(
        title: '保存修改',
        getSubtitle: () {
          if (isSaving) {
            return '正在保存标签修改';
          }
          if (hasPendingChanges) {
            return '应用所有标签重命名和删除';
          }
          return '暂无待保存修改';
        },
        leading: isSaving
            ? const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save_outlined),
        getTrailing: () => !isSaving && hasPendingChanges
            ? const Icon(Icons.chevron_right)
            : const SizedBox.shrink(),
        onTap: (context, setState) async {
          await onSave();
          refresh();
        },
      ),
    ]);
  }

  if (tags.isEmpty) {
    items.add(
      const NormalModel(
        title: '暂无标签',
        subtitle: '账号中使用标签后会显示在这里',
        leading: Icon(Icons.label_outline),
      ),
    );
    return items;
  }

  items.addAll(
    tags.map(
      (tag) => NormalModel(
        leading: const Icon(Icons.label_outline),
        getTitle: () =>
            tag.currentName.isEmpty ? tag.originalName : tag.currentName,
        getSubtitle: () {
          if (tag.markedForDeletion) {
            return '已标记删除，保存后生效';
          }
          if (tag.normalizedName.isEmpty) {
            return '标签名称不能为空';
          }
          if (tag.normalizedName != tag.originalName) {
            return '原标签：${tag.originalName}';
          }
          return '点按重命名';
        },
        getTrailing: () => Builder(
          builder: (context) {
            final theme = Theme.of(context);
            return IconButton(
              tooltip: tag.markedForDeletion ? '取消删除' : '标记删除',
              onPressed: () {
                tag.markedForDeletion = !tag.markedForDeletion;
                refresh();
              },
              icon: Icon(
                tag.markedForDeletion
                    ? Icons.restore_from_trash_outlined
                    : Icons.delete_outline,
                color: tag.markedForDeletion ? theme.colorScheme.error : null,
              ),
            );
          },
        ),
        onTap: (context, setState) async {
          if (tag.markedForDeletion) {
            SmartDialog.showToast('已标记删除，请先取消删除再重命名');
            return;
          }

          final controller = TextEditingController(text: tag.currentName);
          final result = await showDialog<String>(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                title: const Text('重命名标签'),
                content: TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: tag.originalName,
                    hintText: '标签名称',
                  ),
                  onSubmitted: (value) {
                    Navigator.of(dialogContext).pop(value);
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(dialogContext).pop(controller.text),
                    child: const Text('确定'),
                  ),
                ],
              );
            },
          );
          controller.dispose();

          if (result == null) {
            return;
          }

          final nextName = HajimiStorage.normalizeTagName(result);
          if (nextName.isEmpty) {
            SmartDialog.showToast('标签名称不能为空');
            return;
          }

          tag.currentName = nextName;
          refresh();
        },
      ),
    ),
  );

  return items;
}

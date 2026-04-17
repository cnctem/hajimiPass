import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hajimipass/pages/setting/models/tag_settings.dart';
import 'package:hajimipass/utils/storage/hajimi_storage.dart';

class TagSetting extends StatefulWidget {
  const TagSetting({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<TagSetting> createState() => _TagSettingState();
}

class _TagSettingState extends State<TagSetting> {
  late List<EditableTag> _tags;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tags = _buildTags();
  }

  List<EditableTag> _buildTags() {
    return HajimiStorage.instance.accountList.tagList
        .map((tag) => EditableTag(tag.tagName))
        .toList();
  }

  bool get _hasPendingChanges {
    return _tags.any(
      (tag) => tag.markedForDeletion || tag.normalizedName != tag.originalName,
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final renameMap = <String, String>{};
    final deleteTags = <String>[];
    final activeNames = <String>{};

    for (final tag in _tags) {
      if (tag.markedForDeletion) {
        deleteTags.add(tag.originalName);
        continue;
      }

      final currentName = tag.normalizedName;
      if (currentName.isEmpty) {
        SmartDialog.showToast('标签名称不能为空');
        return;
      }
      if (!activeNames.add(currentName)) {
        SmartDialog.showToast('标签名称不能重复');
        return;
      }
      if (currentName != tag.originalName) {
        renameMap[tag.originalName] = currentName;
      }
    }

    if (renameMap.isEmpty && deleteTags.isEmpty) {
      SmartDialog.showToast('没有需要保存的修改');
      return;
    }

    setState(() => _isSaving = true);
    await HajimiStorage.instance.batchUpdateTags(
      renameMap: renameMap,
      deleteTags: deleteTags,
    );
    if (!mounted) return;

    setState(() {
      _tags = _buildTags();
      _isSaving = false;
    });
    SmartDialog.showToast('保存成功');
  }

  Widget _buildSaveAction() {
    final canSave = !_isSaving && _hasPendingChanges;
    return TextButton.icon(
      onPressed: canSave ? _save : null,
      icon: _isSaving
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.save_outlined),
      label: const Text('保存'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showAppBar = widget.showAppBar;
    final padding = MediaQuery.viewPaddingOf(context);
    final settings = tagSettings(
      tags: _tags,
      showAppBar: showAppBar,
      isSaving: _isSaving,
      hasPendingChanges: _hasPendingChanges,
      onSave: _save,
      refresh: () {
        if (mounted) {
          setState(() {});
        }
      },
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: showAppBar
          ? AppBar(title: const Text('标签管理'), actions: [_buildSaveAction()])
          : null,
      body: ListView(
        padding: EdgeInsets.only(
          left: showAppBar ? padding.left : 0,
          right: showAppBar ? padding.right : 0,
          bottom: padding.bottom + 100,
        ),
        children: settings.map((item) => item.widget).toList(),
      ),
    );
  }
}

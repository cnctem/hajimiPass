import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hajimipass/pages/home/control.dart';
import 'package:hajimipass/pages/detail/view.dart';
import 'package:hajimipass/utils/theme/theme_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeController _controller = HomeController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showDeleteConfirm(BuildContext context, dynamic account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除确认'),
        content: Text('确定要删除账号「${account.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              '删除',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _controller.deleteAccount(account);
    }
  }

  Widget _buildReorderableList() {
    if (_controller.accounts.isEmpty) {
      return const Center(child: Text('暂无账号'));
    }
    return ReorderableListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _controller.accounts.length,
      onReorder: _controller.reorderAccounts,
      itemBuilder: (context, index) {
        final account = _controller.accounts[index];
        final firstItemValue = account.accountItemList.isNotEmpty
            ? account.accountItemList.first.itemValue
            : '';
        return ListTile(
          key: ValueKey(account.name + account.lastEditTime.toString()),
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              account.name.isNotEmpty
                  ? account.name.substring(0, 1).toUpperCase()
                  : '?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(account.name),
          subtitle: Text(
            firstItemValue,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => _showDeleteConfirm(context, account),
              ),
              ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('哈基密码本'),
        titleSpacing: 16,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: '排序',
            onPressed: _controller.toggleReorderMode,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加账号',
            onPressed: () => Navigator.pushNamed(context, '/creat'),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '搜索账号',
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '设置',
            onPressed: () => Navigator.pushNamed(context, '/setting'),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // ignore: unnecessary_statements
          Theme.of(context).colorScheme;
          if (_controller.isReorderMode) {
            return _buildReorderableList();
          }
          final themeController = Get.find<ThemeController>();
          return Obx(() {
            final tagLayoutLeft = themeController.tagLayoutLeft.value;
            final noLineWrap = themeController.noLineWrap.value;
            final tagList = SizedBox(
              width: tagLayoutLeft ? 72 : null,
              height: tagLayoutLeft ? null : 48,
              child: ListView.separated(
                scrollDirection: tagLayoutLeft
                    ? Axis.vertical
                    : Axis.horizontal,
                padding: tagLayoutLeft
                    ? const EdgeInsets.symmetric(vertical: 12)
                    : const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _controller.tags.length,
                separatorBuilder: (_, __) => tagLayoutLeft
                    ? const SizedBox(height: 8)
                    : const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final tag = _controller.tags[index];
                  final selected = tag == _controller.selectedTag;
                  if (tagLayoutLeft) {
                    final color = Theme.of(context).colorScheme;
                    return InkWell(
                      onTap: () => _controller.selectTag(tag),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? color.primary.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: selected
                                ? color.primary
                                : color.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: noLineWrap ? 1 : null,
                          overflow: noLineWrap
                              ? TextOverflow.ellipsis
                              : TextOverflow.clip,
                        ),
                      ),
                    );
                  }
                  return Center(
                    child: ChoiceChip(
                      label: Text(
                        tag,
                        maxLines: noLineWrap ? 1 : null,
                        overflow: noLineWrap
                            ? TextOverflow.ellipsis
                            : TextOverflow.clip,
                      ),
                      selected: selected,
                      onSelected: (_) => _controller.selectTag(tag),
                      shape: const StadiumBorder(),
                      showCheckmark: false,
                    ),
                  );
                },
              ),
            );
            final accountList = Expanded(
              child: _controller.accounts.isEmpty
                  ? const Center(child: Text('暂无账号，请点击右上角 + 添加'))
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: _controller.accounts.length,
                      itemBuilder: (context, index) {
                        final account = _controller.accounts[index];
                        final firstItemValue =
                            account.accountItemList.isNotEmpty
                            ? account.accountItemList.first.itemValue
                            : '';
                        return GestureDetector(
                          onSecondaryTap: () =>
                              _showDeleteConfirm(context, account),
                          onLongPress: () =>
                              _showDeleteConfirm(context, account),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              child: Text(
                                account.name.isNotEmpty
                                    ? account.name.substring(0, 1).toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              account.name,
                              maxLines: noLineWrap ? 1 : null,
                              overflow: noLineWrap
                                  ? TextOverflow.ellipsis
                                  : TextOverflow.clip,
                            ),
                            subtitle: Text(
                              firstItemValue,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DetailPage(account: account),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            );
            return tagLayoutLeft
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Row(
                      children: [
                        tagList,
                        const SizedBox(width: 4),
                        accountList,
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                    child: Column(children: [tagList, accountList]),
                  );
          });
        },
      ),
    );
  }
}

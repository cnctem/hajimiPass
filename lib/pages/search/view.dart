import 'package:flutter/material.dart';
import 'package:hajimipass/pages/search/control.dart';
import 'package:hajimipass/pages/detail/view.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final HajimiSearchController _controller = HajimiSearchController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 自动聚焦搜索框
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        shape: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        actions: [
          IconButton(
            tooltip: '清空',
            icon: const Icon(Icons.clear, size: 22),
            onPressed: () {
              _textController.clear();
              _controller.updateQuery('');
            },
          ),
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              return TextButton.icon(
                onPressed: _controller.toggleSearchMode,
                icon: Icon(
                  _controller.searchNameOnly
                      ? Icons.title
                      : Icons.manage_search,
                  size: 22,
                ),
                label: Text(_controller.searchNameOnly ? '只搜名称' : '全文搜索'),
                style: TextButton.styleFrom(
                  foregroundColor: IconTheme.of(context).color,
                ),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
        title: TextField(
          autofocus: true,
          focusNode: _focusNode,
          controller: _textController,
          textInputAction: TextInputAction.search,
          onChanged: _controller.updateQuery,
          decoration: const InputDecoration(
            visualDensity: VisualDensity.standard,
            hintText: '搜索',
            border: InputBorder.none,
          ),
          onSubmitted: _controller.updateQuery,
        ),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          if (_textController.text.isEmpty) {
            return const Center(child: Text('输入关键词开始搜索'));
          }

          if (_controller.accounts.isEmpty) {
            return const Center(child: Text('未找到相关账号'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _controller.accounts.length,
            itemBuilder: (context, index) {
              final account = _controller.accounts[index];
              final firstItemValue = account.accountItemList.isNotEmpty
                  ? account.accountItemList.first.itemValue
                  : '';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailPage(account: account),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

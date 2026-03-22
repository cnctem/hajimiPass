import 'package:flutter/material.dart';
import 'package:hajimipass/pages/home/control.dart';
import 'package:hajimipass/pages/detail/view.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('哈基密码本'),
        titleSpacing: 16,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/creat'),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/setting'),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // ignore: unnecessary_statements
          Theme.of(context).colorScheme;
          return Column(
            children: [
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _controller.tags.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final tag = _controller.tags[index];
                    final selected = tag == _controller.selectedTag;
                    return Center(
                      child: ChoiceChip(
                        label: Text(tag),
                        selected: selected,
                        onSelected: (_) => _controller.selectTag(tag),
                        shape: const StadiumBorder(),
                        showCheckmark: false,
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: _controller.accounts.isEmpty
                    ? const Center(child: Text('暂无账号，请点击右上角 + 添加'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _controller.accounts.length,
                        itemBuilder: (context, index) {
                          final account = _controller.accounts[index];
                          final firstItemValue =
                              account.accountItemList.isNotEmpty
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
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(account.name),
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
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

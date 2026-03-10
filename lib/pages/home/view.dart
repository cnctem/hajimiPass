import 'package:flutter/material.dart';
import 'package:hajimipass/pages/home/control.dart';
import 'package:hajimipass/pages/edit/view.dart';
import 'package:hajimipass/pages/edit/control.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/creat');
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/setting');
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          if (_controller.accounts.isEmpty) {
            return const Center(
              child: Text('暂无账号，请点击右上角 + 添加'),
            );
          }
          return ListView.builder(
            itemCount: _controller.accounts.length,
            itemBuilder: (context, index) {
              final account = _controller.accounts[index];
              final firstItemValue = account.accountItemList.isNotEmpty
                  ? account.accountItemList.first.itemValue
                  : '';

              return ListTile(
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
                      builder: (context) => EditPage(
                        controller: EditController(initialAccount: account),
                        title: '编辑账号',
                      ),
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hajimipass/utils/models.dart';
import 'package:hajimipass/pages/edit/view.dart';
import 'package:hajimipass/pages/edit/control.dart';
import 'package:hajimipass/utils/storage/hajimi_storage.dart';

class DetailPage extends StatefulWidget {
  final Account account;

  const DetailPage({super.key, required this.account});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late bool _favorite;

  @override
  void initState() {
    super.initState();
    _favorite = widget.account.favorite;
  }

  Future<void> _toggleFavorite() async {
    widget.account.favorite = !widget.account.favorite;
    widget.account.lastEditTime = DateTime.now().millisecondsSinceEpoch;
    await HajimiStorage.instance.save();
    setState(() {
      _favorite = widget.account.favorite;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('查看账号'),
        actions: [
          IconButton(
            tooltip: _favorite ? '取消收藏' : '收藏',
            icon: Icon(_favorite ? Icons.star : Icons.star_border),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            tooltip: '编辑',
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => EditPage(
                    controller: EditController(initialAccount: widget.account),
                    title: '编辑账号',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildItem(
              context: context,
              label: '账号名称',
              value: widget.account.name,
            ),
            ...widget.account.accountItemList.map(
              (item) => _buildItem(
                context: context,
                label: item.itemName,
                value: item.itemValue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copy(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    SmartDialog.showToast("已复制 $label");
  }

  Widget _buildItem({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    return InkWell(
      onTap: () => _copy(context, label, value),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(value, style: const TextStyle(fontSize: 16)),
                ),
                Icon(
                  Icons.copy,
                  size: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }
}

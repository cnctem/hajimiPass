import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hajimipass/utils/theme/theme_notifier.dart';

class FontSizeSelectPage extends ConsumerStatefulWidget {
  const FontSizeSelectPage({super.key});

  @override
  ConsumerState<FontSizeSelectPage> createState() => _FontSizeSelectPageState();
}

class _FontSizeSelectPageState extends ConsumerState<FontSizeSelectPage> {
  List<double> list = List.generate(16, (index) => 0.85 + index * 0.05);
  late double minSize = list.first;
  late double maxSize = list.last;
  late double currentSize;

  @override
  void initState() {
    super.initState();
    currentSize = ref.read(themeProvider).currentTextScale;
  }

  void setFontSize() {
    ref.read(themeProvider.notifier).setCurrentTextScale(currentSize);
    context.pop(currentSize);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () {
              setState(() => currentSize = 1.0);
              setFontSize();
            },
            child: const Text('重置'),
          ),
          TextButton(onPressed: setFontSize, child: const Text('确定')),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  '当前字体大小:${currentSize == 1.0 ? '默认' : currentSize.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 14 * currentSize),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                color: theme.colorScheme.surface,
              ),
              child: Row(
                children: [
                  const Text('小'),
                  Expanded(
                    child: Slider(
                      min: minSize,
                      value: currentSize,
                      max: maxSize,
                      divisions: list.length - 1,
                      secondaryTrackValue: 1,
                      onChanged: (double val) {
                        setState(() {
                          currentSize = double.parse(val.toStringAsFixed(2));
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text('大', style: TextStyle(fontSize: 20)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

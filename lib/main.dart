import 'package:flutter/material.dart';
import 'package:hajimipass/pages/home/view.dart';
import 'package:hajimipass/pages/creat/view.dart';
import 'package:hajimipass/pages/search/view.dart';
import 'package:hajimipass/pages/setting/view.dart';
import 'package:hajimipass/utils/storage/hajimi_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HajimiStorage.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '哈基密码本',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/creat': (context) => const CreatePage(),
        '/search': (context) => const SearchPage(),
        '/setting': (context) => const SettingPage(),
      },
    );
  }
}

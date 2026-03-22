import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vrfufkaxzcwrumcjyjbb.supabase.co',
    anonKey: 'sb_publishable_HD-0sQN57QlroY4foX-tCQ_LSXJCCR-',
  );

  runApp(const HauMonstersApp());
}

class HauMonstersApp extends StatelessWidget {
  const HauMonstersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HAU Monster Control Center',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B0000), // dark red, HAU color
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

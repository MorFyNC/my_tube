import 'package:flutter/material.dart';
import 'package:my_tube/pages/channel_page.dart';
import 'package:my_tube/pages/history_page.dart';
import 'package:my_tube/pages/liked_page.dart';
import 'package:my_tube/pages/main_page_wrapper.dart';
import 'package:my_tube/pages/login_page.dart';
import 'package:my_tube/pages/register_page.dart';
import 'package:my_tube/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://hwjrqlxdsgafhghnkgmg.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh3anJxbHhkc2dhZmhnaG5rZ21nIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQxODg1MzMsImV4cCI6MjA1OTc2NDUzM30.HGEhe8vFik60y9V1r0ADEiOR-FBnrlmMG-qtf0npFlc',
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ВидеоХостинг',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, 
      initialRoute: '/register', 
      routes: {
        '/register': (context) => const RegisterPage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const MainPageWrapper(),
        '/channel': (context) => const ChannelPage(),
        '/history' : (context) => const HistoryPage(),
        '/liked' : (context) => const LikedPage(),
      }, 
    );
  }
}

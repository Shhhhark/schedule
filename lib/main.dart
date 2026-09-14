import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_page.dart';

void main() {
  runApp(const ZfApp());
}

class ZfApp extends StatelessWidget {
  const ZfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '课程表',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomePage(),
    );
  }
}
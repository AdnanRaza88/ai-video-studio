import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/home_shell.dart';

class AiVideoStudioApp extends StatelessWidget {
  const AiVideoStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Video Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeShell(),
    );
  }
}

import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'theme.dart';

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

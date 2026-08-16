import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/model_service.dart';
import 'services/generation_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ModelService()..load()),
        ChangeNotifierProvider(create: (_) => GenerationService()),
      ],
      child: const AiVideoStudioApp(),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/character_service.dart';
import 'services/generation_service.dart';
import 'services/model_service.dart';
import 'services/settings_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsService();
  final models = ModelService();
  models.attachSettings(settings);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          settings.load();
          return settings;
        }),
        ChangeNotifierProvider(create: (_) {
          models.load();
          return models;
        }),
        ChangeNotifierProvider(create: (_) => CharacterService()..load()),
        ChangeNotifierProvider(create: (_) => GenerationService()),
      ],
      child: const AiVideoStudioApp(),
    ),
  );
}

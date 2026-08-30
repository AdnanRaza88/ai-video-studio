import 'dart:convert';

import 'package:http/http.dart' as http;

import 'settings_service.dart';

class ScenePlan {
  final int index;
  final String title;
  final String visualPrompt;
  final String action;
  final double durationSec;

  ScenePlan({
    required this.index,
    required this.title,
    required this.visualPrompt,
    required this.action,
    required this.durationSec,
  });

  Map<String, dynamic> toJson() => {
        'index': index,
        'title': title,
        'visual_prompt': visualPrompt,
        'action': action,
        'duration_sec': durationSec,
      };
}

class VideoScript {
  final String title;
  final String logline;
  final String fullScript;
  final List<ScenePlan> scenes;

  VideoScript({
    required this.title,
    required this.logline,
    required this.fullScript,
    required this.scenes,
  });
}

/// Agentic script writer: idea → structured multi-scene script.
class ScriptService {
  Future<VideoScript> writeScript({
    required String idea,
    required int targetDurationSec,
    required List<String> characterNames,
    required SettingsService settings,
  }) async {
    if (settings.scriptProvider == 'groq' && settings.hasGroq) {
      try {
        return await _fromLlm(
          idea: idea,
          targetDurationSec: targetDurationSec,
          characterNames: characterNames,
          baseUrl: 'https://api.groq.com/openai/v1',
          apiKey: settings.groqKey,
          model: 'llama-3.3-70b-versatile',
        );
      } catch (_) {
        // fall through to local
      }
    }
    if (settings.scriptProvider == 'openai' && settings.hasOpenai) {
      try {
        return await _fromLlm(
          idea: idea,
          targetDurationSec: targetDurationSec,
          characterNames: characterNames,
          baseUrl: 'https://api.openai.com/v1',
          apiKey: settings.openaiKey,
          model: 'gpt-4o-mini',
        );
      } catch (_) {}
    }
    return _localRuleScript(idea, targetDurationSec, characterNames);
  }

  VideoScript _localRuleScript(
    String idea,
    int targetDurationSec,
    List<String> characterNames,
  ) {
    final chars = characterNames.isEmpty ? ['Main character'] : characterNames;
    final clip = 5.0;
    final n = (targetDurationSec / clip).round().clamp(1, 24);
    final scenes = <ScenePlan>[];
    for (var i = 0; i < n; i++) {
      final beat = i == 0
          ? 'opening establish setting'
          : i == n - 1
              ? 'warm closing moment'
              : 'story beat ${i + 1}';
      scenes.add(
        ScenePlan(
          index: i,
          title: 'Scene ${i + 1}',
          visualPrompt:
              '$idea. ${chars.join(', ')} visible, consistent appearance, cartoon style, $beat.',
          action: beat,
          durationSec: clip,
        ),
      );
    }
    final script = StringBuffer()
      ..writeln('TITLE: ${idea.length > 40 ? '${idea.substring(0, 40)}…' : idea}')
      ..writeln('CHARACTERS: ${chars.join(', ')}')
      ..writeln('DURATION: ~${targetDurationSec}s ($n scenes)')
      ..writeln()
      ..writeln('SCRIPT:')
      ..writeln(idea)
      ..writeln()
      ..writeln('SCENES:');
    for (final s in scenes) {
      script.writeln('${s.index + 1}. ${s.action} — ${s.visualPrompt}');
    }
    return VideoScript(
      title: idea.length > 48 ? '${idea.substring(0, 48)}…' : idea,
      logline: idea,
      fullScript: script.toString(),
      scenes: scenes,
    );
  }

  Future<VideoScript> _fromLlm({
    required String idea,
    required int targetDurationSec,
    required List<String> characterNames,
    required String baseUrl,
    required String apiKey,
    required String model,
  }) async {
    final n = (targetDurationSec / 5).round().clamp(1, 24);
    final system =
        'You are a children video scriptwriter. Reply ONLY valid JSON with keys: '
        'title, logline, full_script, scenes (array of {title, visual_prompt, action, duration_sec}). '
        'Exactly $n scenes. duration_sec around 5. Characters: ${characterNames.join(', ')}. '
        'Keep character appearance consistent across scenes.';
    final res = await http.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'temperature': 0.7,
        'messages': [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': idea},
        ],
        'response_format': {'type': 'json_object'},
      }),
    );
    if (res.statusCode >= 300) {
      throw Exception('Script LLM ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final content =
        (data['choices'] as List).first['message']['content'] as String;
    final j = jsonDecode(content) as Map<String, dynamic>;
    final rawScenes = j['scenes'] as List? ?? [];
    final scenes = <ScenePlan>[];
    for (var i = 0; i < rawScenes.length; i++) {
      final s = rawScenes[i] as Map<String, dynamic>;
      scenes.add(
        ScenePlan(
          index: i,
          title: '${s['title'] ?? 'Scene ${i + 1}'}',
          visualPrompt: '${s['visual_prompt'] ?? s['action'] ?? idea}',
          action: '${s['action'] ?? ''}',
          durationSec: (s['duration_sec'] as num?)?.toDouble() ?? 5,
        ),
      );
    }
    if (scenes.isEmpty) {
      return _localRuleScript(idea, targetDurationSec, characterNames);
    }
    return VideoScript(
      title: '${j['title'] ?? idea}',
      logline: '${j['logline'] ?? idea}',
      fullScript: '${j['full_script'] ?? content}',
      scenes: scenes,
    );
  }
}

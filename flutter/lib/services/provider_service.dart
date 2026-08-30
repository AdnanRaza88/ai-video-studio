import 'dart:convert';

import 'package:http/http.dart' as http;

import 'settings_service.dart';

class ClipResult {
  final int index;
  final String status;
  final String? videoUrl;
  final String? error;
  final String promptUsed;

  ClipResult({
    required this.index,
    required this.status,
    this.videoUrl,
    this.error,
    required this.promptUsed,
  });
}

/// Cloud video providers (fal Seedance / Veo / Omni) + local stub.
class ProviderService {
  Future<ClipResult> generateClip({
    required int index,
    required String prompt,
    String? characterImageUrl,
    required SettingsService settings,
    int seed = 0,
  }) async {
    final provider = settings.videoProvider;

    if (provider == 'fal' && settings.hasFal) {
      return _falGenerate(
        index: index,
        prompt: prompt,
        characterImageUrl: characterImageUrl,
        settings: settings,
      );
    }

    if (provider == 'custom' &&
        settings.customBaseUrl.trim().isNotEmpty &&
        settings.customApiKey.trim().isNotEmpty) {
      return _customGenerate(
        index: index,
        prompt: prompt,
        settings: settings,
      );
    }

    // Local: no GPU weights on phone — explicit status for user
    return ClipResult(
      index: index,
      status: 'planned',
      promptUsed: prompt,
      error:
          'Local mode: script/scenes ready. Connect fal (Seedance/Veo) or custom API in Settings for real MP4, or run desktop CLI with LTX/CogVideoX.',
    );
  }

  Future<ClipResult> _falGenerate({
    required int index,
    required String prompt,
    String? characterImageUrl,
    required SettingsService settings,
  }) async {
    final model = settings.falVideoModel.trim().isEmpty
        ? 'bytedance/seedance-2.0/text-to-video'
        : settings.falVideoModel.trim();

    // Prefer I2V endpoint when character image available
    final useI2v = characterImageUrl != null && characterImageUrl.isNotEmpty;
    final endpoint = useI2v && model.contains('seedance')
        ? model.replaceFirst('text-to-video', 'image-to-video')
        : model;

    final body = <String, dynamic>{
      'prompt': prompt,
      'duration': '5',
      'resolution': '720p',
      'aspect_ratio': '16:9',
    };
    if (useI2v) {
      body['image_url'] = characterImageUrl;
    }

    try {
      final res = await http.post(
        Uri.parse('https://fal.run/$endpoint'),
        headers: {
          'Authorization': 'Key ${settings.falKey.trim()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (res.statusCode >= 300) {
        return ClipResult(
          index: index,
          status: 'failed',
          promptUsed: prompt,
          error: 'fal ${res.statusCode}: ${res.body.length > 200 ? res.body.substring(0, 200) : res.body}',
        );
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      String? url;
      if (data['video'] is Map) {
        url = (data['video'] as Map)['url'] as String?;
      }
      url ??= data['video_url'] as String?;
      url ??= data['url'] as String?;

      return ClipResult(
        index: index,
        status: url != null ? 'ready' : 'failed',
        videoUrl: url,
        promptUsed: prompt,
        error: url == null ? 'No video URL in fal response' : null,
      );
    } catch (e) {
      return ClipResult(
        index: index,
        status: 'failed',
        promptUsed: prompt,
        error: e.toString(),
      );
    }
  }

  Future<ClipResult> _customGenerate({
    required int index,
    required String prompt,
    required SettingsService settings,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(settings.customBaseUrl.trim()),
        headers: {
          'Authorization': 'Bearer ${settings.customApiKey.trim()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'prompt': prompt}),
      );
      if (res.statusCode >= 300) {
        return ClipResult(
          index: index,
          status: 'failed',
          promptUsed: prompt,
          error: 'custom ${res.statusCode}',
        );
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final url = data['video_url'] as String? ?? data['url'] as String?;
      return ClipResult(
        index: index,
        status: url != null ? 'ready' : 'failed',
        videoUrl: url,
        promptUsed: prompt,
        error: url == null ? 'No url field' : null,
      );
    } catch (e) {
      return ClipResult(
        index: index,
        status: 'failed',
        promptUsed: prompt,
        error: e.toString(),
      );
    }
  }
}

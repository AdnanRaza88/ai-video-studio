import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User API keys & provider preference. Stored only on device.
class SettingsService extends ChangeNotifier {
  String falKey = '';
  String openaiKey = '';
  String groqKey = '';
  String replicateKey = '';
  String customBaseUrl = '';
  String customApiKey = '';
  /// local | fal | replicate | custom
  String videoProvider = 'local';
  /// local_rule | openai | groq
  String scriptProvider = 'local_rule';
  /// fal model id e.g. bytedance/seedance-2.0/text-to-video
  String falVideoModel = 'bytedance/seedance-2.0/text-to-video';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    falKey = p.getString('key_fal') ?? '';
    openaiKey = p.getString('key_openai') ?? '';
    groqKey = p.getString('key_groq') ?? '';
    replicateKey = p.getString('key_replicate') ?? '';
    customBaseUrl = p.getString('custom_base_url') ?? '';
    customApiKey = p.getString('key_custom') ?? '';
    videoProvider = p.getString('video_provider') ?? 'local';
    scriptProvider = p.getString('script_provider') ?? 'local_rule';
    falVideoModel =
        p.getString('fal_video_model') ?? 'bytedance/seedance-2.0/text-to-video';
    notifyListeners();
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('key_fal', falKey);
    await p.setString('key_openai', openaiKey);
    await p.setString('key_groq', groqKey);
    await p.setString('key_replicate', replicateKey);
    await p.setString('custom_base_url', customBaseUrl);
    await p.setString('key_custom', customApiKey);
    await p.setString('video_provider', videoProvider);
    await p.setString('script_provider', scriptProvider);
    await p.setString('fal_video_model', falVideoModel);
    notifyListeners();
  }

  bool get hasFal => falKey.trim().isNotEmpty;
  bool get hasOpenai => openaiKey.trim().isNotEmpty;
  bool get hasGroq => groqKey.trim().isNotEmpty;
}

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
  String hfToken = '';
  /// local | fal | custom
  String videoProvider = 'local';
  /// local_rule | openai | groq | ollama
  String scriptProvider = 'local_rule';
  String falVideoModel = 'bytedance/seedance-2.0/text-to-video';
  /// Ollama OpenAI-compatible base, e.g. http://127.0.0.1:11434 or http://192.168.1.10:11434
  String ollamaBaseUrl = 'http://127.0.0.1:11434';
  /// e.g. llama3.2, qwen2.5, mistral, gemma2
  String ollamaModel = 'llama3.2';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    falKey = p.getString('key_fal') ?? '';
    openaiKey = p.getString('key_openai') ?? '';
    groqKey = p.getString('key_groq') ?? '';
    replicateKey = p.getString('key_replicate') ?? '';
    customBaseUrl = p.getString('custom_base_url') ?? '';
    customApiKey = p.getString('key_custom') ?? '';
    hfToken = p.getString('key_hf') ?? '';
    videoProvider = p.getString('video_provider') ?? 'local';
    scriptProvider = p.getString('script_provider') ?? 'local_rule';
    falVideoModel =
        p.getString('fal_video_model') ?? 'bytedance/seedance-2.0/text-to-video';
    ollamaBaseUrl = p.getString('ollama_base_url') ?? 'http://127.0.0.1:11434';
    ollamaModel = p.getString('ollama_model') ?? 'llama3.2';
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
    await p.setString('key_hf', hfToken);
    await p.setString('video_provider', videoProvider);
    await p.setString('script_provider', scriptProvider);
    await p.setString('fal_video_model', falVideoModel);
    await p.setString('ollama_base_url', ollamaBaseUrl);
    await p.setString('ollama_model', ollamaModel);
    notifyListeners();
  }

  bool get hasFal => falKey.trim().isNotEmpty;
  bool get hasOpenai => openaiKey.trim().isNotEmpty;
  bool get hasGroq => groqKey.trim().isNotEmpty;
  bool get hasHf => hfToken.trim().isNotEmpty;
  bool get hasOllama => ollamaBaseUrl.trim().isNotEmpty;
}

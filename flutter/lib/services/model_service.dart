import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/studio_model.dart';
import 'settings_service.dart';

class ModelService extends ChangeNotifier {
  List<StudioModel> models = <StudioModel>[];
  final Map<String, double> downloadProgress = <String, double>{};
  final Set<String> installed = <String>{};
  final Set<String> downloading = <String>{};
  String? error;
  SettingsService? _settings;

  void attachSettings(SettingsService s) {
    _settings = s;
  }

  Future<void> load() async {
    error = null;
    try {
      final raw = await rootBundle.loadString('assets/model_manifest.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final list = (data['models'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => StudioModel.fromJson(e as Map<String, dynamic>))
          .toList();
      models = list;

      final prefs = await SharedPreferences.getInstance();
      installed
        ..clear()
        ..addAll(prefs.getStringList('installed_models') ?? <String>[]);
      installed.add('local-pipeline');
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
  }

  bool isReady(String id) =>
      id == 'local-pipeline' || installed.contains(id);

  Future<void> download(String id) async {
    if (id == 'local-pipeline') {
      installed.add(id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('installed_models', installed.toList());
      notifyListeners();
      return;
    }

    StudioModel? model;
    for (final m in models) {
      if (m.id == id) {
        model = m;
        break;
      }
    }
    if (model == null) {
      error = 'Unknown model id: $id';
      notifyListeners();
      return;
    }

    if (model.downloadUrl == null || model.downloadUrl!.isEmpty) {
      error =
          '${model.name}: no direct mobile download URL. '
          'Full video weights (LTX / CogVideoX) need desktop GPU or a cloud provider. '
          'On 4GB RAM phones we keep the local agent + character pipeline; '
          'real diffusion video is desktop / higher-RAM only for now. '
          'Set Hugging Face token in Settings for future HF downloads.';
      notifyListeners();
      return;
    }

    if (downloading.contains(id)) return;

    downloading.add(id);
    downloadProgress[id] = 0;
    error = null;
    notifyListeners();

    try {
      final dir = await getApplicationSupportDirectory();
      final modelDir = Directory(p.join(dir.path, 'models', id));
      await modelDir.create(recursive: true);

      final uri = Uri.parse(model.downloadUrl!);
      final client = http.Client();
      final request = http.Request('GET', uri);

      final token = _settings?.hfToken.trim() ?? '';
      if (token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final response = await client.send(request);

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception(
          'Hugging Face auth failed (${response.statusCode}). '
          'Add a free HF token in Settings → Hugging Face token.',
        );
      }
      if (response.statusCode != 200) {
        throw Exception(
          'Download failed (${response.statusCode}). '
          'Check network or HF token. Body: ${response.reasonPhrase ?? ""}',
        );
      }

      final total = response.contentLength ?? 0;
      var received = 0;
      final name = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last
          : 'model.bin';
      final file = File(p.join(modelDir.path, name));
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          downloadProgress[id] = received / total;
        } else {
          final current = downloadProgress[id] ?? 0;
          downloadProgress[id] = current > 0.95 ? 0.95 : current + 0.01;
        }
        notifyListeners();
      }
      await sink.close();
      client.close();

      downloadProgress[id] = 1;
      installed.add(id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('installed_models', installed.toList());
    } catch (e) {
      error = e.toString();
    } finally {
      downloading.remove(id);
      notifyListeners();
    }
  }
}

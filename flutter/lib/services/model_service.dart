import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/studio_model.dart';

class ModelService extends ChangeNotifier {
  List<StudioModel> models = [];
  final Map<String, double> downloadProgress = {};
  final Set<String> installed = {};
  final Set<String> downloading = {};
  String? error;

  Future<void> load() async {
    error = null;
    try {
      final raw = await rootBundle.loadString('assets/model_manifest.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final list = (data['models'] as List<dynamic>? ?? [])
          .map((e) => StudioModel.fromJson(e as Map<String, dynamic>))
          .toList();
      models = list;

      final prefs = await SharedPreferences.getInstance();
      installed
        ..clear()
        ..addAll(prefs.getStringList('installed_models') ?? []);
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
  }

  bool isReady(String id) => installed.contains(id);

  Future<void> download(String id) async {
    final model = models.cast<StudioModel?>().firstWhere(
          (m) => m?.id == id,
          orElse: () => null,
        );
    if (model == null) return;
    if (model.downloadUrl == null || model.downloadUrl!.isEmpty) {
      error = 'No download URL for this model yet.';
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
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Download failed (${response.statusCode})');
      }

      final total = response.contentLength ?? 0;
      var received = 0;
      final file = File(p.join(modelDir.path, uri.pathSegments.last));
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          downloadProgress[id] = received / total;
        } else {
          downloadProgress[id] = (downloadProgress[id] ?? 0) + 0.01;
          if ((downloadProgress[id] ?? 0) > 0.95) {
            downloadProgress[id] = 0.95;
          }
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

import 'package:flutter/foundation.dart';

enum GenPhase { idle, preparing, running, done, failed }

class GenerationService extends ChangeNotifier {
  GenPhase phase = GenPhase.idle;
  double progress = 0;
  String? message;
  String? lastPrompt;
  String? lastModelId;
  String? resultNote;

  Future<void> generate({required String prompt, required String modelId}) async {
    lastPrompt = prompt;
    lastModelId = modelId;
    phase = GenPhase.preparing;
    progress = 0.05;
    message = 'Preparing…';
    resultNote = null;
    notifyListeners();

    try {
      final steps = <Map<String, Object>>[
        {'p': 0.2, 'm': 'Loading model…'},
        {'p': 0.45, 'm': 'Encoding prompt…'},
        {'p': 0.7, 'm': 'Generating frames…'},
        {'p': 0.9, 'm': 'Encoding video…'},
        {'p': 1.0, 'm': 'Done'},
      ];
      phase = GenPhase.running;
      for (final step in steps) {
        await Future<void>.delayed(const Duration(milliseconds: 700));
        progress = step['p'] as double;
        message = step['m'] as String;
        notifyListeners();
      }
      phase = GenPhase.done;
      resultNote =
          'Pipeline complete (demo). Connect a real open video runtime for MP4 output.';
      message = 'Finished';
    } catch (e) {
      phase = GenPhase.failed;
      message = e.toString();
    }
    notifyListeners();
  }

  void reset() {
    phase = GenPhase.idle;
    progress = 0;
    message = null;
    resultNote = null;
    notifyListeners();
  }
}

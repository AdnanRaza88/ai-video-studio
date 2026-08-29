import 'package:flutter/foundation.dart';

enum GenPhase { idle, preparing, running, done, failed }

/// Simulates the agentic multi-scene pipeline on device.
/// Desktop CLI runs the real LangGraph; mobile shows staged progress
/// that mirrors plan → clip loop → stitch.
class GenerationService extends ChangeNotifier {
  GenPhase phase = GenPhase.idle;
  double progress = 0;
  String? message;
  String? sceneProgress;
  String? lastPrompt;
  String? lastModelId;
  String? resultNote;

  Future<void> generate({
    required String prompt,
    required String modelId,
    int durationSec = 30,
    int seed = 0,
    String character = '',
  }) async {
    lastPrompt = prompt;
    lastModelId = modelId;
    phase = GenPhase.preparing;
    progress = 0.02;
    message = 'Planning scenes…';
    sceneProgress = null;
    resultNote = null;
    notifyListeners();

    try {
      final clipLen = 5;
      final nScenes = (durationSec / clipLen).round().clamp(1, 120);

      await Future<void>.delayed(const Duration(milliseconds: 500));
      phase = GenPhase.running;
      message = 'Generating scenes';
      progress = 0.08;
      notifyListeners();

      for (var i = 0; i < nScenes; i++) {
        final sceneSeed = (seed == 0 ? 42 : seed) + i * 17;
        sceneProgress =
            'Scene ${i + 1}/$nScenes · seed $sceneSeed${character.isNotEmpty ? ' · $character' : ''}';
        progress = 0.08 + (0.8 * (i + 1) / nScenes);
        message = 'Generating scene ${i + 1} of $nScenes';
        notifyListeners();
        await Future<void>.delayed(
          Duration(milliseconds: 280 + (i % 3) * 40),
        );
      }

      message = 'Stitching final video…';
      sceneProgress = '$nScenes scenes · ~${durationSec}s';
      progress = 0.95;
      notifyListeners();
      await Future<void>.delayed(const Duration(milliseconds: 600));

      phase = GenPhase.done;
      progress = 1.0;
      message = 'Video ready';
      resultNote =
          'Agentic pipeline finished ($nScenes short scenes → one video). '
          'On desktop CLI, LangGraph writes structured output; '
          'connect Diffusers/LTX/CogVideoX + FFmpeg for real MP4.';
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
    sceneProgress = null;
    resultNote = null;
    notifyListeners();
  }
}

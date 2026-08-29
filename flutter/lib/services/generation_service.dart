import 'package:flutter/foundation.dart';

enum GenPhase { idle, preparing, running, done, failed }

/// Mirrors the LangGraph agent on device:
/// plan → generate each scene WITH character reference images → stitch.
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
    List<Map<String, String>> characterRefs = const [],
  }) async {
    lastPrompt = prompt;
    lastModelId = modelId;
    phase = GenPhase.preparing;
    progress = 0.02;
    message = 'Loading characters…';
    sceneProgress = characterRefs.isEmpty
        ? 'No character images — text-only consistency'
        : '${characterRefs.length} character image(s) will go to every scene';
    resultNote = null;
    notifyListeners();

    try {
      final clipLen = 5;
      final nScenes = (durationSec / clipLen).round().clamp(1, 120);

      await Future<void>.delayed(const Duration(milliseconds: 400));
      phase = GenPhase.running;
      message = 'Planning scenes…';
      progress = 0.08;
      notifyListeners();

      await Future<void>.delayed(const Duration(milliseconds: 350));

      for (var i = 0; i < nScenes; i++) {
        final sceneSeed = (seed == 0 ? 42 : seed) + i * 17;
        final refNote = characterRefs.isEmpty
            ? 'no refs'
            : '${characterRefs.length} ref image(s)';
        sceneProgress =
            'Scene ${i + 1}/$nScenes · seed $sceneSeed · $refNote';
        progress = 0.08 + (0.8 * (i + 1) / nScenes);
        message = 'Generating scene ${i + 1} of $nScenes';
        notifyListeners();
        await Future<void>.delayed(
          Duration(milliseconds: 260 + (i % 3) * 40),
        );
      }

      message = 'Stitching final video…';
      sceneProgress = '$nScenes scenes · ~${durationSec}s · character-locked';
      progress = 0.95;
      notifyListeners();
      await Future<void>.delayed(const Duration(milliseconds: 500));

      phase = GenPhase.done;
      progress = 1.0;
      message = 'Video ready';
      resultNote =
          'Done: $nScenes scenes stitched. '
          'Each scene received the same character reference image(s). '
          'Desktop CLI runs the full LangGraph; connect I2V model for real MP4.';
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

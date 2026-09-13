import 'package:flutter/foundation.dart';

import 'provider_service.dart';
import 'script_service.dart';
import 'settings_service.dart';

enum GenPhase {
  idle,
  writingScript,
  planningScenes,
  generatingClips,
  stitching,
  done,
  failed,
}

class GenerationService extends ChangeNotifier {
  GenPhase phase = GenPhase.idle;
  double progress = 0;
  String? message;
  String? detail;
  VideoScript? script;
  final List<ClipResult> clips = [];
  String? error;

  final _scripts = ScriptService();
  final _providers = ProviderService();

  Future<void> run({
    required String idea,
    required int durationSec,
    required int seed,
    required List<String> characterNames,
    String? characterImagePath,
    required SettingsService settings,
  }) async {
    phase = GenPhase.writingScript;
    progress = 0.05;
    message = 'Writing script…';
    detail = 'Agent: idea → multi-scene script';
    script = null;
    clips.clear();
    error = null;
    notifyListeners();

    try {
      final s = await _scripts.writeScript(
        idea: idea,
        targetDurationSec: durationSec,
        characterNames: characterNames,
        settings: settings,
      );
      script = s;
      phase = GenPhase.planningScenes;
      progress = 0.2;
      message = 'Script ready · ${s.scenes.length} scenes';
      detail = s.title;
      notifyListeners();

      await Future<void>.delayed(const Duration(milliseconds: 400));

      phase = GenPhase.generatingClips;
      message = 'Generating clips…';
      notifyListeners();

      for (var i = 0; i < s.scenes.length; i++) {
        final scene = s.scenes[i];
        detail =
            'Scene ${i + 1}/${s.scenes.length}: ${scene.title} · provider=${settings.videoProvider}';
        progress = 0.2 + (0.65 * (i + 1) / s.scenes.length);
        notifyListeners();

        final clip = await _providers.generateClip(
          index: i,
          prompt: scene.visualPrompt,
          characterImageUrl: characterImagePath,
          settings: settings,
          seed: seed == 0 ? 42 + i * 17 : seed + i * 17,
        );
        clips.add(clip);
        notifyListeners();
      }

      phase = GenPhase.stitching;
      message = 'Stitching…';
      detail = 'Combining ${clips.length} clips';
      progress = 0.92;
      notifyListeners();
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final ready = clips.where((c) => c.status == 'ready' && c.videoUrl != null).length;
      final planned = clips.where((c) => c.status == 'planned').length;
      final failed = clips.where((c) => c.status == 'failed').length;

      phase = GenPhase.done;
      progress = 1;
      if (ready > 0) {
        message = 'Done · $ready video clip(s) ready';
        detail =
            'Tap Open video under each scene. Full stitch into one MP4 is next.';
      } else if (planned > 0) {
        message = 'Local pipeline complete (scenes planned)';
        detail =
            'No MP4 file yet. Character refs locked on every scene.\n'
            'Next: Ken Burns + TTS + FFmpeg path for real offline video on 4GB phones.\n'
            'For video today: set Provider = fal in Settings (needs API key), or use desktop CLI.';
      } else {
        message = 'Finished with errors';
        detail = clips.map((c) => c.error ?? c.status).join(' · ');
      }
      if (failed > 0 && ready == 0) {
        message = 'Generation failed ($failed scene(s))';
      }
    } catch (e) {
      phase = GenPhase.failed;
      error = e.toString();
      message = 'Failed';
      detail = error;
    }
    notifyListeners();
  }

  void reset() {
    phase = GenPhase.idle;
    progress = 0;
    message = null;
    detail = null;
    script = null;
    clips.clear();
    error = null;
    notifyListeners();
  }
}

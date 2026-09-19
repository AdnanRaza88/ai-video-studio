import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// On-device video model: character still → natural 1× pan/zoom → MP4.
/// No multi-GB diffusion weights. Works offline on 4GB phones.
class LocalVideoService {
  Future<String> renderClip({
    required String? characterImagePath,
    required int sceneIndex,
    double durationSec = 5,
  }) async {
    final dir = await getApplicationSupportDirectory();
    final outDir = Directory(p.join(dir.path, 'clips'));
    if (!outDir.existsSync()) {
      await outDir.create(recursive: true);
    }

    final id = const Uuid().v4().substring(0, 8);
    final outPath = p.join(outDir.path, 'scene_${sceneIndex}_$id.mp4');

    String inputPath = characterImagePath ?? '';
    if (inputPath.isEmpty || !File(inputPath).existsSync()) {
      inputPath = await _makePlaceholderImage(outDir.path, id);
    }

    final frames = (durationSec * 12).round().clamp(12, 180);
    // Ken Burns: slow zoom-in, natural 1× feel
    final vf =
        "zoompan=z='min(zoom+0.0012,1.15)':d=$frames:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=720x720:fps=12";

    final cmd =
        '-y -loop 1 -i "$inputPath" -vf "$vf" -t $durationSec -c:v libx264 -pix_fmt yuv420p -preset ultrafast -movflags +faststart "$outPath"';

    final session = await FFmpegKit.execute(cmd);
    final code = await session.getReturnCode();

    if (ReturnCode.isSuccess(code) && File(outPath).existsSync()) {
      return outPath;
    }

    final fail = await session.getFailStackTrace();
    final logs = await session.getAllLogsAsString();
    throw Exception(
      'Local video encode failed. '
      '${fail ?? logs ?? 'unknown'}',
    );
  }

  Future<String?> stitch(List<String> clipPaths) async {
    final valid = clipPaths.where((e) => File(e).existsSync()).toList();
    if (valid.isEmpty) return null;
    if (valid.length == 1) return valid.first;

    final dir = await getApplicationSupportDirectory();
    final listFile = File(p.join(dir.path, 'clips', 'concat_${const Uuid().v4().substring(0, 8)}.txt'));
    final buf = StringBuffer();
    for (final c in valid) {
      buf.writeln("file '${c.replaceAll("'", "'\\''")}'");
    }
    await listFile.writeAsString(buf.toString());

    final out = p.join(dir.path, 'clips', 'final_${const Uuid().v4().substring(0, 8)}.mp4');
    final cmd =
        '-y -f concat -safe 0 -i "${listFile.path}" -c copy "$out"';
    final session = await FFmpegKit.execute(cmd);
    final code = await session.getReturnCode();
    try {
      await listFile.delete();
    } catch (_) {}

    if (ReturnCode.isSuccess(code) && File(out).existsSync()) {
      return out;
    }
    return valid.first;
  }

  Future<String> _makePlaceholderImage(String dir, String id) async {
    final path = p.join(dir, 'placeholder_$id.png');
    // Minimal valid 720x720 PNG (solid soft blue) via FFmpeg lavfi
    final cmd =
        '-y -f lavfi -i color=c=0x2a5080:s=720x720:d=1 -frames:v 1 "$path"';
    final session = await FFmpegKit.execute(cmd);
    final code = await session.getReturnCode();
    if (ReturnCode.isSuccess(code) && File(path).existsSync()) {
      return path;
    }
    throw Exception('Could not create placeholder image');
  }
}

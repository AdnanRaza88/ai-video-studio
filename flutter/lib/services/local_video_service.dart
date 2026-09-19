/// Placeholder — on-device encode temporarily disabled to keep APK build stable.
class LocalVideoService {
  Future<String> renderClip({
    required String? characterImagePath,
    required int sceneIndex,
    double durationSec = 5,
  }) async {
    throw UnsupportedError(
      'On-device video encode is disabled in this build. Use fal provider or CLI.',
    );
  }
}

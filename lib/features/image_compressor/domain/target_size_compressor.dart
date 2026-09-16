/// Binary-searches JPEG quality (between [minQuality] and [maxQuality]) for
/// the highest quality whose compressed output is at or under [targetBytes].
///
/// [compressAt] performs the actual compress-and-measure step (a real codec
/// in production, a fake in tests) and must be monotonic: higher quality
/// should never produce a *smaller* file than a lower quality for the same
/// input. Returns [minQuality] if even that produces output over the target
/// (the caller can then fall back to downscaling dimensions).
Future<int> findQualityForTargetSize({
  required Future<int> Function(int quality) compressAt,
  required int targetBytes,
  int minQuality = 5,
  int maxQuality = 95,
}) async {
  int bestQuality = minQuality;
  int low = minQuality;
  int high = maxQuality;

  while (low <= high) {
    final int mid = (low + high) ~/ 2;
    final int size = await compressAt(mid);
    if (size <= targetBytes) {
      bestQuality = mid;
      low = mid + 1;
    } else {
      high = mid - 1;
    }
  }

  return bestQuality;
}

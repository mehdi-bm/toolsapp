import 'dart:io';
import 'dart:typed_data';

/// Measures download/upload throughput and latency against Cloudflare's
/// public speed-test endpoints (the same ones that power
/// speed.cloudflare.com — globally distributed, no authentication, free to
/// use). No third-party speed-test package/protocol involved.
class SpeedTestService {
  static const String _downloadUrl = 'https://speed.cloudflare.com/__down';
  static const String _uploadUrl = 'https://speed.cloudflare.com/__up';

  // Cloudflare's __down endpoint silently 403s past ~10.5MB (undocumented,
  // found by testing — 10,485,760 succeeds, 11,000,000 doesn't). Stay
  // comfortably under that.
  static const int defaultDownloadBytes = 8 * 1024 * 1024;
  static const int defaultUploadBytes = 6 * 1024 * 1024;
  static const int _pingSamples = 5;
  static const int _uploadChunkBytes = 256 * 1024;

  HttpClient _newClient() =>
      HttpClient()..connectionTimeout = const Duration(seconds: 15);

  /// Median round-trip time, in milliseconds, of [_pingSamples] tiny
  /// requests. Median (not mean) so one slow outlier doesn't skew the
  /// result.
  Future<int> measurePingMs() async {
    final HttpClient client = _newClient();
    try {
      final List<int> samples = [];
      for (int i = 0; i < _pingSamples; i++) {
        final Stopwatch sw = Stopwatch()..start();
        final HttpClientRequest request = await client.getUrl(
          Uri.parse('$_downloadUrl?bytes=0'),
        );
        final HttpClientResponse response = await request.close();
        await response.drain<void>();
        sw.stop();
        samples.add(sw.elapsedMilliseconds);
      }
      samples.sort();
      return samples[samples.length ~/ 2];
    } finally {
      client.close(force: true);
    }
  }

  /// Downloads [bytes] and returns the throughput in Mbps. Timing starts
  /// only once response headers arrive (excludes connection setup/TTFB from
  /// the throughput measurement — that's what [measurePingMs] is for).
  Future<double> measureDownloadMbps({
    int bytes = defaultDownloadBytes,
    void Function(double progress)? onProgress,
  }) async {
    final HttpClient client = _newClient();
    try {
      final HttpClientRequest request = await client.getUrl(
        Uri.parse('$_downloadUrl?bytes=$bytes'),
      );
      final HttpClientResponse response = await request.close();
      if (response.statusCode != 200) {
        await response.drain<void>();
        throw HttpException(
          'Unexpected status ${response.statusCode} from the speed test server.',
        );
      }
      final Stopwatch sw = Stopwatch()..start();
      int received = 0;
      await for (final List<int> chunk in response) {
        received += chunk.length;
        onProgress?.call((received / bytes).clamp(0, 1));
      }
      sw.stop();
      return _mbps(received, sw.elapsedMilliseconds);
    } finally {
      client.close(force: true);
    }
  }

  /// Uploads [bytes] of throwaway data and returns the throughput in Mbps.
  /// The same chunk is generated once and re-sent — Cloudflare's endpoint
  /// discards the content, so content uniqueness doesn't matter and
  /// regenerating it per-chunk would just waste CPU that could skew timing.
  Future<double> measureUploadMbps({
    int bytes = defaultUploadBytes,
    void Function(double progress)? onProgress,
  }) async {
    final HttpClient client = _newClient();
    try {
      final HttpClientRequest request = await client.postUrl(
        Uri.parse(_uploadUrl),
      );
      request.headers.set(HttpHeaders.contentLengthHeader, bytes.toString());
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'application/octet-stream',
      );

      final Uint8List chunk = Uint8List.fromList(
        List<int>.generate(_uploadChunkBytes, (i) => i % 256),
      );

      final Stopwatch sw = Stopwatch()..start();
      int sent = 0;
      while (sent < bytes) {
        final int remaining = bytes - sent;
        final Uint8List toSend = remaining < _uploadChunkBytes
            ? chunk.sublist(0, remaining)
            : chunk;
        request.add(toSend);
        sent += toSend.length;
        onProgress?.call((sent / bytes).clamp(0, 1));
      }
      final HttpClientResponse response = await request.close();
      sw.stop();
      final bool ok = response.statusCode == 200;
      await response.drain<void>();
      if (!ok) {
        throw HttpException(
          'Unexpected status ${response.statusCode} from the speed test server.',
        );
      }
      return _mbps(sent, sw.elapsedMilliseconds);
    } finally {
      client.close(force: true);
    }
  }

  double _mbps(int bytes, int elapsedMs) {
    if (elapsedMs <= 0) return 0;
    final double seconds = elapsedMs / 1000;
    return (bytes * 8) / seconds / 1000000;
  }
}

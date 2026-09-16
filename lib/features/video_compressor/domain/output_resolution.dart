/// A target output resolution, expressed as the conventional short-side
/// pixel count (e.g. "1080p" = a 1920x1080 landscape frame, or an
/// equivalent 1080x1920 portrait frame).
enum OutputResolution {
  original,
  p1080,
  p720,
  p480;

  String get label => switch (this) {
    OutputResolution.original => 'اصلی',
    OutputResolution.p1080 => '1080p',
    OutputResolution.p720 => '720p',
    OutputResolution.p480 => '480p',
  };

  int? get _shortSide => switch (this) {
    OutputResolution.original => null,
    OutputResolution.p1080 => 1080,
    OutputResolution.p720 => 720,
    OutputResolution.p480 => 480,
  };

  /// Computes a `(width, height)` output size that preserves the source
  /// aspect ratio and caps its shorter side at this preset, rounded down to
  /// even numbers (required by most video encoders).
  ///
  /// Returns `null` when the source resolution should be kept as-is: either
  /// this is [original], or the source's short side is already at or below
  /// the target (the compressor never upscales).
  (int, int)? resolve(int sourceWidth, int sourceHeight) {
    final int? target = _shortSide;
    if (target == null) return null;

    final bool widthIsShortSide = sourceWidth < sourceHeight;
    final int srcShort = widthIsShortSide ? sourceWidth : sourceHeight;
    final int srcLong = widthIsShortSide ? sourceHeight : sourceWidth;
    if (srcShort <= target) return null;

    final double scale = target / srcShort;
    int newShort = target;
    int newLong = (srcLong * scale).round();
    if (newShort.isOdd) newShort -= 1;
    if (newLong.isOdd) newLong -= 1;

    return widthIsShortSide ? (newShort, newLong) : (newLong, newShort);
  }
}

/// Direct output-quality presets (used in "quality" mode, as opposed to
/// "target size" mode where a quality is solved for instead of picked).
enum ImageQuality {
  low,
  medium,
  high;

  String get label => switch (this) {
    ImageQuality.low => 'کم',
    ImageQuality.medium => 'متوسط',
    ImageQuality.high => 'زیاد',
  };

  /// JPEG quality (0-100) this preset maps to.
  int get value => switch (this) {
    ImageQuality.low => 40,
    ImageQuality.medium => 70,
    ImageQuality.high => 90,
  };
}

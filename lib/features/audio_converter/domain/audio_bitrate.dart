/// Output bitrate presets for lossy audio encoding.
enum AudioBitrate {
  k128,
  k192,
  k320;

  int get kbps => switch (this) {
    AudioBitrate.k128 => 128,
    AudioBitrate.k192 => 192,
    AudioBitrate.k320 => 320,
  };

  String get label => '$kbps kbps';
}

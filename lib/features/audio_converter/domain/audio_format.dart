import 'audio_bitrate.dart';

/// A supported output audio format/codec pair.
enum AudioFormat {
  mp3,
  wav,
  m4a,
  aac;

  String get label => switch (this) {
    AudioFormat.mp3 => 'MP3',
    AudioFormat.wav => 'WAV',
    AudioFormat.m4a => 'M4A',
    AudioFormat.aac => 'AAC',
  };

  String get fileExtension => switch (this) {
    AudioFormat.mp3 => 'mp3',
    AudioFormat.wav => 'wav',
    AudioFormat.m4a => 'm4a',
    AudioFormat.aac => 'aac',
  };

  /// WAV is uncompressed PCM: there's no bitrate to pick.
  bool get supportsBitrate => this != AudioFormat.wav;

  /// FFmpeg arguments selecting the audio codec (and bitrate, where
  /// applicable) for this output format. `-vn` drops any embedded cover-art
  /// "video" stream, which otherwise trips up encoders that don't expect it.
  List<String> encodeArgs(AudioBitrate bitrate) => switch (this) {
    AudioFormat.mp3 => [
      '-vn',
      '-acodec',
      'libmp3lame',
      '-b:a',
      '${bitrate.kbps}k',
    ],
    AudioFormat.aac => ['-vn', '-acodec', 'aac', '-b:a', '${bitrate.kbps}k'],
    AudioFormat.m4a => [
      '-vn',
      '-acodec',
      'aac',
      '-b:a',
      '${bitrate.kbps}k',
      '-movflags',
      '+faststart',
    ],
    AudioFormat.wav => ['-vn', '-acodec', 'pcm_s16le'],
  };
}

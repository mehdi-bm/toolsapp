import 'package:flutter_test/flutter_test.dart';
import 'package:toolbax/features/audio_converter/domain/audio_bitrate.dart';
import 'package:toolbax/features/audio_converter/domain/audio_format.dart';

void main() {
  group('AudioFormat', () {
    test('only WAV is bitrate-less (lossless PCM)', () {
      expect(AudioFormat.wav.supportsBitrate, isFalse);
      expect(AudioFormat.mp3.supportsBitrate, isTrue);
      expect(AudioFormat.aac.supportsBitrate, isTrue);
      expect(AudioFormat.m4a.supportsBitrate, isTrue);
    });

    test('mp3 encodes with the real MP3 codec and the requested bitrate', () {
      final args = AudioFormat.mp3.encodeArgs(AudioBitrate.k192);
      expect(args, containsAllInOrder(['-acodec', 'libmp3lame']));
      expect(args, containsAllInOrder(['-b:a', '192k']));
    });

    test('wav ignores the bitrate argument entirely', () {
      final args = AudioFormat.wav.encodeArgs(AudioBitrate.k320);
      expect(args, containsAllInOrder(['-acodec', 'pcm_s16le']));
      expect(args, isNot(contains('-b:a')));
    });

    test('m4a and aac both use the aac codec but differ in container flags', () {
      final aacArgs = AudioFormat.aac.encodeArgs(AudioBitrate.k128);
      final m4aArgs = AudioFormat.m4a.encodeArgs(AudioBitrate.k128);
      expect(aacArgs, containsAllInOrder(['-acodec', 'aac']));
      expect(m4aArgs, containsAllInOrder(['-acodec', 'aac']));
      expect(m4aArgs, contains('-movflags'));
      expect(aacArgs, isNot(contains('-movflags')));
    });

    test('file extensions match the format', () {
      expect(AudioFormat.mp3.fileExtension, 'mp3');
      expect(AudioFormat.wav.fileExtension, 'wav');
      expect(AudioFormat.m4a.fileExtension, 'm4a');
      expect(AudioFormat.aac.fileExtension, 'aac');
    });
  });

  group('AudioBitrate', () {
    test('kbps values match the requested presets', () {
      expect(AudioBitrate.k128.kbps, 128);
      expect(AudioBitrate.k192.kbps, 192);
      expect(AudioBitrate.k320.kbps, 320);
    });
  });
}

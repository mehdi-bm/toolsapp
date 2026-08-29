// One-off dev script: converts a white-glyph-on-black-background render into
// a transparent PNG by using each pixel's luminance as its alpha channel
// (black background -> alpha 0, white glyph -> alpha 255). Run with:
//   dart run tool/generate_icon_foreground.dart <input.png> <output.png>
import 'dart:io';

import 'package:image/image.dart' as img;

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln('Usage: dart run tool/generate_icon_foreground.dart <input.png> <output.png>');
    exit(1);
  }

  final img.Image src = img.decodePng(File(args[0]).readAsBytesSync())!;
  final img.Image out = img.Image(width: src.width, height: src.height, numChannels: 4);

  for (int y = 0; y < src.height; y++) {
    for (int x = 0; x < src.width; x++) {
      final img.Pixel p = src.getPixel(x, y);
      final int alpha = img.getLuminance(p).round().clamp(0, 255);
      out.setPixelRgba(x, y, 255, 255, 255, alpha);
    }
  }

  File(args[1]).writeAsBytesSync(img.encodePng(out));
  stdout.writeln('Wrote ${args[1]} (${out.width}x${out.height})');
}

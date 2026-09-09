// Packages Imagegen artwork at store resolution without changing the design.
// dart run tool/prepare_icon_assets.dart <icon.png> <foreground.png>
import 'dart:io';

import 'package:image/image.dart' as img;

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln(
      'Usage: dart run tool/prepare_icon_assets.dart '
      '<icon.png> <foreground.png>',
    );
    exitCode = 1;
    return;
  }
  img.Image read(String path) => img.copyResize(
    img.decodePng(File(path).readAsBytesSync())!,
    width: 1024,
    height: 1024,
    interpolation: img.Interpolation.average,
  );
  final icon = img.Image(width: 1024, height: 1024, numChannels: 3);
  img.fill(icon, color: img.ColorRgb8(32, 32, 176));
  img.compositeImage(icon, read(args[0]));
  final foreground = read(args[1]);
  if (foreground.numChannels != 4 || foreground.getPixel(0, 0).a != 0) {
    throw StateError('Adaptive foreground must have a transparent background.');
  }
  File('assets/icon/icon.png').writeAsBytesSync(img.encodePng(icon));
  File(
    'assets/icon/icon_foreground.png',
  ).writeAsBytesSync(img.encodePng(foreground));
  stdout.writeln('Prepared opaque 1024px icon and transparent foreground.');
}

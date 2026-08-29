import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/tool_catalog.dart';
import '../../../core/permissions/permission_copy.dart';
import '../../../core/permissions/permission_gate.dart';
import '../../../core/utils/color_format.dart';
import '../../../core/widgets/tool_scaffold.dart';

class ColorDetectorPage extends StatefulWidget {
  const ColorDetectorPage({super.key});

  @override
  State<ColorDetectorPage> createState() => _ColorDetectorPageState();
}

class _ColorDetectorPageState extends State<ColorDetectorPage> {
  CameraController? _controller;
  bool _initializing = true;
  bool _cameraError = false;
  bool _initStarted = false;
  Color _liveColor = Colors.grey;
  Color? _sampledColor;
  DateTime _lastSampleTime = DateTime.fromMillisecondsSinceEpoch(0);

  // Only called from within the granted branch of PermissionGate's builder
  // (see _buildCameraBody) so the camera is never touched before permission
  // is confirmed.
  Future<void> _initCamera() async {
    try {
      final List<CameraDescription> cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('noCamera', 'No camera found');
      }
      final CameraDescription backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final CameraController controller = CameraController(
        backCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      await controller.startImageStream(_processImage);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cameraError = true;
        _initializing = false;
      });
    }
  }

  void _processImage(CameraImage image) {
    final DateTime now = DateTime.now();
    if (now.difference(_lastSampleTime) < const Duration(milliseconds: 150)) {
      return;
    }
    _lastSampleTime = now;

    try {
      final Color color = _colorAtCenter(image);
      if (mounted) setState(() => _liveColor = color);
    } catch (_) {
      // A malformed frame is not worth surfacing to the user; skip it.
    }
  }

  /// Converts the center pixel of an Android YUV420 camera frame to RGB.
  Color _colorAtCenter(CameraImage image) {
    final int x = image.width ~/ 2;
    final int y = image.height ~/ 2;

    final Plane yPlane = image.planes[0];
    final Plane uPlane = image.planes[1];
    final Plane vPlane = image.planes[2];

    final int yIndex = y * yPlane.bytesPerRow + x;
    final int uvRowStride = uPlane.bytesPerRow;
    final int uvPixelStride = uPlane.bytesPerPixel ?? 1;
    final int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

    final double yVal = yPlane.bytes[yIndex].toDouble();
    final double uVal = uPlane.bytes[uvIndex].toDouble() - 128;
    final double vVal = vPlane.bytes[uvIndex].toDouble() - 128;

    final int r = (yVal + 1.402 * vVal).round().clamp(0, 255);
    final int g = (yVal - 0.344136 * uVal - 0.714136 * vVal)
        .round()
        .clamp(0, 255);
    final int b = (yVal + 1.772 * uVal).round().clamp(0, 255);

    return Color.fromARGB(255, r, g, b);
  }

  void _sample() => setState(() => _sampledColor = _liveColor);

  void _resume() => setState(() => _sampledColor = null);

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ToolItem tool = kToolsById['color_detector']!;

    return ToolScaffold(
      tool: tool,
      helperText: 'دوربین را روی رنگ موردنظر بگیرید و برای ثبت آن ضربه بزنید.',
      body: PermissionGate(
        permission: Permission.camera,
        copy: kCameraPermissionCopy,
        builder: _buildCameraBody,
      ),
    );
  }

  Widget _buildCameraBody(BuildContext context) {
    if (!_initStarted) {
      _initStarted = true;
      _initCamera();
    }
    if (_initializing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_cameraError || _controller == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'دوربین در دسترس نیست.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    final ThemeData theme = Theme.of(context);
    final Color displayColor = _sampledColor ?? _liveColor;
    final String hex = colorToHex(displayColor);
    final ({int r, int g, int b}) rgb = colorToRgb(displayColor);
    final HSVColor hsv = HSVColor.fromColor(displayColor);

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_controller!),
        const IgnorePointer(
          child: Center(
            child: Icon(Icons.add, color: Colors.white, size: 32),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: displayColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('HEX: $hex', style: theme.textTheme.bodyMedium),
                          Text(
                            'RGB: ${rgb.r}, ${rgb.g}, ${rgb.b}',
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            'HSV: ${hsv.hue.round()}°, '
                            '${(hsv.saturation * 100).round()}%, '
                            '${(hsv.value * 100).round()}%',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _copy(context, hex),
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('کپی HEX'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _copy(context, '${rgb.r}, ${rgb.g}, ${rgb.b}'),
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('کپی RGB'),
                    ),
                    FilledButton.icon(
                      key: const Key('color_sample_action'),
                      onPressed: _sampledColor == null ? _sample : _resume,
                      icon: Icon(
                        _sampledColor == null
                            ? Icons.colorize_rounded
                            : Icons.refresh_rounded,
                      ),
                      label: Text(_sampledColor == null ? 'ثبت رنگ' : 'ادامه'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _copy(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('کپی شد.')));
    }
  }
}

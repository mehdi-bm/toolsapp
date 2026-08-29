import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/tool_catalog.dart';
import '../../../core/permissions/permission_copy.dart';
import '../../../core/permissions/permission_gate.dart';
import '../../../core/widgets/tool_scaffold.dart';

class MagnifierPage extends StatefulWidget {
  const MagnifierPage({super.key});

  @override
  State<MagnifierPage> createState() => _MagnifierPageState();
}

class _MagnifierPageState extends State<MagnifierPage> {
  CameraController? _controller;
  bool _initializing = true;
  bool _cameraError = false;
  bool _initStarted = false;
  double _zoom = 1;
  double _minZoom = 1;
  double _maxZoom = 1;
  bool _torchOn = false;

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
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      final double minZoom = await controller.getMinZoomLevel();
      final double maxZoom = await controller.getMaxZoomLevel();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _minZoom = minZoom;
        _maxZoom = maxZoom;
        _zoom = minZoom;
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

  Future<void> _toggleTorch() async {
    final CameraController? controller = _controller;
    if (controller == null) return;
    final bool next = !_torchOn;
    try {
      await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      setState(() => _torchOn = next);
    } catch (_) {
      // Torch may be unsupported on this device/camera; ignore silently.
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ToolItem tool = kToolsById['magnifier']!;

    return ToolScaffold(
      tool: tool,
      helperText: 'برای بزرگ‌نمایی از اسلایدر پایین صفحه استفاده کنید.',
      actions: [
        IconButton(
          key: const Key('magnifier_torch_action'),
          onPressed: _controller == null ? null : _toggleTorch,
          tooltip: 'چراغ‌قوه',
          icon: Icon(
            _torchOn
                ? Icons.flashlight_on_rounded
                : Icons.flashlight_off_rounded,
          ),
        ),
      ],
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

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_controller!),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                const Icon(Icons.zoom_out_rounded, color: Colors.white),
                Expanded(
                  child: Slider(
                    key: const Key('magnifier_zoom_slider'),
                    min: _minZoom,
                    max: _maxZoom,
                    value: _zoom.clamp(_minZoom, _maxZoom),
                    onChanged: _minZoom == _maxZoom
                        ? null
                        : (value) {
                            setState(() => _zoom = value);
                            _controller?.setZoomLevel(value);
                          },
                  ),
                ),
                const Icon(Icons.zoom_in_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

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

class _MagnifierPageState extends State<MagnifierPage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _initializing = true;
  bool _cameraError = false;
  bool _initStarted = false;
  double _zoom = 1;
  double _minZoom = 1;
  double _maxZoom = 1;
  bool _torchOn = false;
  int _session = 0;
  bool _foreground = true;
  Future<void> _closing = Future<void>.value();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _release(CameraController? controller) async {
    try {
      await controller?.dispose();
    } catch (_) {
      /* Camera already closed. */
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _session++;
      final controller = _controller;
      _controller = null;
      _closing = _closing.then((_) => _release(controller));
      _initStarted = false;
      _initializing = true;
      _torchOn = false;
    }
    if (mounted) setState(() {});
  }

  // Only called from within the granted branch of PermissionGate's builder
  // (see _buildCameraBody) so the camera is never touched before permission
  // is confirmed.
  Future<void> _initCamera() async {
    _cameraError = false;
    final int session = ++_session;
    CameraController? pending;
    try {
      await _closing;
      if (!mounted || !_foreground || session != _session) return;
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
      pending = controller;
      await controller.initialize();
      final double minZoom = await controller.getMinZoomLevel();
      final double maxZoom = await controller.getMaxZoomLevel();
      if (!mounted || !_foreground || session != _session) {
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
      await _release(pending);
      if (!mounted || session != _session) return;
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
      if (!mounted || controller != _controller) return;
      setState(() => _torchOn = next);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('چراغ دوربین در دسترس نیست.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _session++;
    WidgetsBinding.instance.removeObserver(this);
    _release(_controller);
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
    if (!_initStarted && _foreground) {
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
        Center(child: CameraPreview(_controller!)),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 64,
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
                            _setZoom(value);
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

  Future<void> _setZoom(double value) async {
    try {
      await _controller?.setZoomLevel(value);
    } catch (_) {
      // A camera session can close while a slider update is in flight.
    }
  }
}

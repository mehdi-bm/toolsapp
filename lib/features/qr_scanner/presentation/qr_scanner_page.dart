import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/tool_catalog.dart';
import '../../../core/permissions/permission_copy.dart';
import '../../../core/permissions/permission_gate.dart';
import '../../../core/widgets/scanner_frame_overlay.dart';
import '../../../core/widgets/tool_scaffold.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  String? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_result != null) return;
    if (capture.barcodes.isEmpty) return;
    final String? value = capture.barcodes.first.rawValue;
    if (value == null || value.isEmpty) return;
    setState(() => _result = value);
    _controller.stop();
  }

  void _rescan() {
    setState(() => _result = null);
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    final ToolItem tool = kToolsById['qr_scanner']!;

    return ToolScaffold(
      tool: tool,
      helperText: 'دوربین را روی کد QR بگیرید تا به‌طور خودکار اسکن شود.',
      actions: [
        IconButton(
          key: const Key('qr_torch_action'),
          onPressed: () => _controller.toggleTorch(),
          tooltip: 'چراغ‌قوه',
          icon: const Icon(Icons.flashlight_on_rounded),
        ),
      ],
      body: PermissionGate(
        permission: Permission.camera,
        copy: kCameraPermissionCopy,
        builder: (context) => Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(controller: _controller, onDetect: _handleDetect),
            const ScannerFrameOverlay(),
            if (_result != null)
              _QrResultPanel(value: _result!, onRescan: _rescan),
          ],
        ),
      ),
    );
  }
}

class _QrResultPanel extends StatelessWidget {
  const _QrResultPanel({required this.value, required this.onRescan});

  final String value;
  final VoidCallback onRescan;

  bool get _isUrl =>
      value.startsWith('http://') || value.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Align(
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
            Text(
              value,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: value));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('کپی شد.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('کپی'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await SharePlus.instance.share(
                        ShareParams(text: value),
                      );
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('اشتراک‌گذاری ممکن نشد.')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('اشتراک‌گذاری'),
                ),
                if (_isUrl)
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        final bool launched = await launchUrl(
                          Uri.parse(value),
                          mode: LaunchMode.externalApplication,
                        );
                        if (!launched && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('باز کردن پیوند ممکن نشد.')),
                          );
                        }
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('باز کردن پیوند ممکن نشد.')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('باز کردن پیوند'),
                  ),
                FilledButton.icon(
                  onPressed: onRescan,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('اسکن مجدد'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

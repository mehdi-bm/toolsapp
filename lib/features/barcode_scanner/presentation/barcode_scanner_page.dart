import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/tool_catalog.dart';
import '../../../core/permissions/permission_copy.dart';
import '../../../core/permissions/permission_gate.dart';
import '../../../core/widgets/scanner_frame_overlay.dart';
import '../../../core/widgets/tool_scaffold.dart';

const List<BarcodeFormat> _kSupportedBarcodeFormats = [
  BarcodeFormat.code128,
  BarcodeFormat.code39,
  BarcodeFormat.code93,
  BarcodeFormat.codabar,
  BarcodeFormat.ean13,
  BarcodeFormat.ean8,
  BarcodeFormat.itf14,
  BarcodeFormat.upcA,
  BarcodeFormat.upcE,
];

String _formatLabel(BarcodeFormat format) {
  switch (format) {
    case BarcodeFormat.code128:
      return 'Code 128';
    case BarcodeFormat.code39:
      return 'Code 39';
    case BarcodeFormat.code93:
      return 'Code 93';
    case BarcodeFormat.codabar:
      return 'Codabar';
    case BarcodeFormat.ean13:
      return 'EAN-13';
    case BarcodeFormat.ean8:
      return 'EAN-8';
    case BarcodeFormat.itf14:
      return 'ITF';
    case BarcodeFormat.upcA:
      return 'UPC-A';
    case BarcodeFormat.upcE:
      return 'UPC-E';
    default:
      return 'بارکد';
  }
}

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    formats: _kSupportedBarcodeFormats,
  );
  Barcode? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_result != null) return;
    if (capture.barcodes.isEmpty) return;
    final Barcode barcode = capture.barcodes.first;
    if (barcode.rawValue == null || barcode.rawValue!.isEmpty) return;
    setState(() => _result = barcode);
    _controller.stop();
  }

  void _rescan() {
    setState(() => _result = null);
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    final ToolItem tool = kToolsById['barcode_scanner']!;

    return ToolScaffold(
      tool: tool,
      helperText:
          'این ابزار فقط بارکد را می‌خواند و اطلاعاتی دربارهٔ محصول نمایش '
          'نمی‌دهد.',
      actions: [
        IconButton(
          key: const Key('barcode_torch_action'),
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
              _BarcodeResultPanel(barcode: _result!, onRescan: _rescan),
          ],
        ),
      ),
    );
  }
}

class _BarcodeResultPanel extends StatelessWidget {
  const _BarcodeResultPanel({required this.barcode, required this.onRescan});

  final Barcode barcode;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String value = barcode.rawValue ?? '';

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
              _formatLabel(barcode.format),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 3,
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

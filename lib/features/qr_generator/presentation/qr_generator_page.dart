import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/tool_catalog.dart';
import '../../../core/widgets/tool_scaffold.dart';
import '../domain/wifi_qr.dart';

enum _QrContentType { text, url, phone, email, wifi }

extension on _QrContentType {
  String get label => switch (this) {
    _QrContentType.text => 'متن',
    _QrContentType.url => 'لینک',
    _QrContentType.phone => 'شماره تلفن',
    _QrContentType.email => 'ایمیل',
    _QrContentType.wifi => 'وای‌فای',
  };
}

class QrGeneratorPage extends StatefulWidget {
  const QrGeneratorPage({super.key});

  @override
  State<QrGeneratorPage> createState() => _QrGeneratorPageState();
}

class _QrGeneratorPageState extends State<QrGeneratorPage> {
  final GlobalKey _qrBoundaryKey = GlobalKey();
  final TextEditingController _primaryController = TextEditingController();
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _wifiPasswordController = TextEditingController();

  _QrContentType _type = _QrContentType.text;
  String _wifiSecurity = 'WPA';
  bool _exporting = false;

  @override
  void dispose() {
    _primaryController.dispose();
    _ssidController.dispose();
    _wifiPasswordController.dispose();
    super.dispose();
  }

  String _buildQrData() {
    switch (_type) {
      case _QrContentType.text:
        return _primaryController.text.trim();
      case _QrContentType.url:
        final String raw = _primaryController.text.trim();
        if (raw.isEmpty) return '';
        return raw.startsWith('http://') || raw.startsWith('https://')
            ? raw
            : 'https://$raw';
      case _QrContentType.phone:
        final String raw = _primaryController.text.trim();
        return raw.isEmpty ? '' : 'tel:$raw';
      case _QrContentType.email:
        final String raw = _primaryController.text.trim();
        return raw.isEmpty ? '' : 'mailto:$raw';
      case _QrContentType.wifi:
        return buildWifiQr(
          ssid: _ssidController.text,
          password: _wifiPasswordController.text,
          security: _wifiSecurity,
        );
    }
  }

  Future<Uint8List?> _renderPng() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return null;
    final RenderRepaintBoundary? boundary =
        _qrBoundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final ui.Image image = await boundary.toImage(pixelRatio: 3);
    try {
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  Future<void> _saveImage() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final Uint8List? bytes = await _renderPng();
      if (bytes == null || !mounted) return;
      await Gal.putImageBytes(
        bytes,
        name: 'qr_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تصویر ذخیره شد.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ذخیرهٔ تصویر ممکن نشد.')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _shareImage() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final Uint8List? bytes = await _renderPng();
      if (bytes == null || !mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: 'image/png', name: 'qr.png')],
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('اشتراک‌گذاری ممکن نشد.')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _copyText() async {
    final String data = _buildQrData();
    if (data.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: data));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('کپی شد.')));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ToolItem tool = kToolsById['qr_generator']!;
    final String data = _buildQrData();
    final bool valid =
        data.isNotEmpty &&
        utf8.encode(data).length <= 2000 &&
        QrValidator.validate(data: data).isValid;

    return ToolScaffold(
      tool: tool,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final _QrContentType type in _QrContentType.values)
                  ChoiceChip(
                    key: Key('qr_gen_type_${type.name}'),
                    label: Text(type.label),
                    selected: _type == type,
                    onSelected: (_) => setState(() => _type = type),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ..._buildFields(),
            const SizedBox(height: 20),
            Center(
              child: !valid
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        data.isEmpty
                            ? 'برای مشاهدهٔ QR، اطلاعات را وارد کنید.'
                            : 'متن برای ساخت QR بیش از حد طولانی است؛ آن را کوتاه کنید.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : RepaintBoundary(
                      key: _qrBoundaryKey,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.white,
                        child: QrImageView(
                          data: data,
                          version: QrVersions.auto,
                          size: 200,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  key: const Key('qr_gen_save_action'),
                  onPressed: !valid || _exporting ? null : _saveImage,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('ذخیره تصویر'),
                ),
                OutlinedButton.icon(
                  onPressed: !valid || _exporting ? null : _shareImage,
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('اشتراک‌گذاری'),
                ),
                OutlinedButton.icon(
                  onPressed: data.isEmpty ? null : _copyText,
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('کپی متن اصلی'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFields() {
    switch (_type) {
      case _QrContentType.text:
        return [
          TextField(
            key: const Key('qr_gen_primary_field'),
            controller: _primaryController,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'متن',
              border: OutlineInputBorder(),
            ),
          ),
        ];
      case _QrContentType.url:
        return [
          TextField(
            key: const Key('qr_gen_primary_field'),
            controller: _primaryController,
            keyboardType: TextInputType.url,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'آدرس لینک',
              hintText: 'example.com',
              border: OutlineInputBorder(),
            ),
          ),
        ];
      case _QrContentType.phone:
        return [
          TextField(
            key: const Key('qr_gen_primary_field'),
            controller: _primaryController,
            keyboardType: TextInputType.phone,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'شماره تلفن',
              border: OutlineInputBorder(),
            ),
          ),
        ];
      case _QrContentType.email:
        return [
          TextField(
            key: const Key('qr_gen_primary_field'),
            controller: _primaryController,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'آدرس ایمیل',
              border: OutlineInputBorder(),
            ),
          ),
        ];
      case _QrContentType.wifi:
        return [
          TextField(
            key: const Key('qr_gen_ssid_field'),
            controller: _ssidController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'نام شبکه (SSID)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('qr_gen_wifi_password_field'),
            controller: _wifiPasswordController,
            obscureText: true,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'رمز عبور',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: const Key('qr_gen_wifi_security_field'),
            initialValue: _wifiSecurity,
            decoration: const InputDecoration(
              labelText: 'نوع امنیت',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'WPA', child: Text('WPA/WPA2')),
              DropdownMenuItem(value: 'WEP', child: Text('WEP')),
              DropdownMenuItem(value: 'nopass', child: Text('بدون رمز')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _wifiSecurity = value);
            },
          ),
        ];
    }
  }
}

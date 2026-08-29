import 'package:flutter/material.dart';
import 'package:torch_light/torch_light.dart';

import '../../../core/constants/tool_catalog.dart';
import '../../../core/widgets/tool_scaffold.dart';

class FlashlightPage extends StatefulWidget {
  const FlashlightPage({super.key});

  @override
  State<FlashlightPage> createState() => _FlashlightPageState();
}

class _FlashlightPageState extends State<FlashlightPage> {
  bool _isOn = false;
  bool _available = true;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    bool available;
    try {
      available = await TorchLight.isTorchAvailable().timeout(
        const Duration(seconds: 5),
      );
    } catch (_) {
      available = false;
    }
    if (!mounted) return;
    setState(() {
      _available = available;
      _checking = false;
    });
  }

  Future<void> _toggle() async {
    try {
      if (_isOn) {
        await TorchLight.disableTorch();
      } else {
        await TorchLight.enableTorch();
      }
      if (!mounted) return;
      setState(() => _isOn = !_isOn);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('کنترل چراغ‌قوه ممکن نشد.')));
    }
  }

  @override
  void dispose() {
    if (_isOn) {
      TorchLight.disableTorch();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ToolItem tool = kToolsById['flashlight']!;

    return ToolScaffold(
      tool: tool,
      helperText: _available
          ? 'برای روشن یا خاموش کردن چراغ‌قوه، دایره را لمس کنید.'
          : 'این دستگاه چراغ‌قوه ندارد یا در دسترس نیست.',
      body: Center(
        child: _checking
            ? const CircularProgressIndicator()
            : GestureDetector(
                key: const Key('flashlight_toggle'),
                onTap: _available ? _toggle : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isOn
                        ? Colors.amber
                        : theme.colorScheme.surfaceContainerHighest,
                    boxShadow: _isOn
                        ? [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.5),
                              blurRadius: 32,
                              spreadRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    _isOn
                        ? Icons.flashlight_on_rounded
                        : Icons.flashlight_off_rounded,
                    size: 72,
                    color: _isOn
                        ? Colors.white
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/tool_catalog.dart';
import '../../../core/permissions/permission_copy.dart';
import '../../../core/permissions/permission_gate.dart';
import '../../../core/utils/persian_numbers.dart';
import '../../../core/widgets/tool_scaffold.dart';

const double _kMinDb = 30;
const double _kMaxDb = 100;

class SoundMeterPage extends StatefulWidget {
  const SoundMeterPage({super.key});

  @override
  State<SoundMeterPage> createState() => _SoundMeterPageState();
}

class _SoundMeterPageState extends State<SoundMeterPage> {
  final NoiseMeter _noiseMeter = NoiseMeter();
  StreamSubscription<NoiseReading>? _subscription;
  double? _currentDb;
  double _maxDb = 0;
  bool _isRunning = false;
  bool _errorState = false;

  Future<void> _start() async {
    setState(() => _errorState = false);
    try {
      _subscription = _noiseMeter.noise.listen(
        (NoiseReading reading) {
          if (!mounted) return;
          if (!reading.meanDecibel.isFinite) return;
          setState(() {
            _currentDb = reading.meanDecibel;
            if (_currentDb! > _maxDb) _maxDb = _currentDb!;
          });
        },
        onError: (Object _) {
          _subscription?.cancel();
          _subscription = null;
          if (!mounted) return;
          setState(() {
            _errorState = true;
            _isRunning = false;
          });
        },
        cancelOnError: true,
      );
      setState(() => _isRunning = true);
    } catch (_) {
      setState(() => _errorState = true);
    }
  }

  Future<void> _stop() async {
    await _subscription?.cancel();
    _subscription = null;
    if (!mounted) return;
    setState(() => _isRunning = false);
  }

  void _reset() {
    setState(() {
      _maxDb = 0;
      _currentDb = null;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ToolItem tool = kToolsById['sound_meter']!;

    return ToolScaffold(
      tool: tool,
      helperText:
          'اندازه‌گیری تقریبی سطح صدا — این ابزار جایگزین یک صداسنج حرفه‌ای '
          'و کالیبره‌شده نیست.',
      actions: [
        IconButton(
          key: const Key('sound_meter_reset_action'),
          onPressed: _reset,
          tooltip: 'بازنشانی',
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: PermissionGate(
        permission: Permission.microphone,
        copy: kMicrophonePermissionCopy,
        builder: _buildMeterBody,
      ),
    );
  }

  Widget _buildMeterBody(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (_errorState) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'دسترسی به میکروفون ممکن نشد.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ),
      );
    }

    final double displayDb = _currentDb ?? _kMinDb;
    final double fraction = ((displayDb - _kMinDb) / (_kMaxDb - _kMinDb))
        .clamp(0, 1);
    final Color meterColor = fraction < 0.5
        ? Colors.green
        : (fraction < 0.8 ? Colors.orange : Colors.red);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _currentDb == null
                ? '—'
                : '${toPersianNumber(_currentDb!, decimalDigits: 0)} dB',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: meterColor,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 20,
              color: meterColor,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'بیشینه: ${toPersianNumber(_maxDb, decimalDigits: 0)} dB',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            key: const Key('sound_meter_toggle'),
            onPressed: _isRunning ? _stop : _start,
            icon: Icon(_isRunning ? Icons.stop_rounded : Icons.mic_rounded),
            label: Text(_isRunning ? 'توقف' : 'شروع'),
          ),
        ],
      ),
    );
  }
}

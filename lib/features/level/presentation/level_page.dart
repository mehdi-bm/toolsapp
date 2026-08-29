import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../core/constants/tool_catalog.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/utils/persian_numbers.dart';
import '../../../core/widgets/tool_scaffold.dart';
import '../data/level_calibration_repository.dart';

class LevelPage extends StatefulWidget {
  const LevelPage({super.key});

  @override
  State<LevelPage> createState() => _LevelPageState();
}

class _LevelPageState extends State<LevelPage> {
  final LevelCalibrationRepository _repository =
      getIt<LevelCalibrationRepository>();

  StreamSubscription<AccelerometerEvent>? _subscription;

  double _rawRoll = 0;
  double _rawPitch = 0;
  double _rollOffset = 0;
  double _pitchOffset = 0;
  bool _hasReading = false;
  bool _sensorUnavailable = false;

  double get _roll => _rawRoll - _rollOffset;
  double get _pitch => _rawPitch - _pitchOffset;

  @override
  void initState() {
    super.initState();
    _rollOffset = _repository.getRollOffset();
    _pitchOffset = _repository.getPitchOffset();

    _subscription =
        accelerometerEventStream(
          samplingPeriod: SensorInterval.uiInterval,
        ).listen(
          (event) {
            final double roll = math.atan2(event.x, event.z) * 180 / math.pi;
            final double pitch = math.atan2(event.y, event.z) * 180 / math.pi;
            if (!mounted) return;
            setState(() {
              _rawRoll = roll;
              _rawPitch = pitch;
              _hasReading = true;
            });
          },
          onError: (Object _) {
            if (!mounted) return;
            setState(() => _sensorUnavailable = true);
          },
          cancelOnError: true,
        );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _calibrate() async {
    setState(() {
      _rollOffset = _rawRoll;
      _pitchOffset = _rawPitch;
    });
    await _repository.saveOffsets(roll: _rollOffset, pitch: _pitchOffset);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ToolItem tool = kToolsById['level']!;

    return ToolScaffold(
      tool: tool,
      helperText:
          'برای دقت بیشتر، گوشی را روی یک سطح واقعاً تراز بگذارید و دکمهٔ '
          'کالیبره کردن را بزنید.',
      actions: [
        IconButton(
          onPressed: _sensorUnavailable ? null : _calibrate,
          tooltip: 'کالیبره کردن',
          icon: const Icon(Icons.center_focus_strong_rounded),
        ),
      ],
      body: _sensorUnavailable
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'سنسور حرکت روی این دستگاه در دسترس نیست.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            )
          : !_hasReading
          ? const Center(child: CircularProgressIndicator())
          : _buildLevelBody(theme),
    );
  }

  Widget _buildLevelBody(ThemeData theme) {
    final bool isLevel = _roll.abs() < 1 && _pitch.abs() < 1;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'افقی: ${toPersianNumber(_roll, decimalDigits: 1)}°   '
          'عمودی: ${toPersianNumber(_pitch, decimalDigits: 1)}°',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        _LevelBubble(
          roll: _roll,
          pitch: _pitch,
          isLevel: isLevel,
          accentColor: theme.colorScheme.primary,
          successColor: Colors.green,
          trackColor: theme.colorScheme.outlineVariant,
        ),
      ],
    );
  }
}

class _LevelBubble extends StatelessWidget {
  const _LevelBubble({
    required this.roll,
    required this.pitch,
    required this.isLevel,
    required this.accentColor,
    required this.successColor,
    required this.trackColor,
  });

  final double roll;
  final double pitch;
  final bool isLevel;
  final Color accentColor;
  final Color successColor;
  final Color trackColor;

  static const double _size = 240;
  static const double _maxAngle = 30;

  @override
  Widget build(BuildContext context) {
    final double clampedRoll = roll.clamp(-_maxAngle, _maxAngle).toDouble();
    final double clampedPitch = pitch.clamp(-_maxAngle, _maxAngle).toDouble();
    final double maxOffset = _size / 2 - 24;
    final Offset offset = Offset(
      (clampedRoll / _maxAngle) * maxOffset,
      (clampedPitch / _maxAngle) * maxOffset,
    );
    final Color bubbleColor = isLevel ? successColor : accentColor;

    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: trackColor, width: 2),
            ),
          ),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: bubbleColor, width: 2),
            ),
          ),
          Transform.translate(
            offset: offset,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bubbleColor.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

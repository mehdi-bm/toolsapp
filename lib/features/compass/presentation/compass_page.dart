import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../core/constants/tool_catalog.dart';
import '../../../core/utils/compass_direction.dart';
import '../../../core/utils/compass_math.dart';
import '../../../core/utils/persian_numbers.dart';
import '../../../core/widgets/tool_scaffold.dart';

class CompassPage extends StatefulWidget {
  const CompassPage({super.key});

  @override
  State<CompassPage> createState() => _CompassPageState();
}

class _CompassPageState extends State<CompassPage> {
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<MagnetometerEvent>? _magSubscription;

  AccelerometerEvent? _lastAccel;
  MagnetometerEvent? _lastMag;
  double? _headingDegrees;
  bool _unavailable = false;
  Timer? _readingTimeout;

  @override
  void initState() {
    super.initState();
    _readingTimeout = Timer(const Duration(seconds: 5), () {
      if (mounted && _headingDegrees == null) {
        setState(() => _unavailable = true);
      }
    });

    _accelSubscription =
        accelerometerEventStream(
          samplingPeriod: SensorInterval.uiInterval,
        ).listen(
          (AccelerometerEvent event) {
            _lastAccel = event;
            _recompute();
          },
          onError: (Object _) {
            if (!mounted) return;
            setState(() => _unavailable = true);
          },
          cancelOnError: true,
        );

    _magSubscription =
        magnetometerEventStream(
          samplingPeriod: SensorInterval.uiInterval,
        ).listen(
          (MagnetometerEvent event) {
            _lastMag = event;
            _recompute();
          },
          onError: (Object _) {
            if (!mounted) return;
            setState(() => _unavailable = true);
          },
          cancelOnError: true,
        );
  }

  void _recompute() {
    final AccelerometerEvent? accel = _lastAccel;
    final MagnetometerEvent? mag = _lastMag;
    if (accel == null || mag == null) return;

    final double? azimuth = computeAzimuthRadians(
      gravityX: accel.x,
      gravityY: accel.y,
      gravityZ: accel.z,
      magneticX: mag.x,
      magneticY: mag.y,
      magneticZ: mag.z,
    );
    if (azimuth == null || !mounted) return;

    double degrees = azimuth * 180 / math.pi;
    if (degrees < 0) degrees += 360;
    setState(() {
      _headingDegrees = degrees;
      _unavailable = false;
    });
  }

  @override
  void dispose() {
    _readingTimeout?.cancel();
    _accelSubscription?.cancel();
    _magSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ToolItem tool = kToolsById['compass']!;

    return ToolScaffold(
      tool: tool,
      helperText:
          'قطب‌نما به سنسور مغناطیسی گوشی نیاز دارد و ممکن است نزدیک اجسام '
          'فلزی دقت کمتری داشته باشد.',
      body: _unavailable
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'قطب‌نما روی این دستگاه در دسترس نیست.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            )
          : _headingDegrees == null
          ? const Center(child: CircularProgressIndicator())
          : _buildCompassBody(theme, _headingDegrees!),
    );
  }

  Widget _buildCompassBody(ThemeData theme, double heading) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: -heading * math.pi / 180,
                child: CustomPaint(
                  size: const Size(260, 260),
                  painter: _CompassDialPainter(
                    color: theme.colorScheme.onSurface,
                    accentColor: theme.colorScheme.primary,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${toPersianNumber(heading, decimalDigits: 0)}° '
          '${compassDirectionLabel(heading)}',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CompassDialPainter extends CustomPainter {
  _CompassDialPainter({required this.color, required this.accentColor});

  final Color color;
  final Color accentColor;

  static const Map<int, String> _labels = {0: 'N', 90: 'E', 180: 'S', 270: 'W'};

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.width / 2 - 8;

    final Paint circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, circlePaint);

    final Paint tickPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 1.5;
    for (int deg = 0; deg < 360; deg += 30) {
      final double screenAngle = (90 - deg) * math.pi / 180;
      final Offset direction = Offset(
        math.cos(screenAngle),
        -math.sin(screenAngle),
      );
      canvas.drawLine(
        center + direction * (radius - 10),
        center + direction * radius,
        tickPaint,
      );
    }

    _labels.forEach((deg, label) {
      final double screenAngle = (90 - deg) * math.pi / 180;
      final Offset direction = Offset(
        math.cos(screenAngle),
        -math.sin(screenAngle),
      );
      final Offset pos = center + direction * (radius - 24);
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: deg == 0 ? accentColor : color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    });
  }

  @override
  bool shouldRepaint(covariant _CompassDialPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.accentColor != accentColor;
  }
}

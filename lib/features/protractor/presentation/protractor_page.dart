import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/tool_catalog.dart';
import '../../../core/utils/persian_numbers.dart';
import '../../../core/widgets/tool_scaffold.dart';

class ProtractorPage extends StatefulWidget {
  const ProtractorPage({super.key});

  @override
  State<ProtractorPage> createState() => _ProtractorPageState();
}

class _ProtractorPageState extends State<ProtractorPage> {
  double _angleDegrees = 90;

  void _updateAngle(Offset localPosition, Size size) {
    final Offset center = Offset(size.width / 2, size.height * 0.92);
    final double dx = localPosition.dx - center.dx;
    final double dy = localPosition.dy - center.dy;

    double degrees;
    if (dy <= 0) {
      degrees = math.atan2(-dy, dx) * 180 / math.pi;
    } else {
      degrees = dx >= 0 ? 0 : 180;
    }

    setState(() => _angleDegrees = degrees.clamp(0, 180).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ToolItem tool = kToolsById['protractor']!;

    return ToolScaffold(
      tool: tool,
      helperText: 'با کشیدن انگشت روی صفحه، عقربه را تا زاویهٔ موردنظر بچرخانید.',
      actions: [
        IconButton(
          key: const Key('protractor_reset_action'),
          onPressed: () => setState(() => _angleDegrees = 90),
          tooltip: 'بازنشانی',
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              '${toPersianNumber(_angleDegrees, decimalDigits: 1)}°',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double side = math.min(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  return Center(
                    child: GestureDetector(
                      key: const Key('protractor_dial'),
                      onPanStart: (details) =>
                          _updateAngle(details.localPosition, Size(side, side)),
                      onPanUpdate: (details) =>
                          _updateAngle(details.localPosition, Size(side, side)),
                      child: CustomPaint(
                        size: Size(side, side),
                        painter: _ProtractorPainter(
                          angleDegrees: _angleDegrees,
                          arcColor: theme.colorScheme.onSurface,
                          needleColor: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProtractorPainter extends CustomPainter {
  _ProtractorPainter({
    required this.angleDegrees,
    required this.arcColor,
    required this.needleColor,
  });

  final double angleDegrees;
  final Color arcColor;
  final Color needleColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height * 0.92);
    final double radius = size.width * 0.42;

    final Paint arcPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      -math.pi,
      false,
      arcPaint,
    );

    final Paint tickPaint = Paint()
      ..color = arcColor
      ..strokeWidth = 1.5;

    for (int d = 0; d <= 180; d += 2) {
      final double theta = d * math.pi / 180;
      final bool isMajor = d % 10 == 0;
      final double outerR = radius;
      final double innerR = radius - (isMajor ? 12 : 6);
      final Offset outer = center + Offset(math.cos(theta), -math.sin(theta)) * outerR;
      final Offset inner = center + Offset(math.cos(theta), -math.sin(theta)) * innerR;
      canvas.drawLine(inner, outer, tickPaint);

      if (isMajor) {
        final TextPainter tp = TextPainter(
          text: TextSpan(
            text: toPersianNumber(d),
            style: TextStyle(color: arcColor, fontSize: 11),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final Offset labelPos = center +
            Offset(math.cos(theta), -math.sin(theta)) * (radius - 26);
        tp.paint(canvas, labelPos - Offset(tp.width / 2, tp.height / 2));
      }
    }

    final double needleTheta = angleDegrees * math.pi / 180;
    final Paint needlePaint = Paint()
      ..color = needleColor
      ..strokeWidth = 3;
    canvas.drawLine(
      center,
      center + Offset(math.cos(needleTheta), -math.sin(needleTheta)) * (radius - 4),
      needlePaint,
    );
    canvas.drawCircle(center, 4, Paint()..color = needleColor);
  }

  @override
  bool shouldRepaint(covariant _ProtractorPainter oldDelegate) {
    return oldDelegate.angleDegrees != angleDegrees;
  }
}

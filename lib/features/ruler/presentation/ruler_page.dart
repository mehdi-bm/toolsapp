import 'package:flutter/material.dart';

import '../../../core/constants/tool_catalog.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/utils/persian_numbers.dart';
import '../../../core/widgets/tool_scaffold.dart';
import '../data/ruler_calibration_repository.dart';

class RulerPage extends StatefulWidget {
  const RulerPage({super.key});

  @override
  State<RulerPage> createState() => _RulerPageState();
}

class _RulerPageState extends State<RulerPage> {
  final RulerCalibrationRepository _repository =
      getIt<RulerCalibrationRepository>();

  late double _pxPerCm;
  bool _vertical = true;

  @override
  void initState() {
    super.initState();
    _pxPerCm = _repository.getPxPerCm();
  }

  Future<void> _openCalibration() async {
    final double? calibrated = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CalibrationSheet(initialPxPerCm: _pxPerCm),
    );
    if (calibrated != null) {
      setState(() => _pxPerCm = calibrated);
      await _repository.savePxPerCm(calibrated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ToolItem tool = kToolsById['ruler']!;

    return ToolScaffold(
      tool: tool,
      helperText:
          'اندازه‌گیری روی صفحهٔ گوشی تقریبی است. برای دقت بیشتر، ابزار را '
          'کالیبره کنید.',
      actions: [
        IconButton(
          key: const Key('ruler_rotate_action'),
          onPressed: () => setState(() => _vertical = !_vertical),
          tooltip: 'چرخش خط‌کش',
          icon: const Icon(Icons.screen_rotation_rounded),
        ),
        IconButton(
          key: const Key('ruler_calibrate_action'),
          onPressed: _openCalibration,
          tooltip: 'کالیبره کردن',
          icon: const Icon(Icons.straighten_rounded),
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CustomPaint(
              size: Size.infinite,
              painter: _RulerPainter(
                pxPerCm: _pxPerCm,
                vertical: _vertical,
                lineColor: theme.colorScheme.onSurface,
                labelColor: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  _RulerPainter({
    required this.pxPerCm,
    required this.vertical,
    required this.lineColor,
    required this.labelColor,
  });

  final double pxPerCm;
  final bool vertical;
  final Color lineColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    final double lengthPx = vertical ? size.height : size.width;
    final double thickness = vertical ? size.width : size.height;
    final double pxPerMm = pxPerCm / 10;
    final int totalMm = (lengthPx / pxPerMm).floor();

    final Paint majorPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5;
    final Paint minorPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    for (int mm = 0; mm <= totalMm; mm++) {
      final double pos = mm * pxPerMm;
      final bool isCm = mm % 10 == 0;
      final bool isHalfCm = mm % 5 == 0;
      final double tickFraction = isCm ? 0.5 : (isHalfCm ? 0.32 : 0.18);
      final double tickLength = thickness * tickFraction;
      final Paint paint = isCm ? majorPaint : minorPaint;

      if (vertical) {
        canvas.drawLine(Offset(0, pos), Offset(tickLength, pos), paint);
      } else {
        canvas.drawLine(Offset(pos, 0), Offset(pos, tickLength), paint);
      }

      if (isCm && mm > 0) {
        final TextPainter tp = TextPainter(
          text: TextSpan(
            text: toPersianNumber(mm ~/ 10),
            style: TextStyle(color: labelColor, fontSize: 11),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        if (vertical) {
          tp.paint(canvas, Offset(tickLength + 4, pos - tp.height / 2));
        } else {
          tp.paint(canvas, Offset(pos - tp.width / 2, tickLength + 2));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) {
    return oldDelegate.pxPerCm != pxPerCm ||
        oldDelegate.vertical != vertical ||
        oldDelegate.lineColor != lineColor;
  }
}

class _CalibrationSheet extends StatefulWidget {
  const _CalibrationSheet({required this.initialPxPerCm});

  final double initialPxPerCm;

  static const double _cardWidthMm = 85.6;

  @override
  State<_CalibrationSheet> createState() => _CalibrationSheetState();
}

class _CalibrationSheetState extends State<_CalibrationSheet> {
  late double _pxPerCm;

  @override
  void initState() {
    super.initState();
    _pxPerCm = widget.initialPxPerCm;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double cardWidthPx =
        (_CalibrationSheet._cardWidthMm / 10) * _pxPerCm;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'کالیبره کردن خط‌کش',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'یک کارت بانکی استاندارد را روی مستطیل زیر بگذارید و اسلایدر را '
            'تنظیم کنید تا عرض آن دقیقاً با عرض کارت برابر شود.',
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: cardWidthPx,
              height: cardWidthPx * 0.63,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.colorScheme.primary),
              ),
              alignment: Alignment.center,
              child: const Text('کارت بانکی'),
            ),
          ),
          const SizedBox(height: 20),
          Slider(
            min: RulerCalibrationRepository.defaultPxPerCm * 0.6,
            max: RulerCalibrationRepository.defaultPxPerCm * 1.6,
            value: _pxPerCm,
            onChanged: (value) => setState(() => _pxPerCm = value),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('انصراف'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_pxPerCm),
                  child: const Text('ذخیره'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/tool_catalog.dart';
import '../../../core/utils/persian_numbers.dart';
import '../../../core/widgets/tool_scaffold.dart';
import '../domain/random_code_generator.dart';

class RandomGeneratorPage extends StatefulWidget {
  const RandomGeneratorPage({super.key});

  @override
  State<RandomGeneratorPage> createState() => _RandomGeneratorPageState();
}

class _RandomGeneratorPageState extends State<RandomGeneratorPage> {
  final Random _random = Random.secure();

  double _length = 6;
  bool _alphanumeric = false;
  String _code = '';

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    setState(() {
      _code = generateRandomCode(
        length: _length.round(),
        alphanumeric: _alphanumeric,
        random: _random,
      );
    });
  }

  Future<void> _copy() async {
    if (_code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _code));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('کپی شد.')));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ToolItem tool = kToolsById['random_generator']!;

    return ToolScaffold(
      tool: tool,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SelectableText(
                key: const Key('random_code_display'),
                _code,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontFamily: 'monospace',
                  letterSpacing: 3,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SegmentedButton<bool>(
              key: const Key('random_type_selector'),
              segments: const [
                ButtonSegment(value: false, label: Text('فقط عدد')),
                ButtonSegment(value: true, label: Text('عدد و حرف')),
              ],
              selected: {_alphanumeric},
              onSelectionChanged: (selection) {
                _alphanumeric = selection.first;
                _generate();
              },
            ),
            const SizedBox(height: 16),
            Text('طول کد: ${toPersianNumber(_length.round())}'),
            Slider(
              key: const Key('random_length_slider'),
              min: 4,
              max: 20,
              divisions: 16,
              value: _length,
              onChanged: (value) {
                _length = value;
                _generate();
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('random_generate_action'),
                    onPressed: _generate,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('تولید'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _code.isEmpty ? null : _copy,
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('کپی'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

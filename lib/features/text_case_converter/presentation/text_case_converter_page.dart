import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/tool_catalog.dart';
import '../../../core/widgets/tool_scaffold.dart';
import '../domain/text_case_converter.dart';

class TextCaseConverterPage extends StatefulWidget {
  const TextCaseConverterPage({super.key});

  @override
  State<TextCaseConverterPage> createState() => _TextCaseConverterPageState();
}

class _TextCaseConverterPageState extends State<TextCaseConverterPage> {
  final TextEditingController _inputController = TextEditingController();
  String _output = '';

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _apply(String Function(String) transform) {
    setState(() => _output = transform(_inputController.text));
  }

  void _clear() {
    setState(() {
      _inputController.clear();
      _output = '';
    });
  }

  Future<void> _copy() async {
    if (_output.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _output));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('کپی شد.')));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ToolItem tool = kToolsById['text_case_converter']!;

    return ToolScaffold(
      tool: tool,
      helperText: 'حروف فارسی حالت بزرگ/کوچک ندارند و بدون تغییر می‌مانند.',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('case_converter_input'),
              controller: _inputController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'متن ورودی',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  key: const Key('case_converter_upper'),
                  onPressed: () => _apply(toUpperCaseSafe),
                  child: const Text('حروف بزرگ'),
                ),
                FilledButton(
                  key: const Key('case_converter_lower'),
                  onPressed: () => _apply(toLowerCaseSafe),
                  child: const Text('حروف کوچک'),
                ),
                FilledButton(
                  key: const Key('case_converter_title'),
                  onPressed: () => _apply(toTitleCase),
                  child: const Text('حالت عنوان'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('نتیجه', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SelectableText(
                key: const Key('case_converter_output'),
                _output.isEmpty ? '—' : _output,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _output.isEmpty ? null : _copy,
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('کپی نتیجه'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clear,
                    icon: const Icon(Icons.clear_rounded),
                    label: const Text('پاک‌سازی'),
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

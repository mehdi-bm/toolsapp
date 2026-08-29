import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/tool_catalog.dart';
import '../../../core/widgets/tool_scaffold.dart';
import '../domain/text_cleaner.dart';

class TextCleanerPage extends StatefulWidget {
  const TextCleanerPage({super.key});

  @override
  State<TextCleanerPage> createState() => _TextCleanerPageState();
}

class _TextCleanerPageState extends State<TextCleanerPage> {
  final TextEditingController _controller = TextEditingController();

  bool _collapseSpaces = true;
  bool _removeEmptyLines = true;
  bool _normalizeLineBreaks = true;
  bool _trimEdges = true;
  bool _normalizeArabicChars = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  TextCleanerOptions get _options => TextCleanerOptions(
    collapseSpaces: _collapseSpaces,
    removeEmptyLines: _removeEmptyLines,
    normalizeLineBreaks: _normalizeLineBreaks,
    trimEdges: _trimEdges,
    normalizeArabicChars: _normalizeArabicChars,
  );

  Future<void> _copy(String value) async {
    if (value.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('کپی شد.')));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ToolItem tool = kToolsById['text_cleaner']!;
    final String cleaned = cleanText(_controller.text, _options);

    return ToolScaffold(
      tool: tool,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('text_cleaner_input'),
              controller: _controller,
              maxLines: 6,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'متن ورودی',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            _OptionSwitch(
              keyName: 'text_cleaner_toggle_collapse_spaces',
              title: 'حذف فاصله‌های اضافی',
              value: _collapseSpaces,
              onChanged: (v) => setState(() => _collapseSpaces = v),
            ),
            _OptionSwitch(
              keyName: 'text_cleaner_toggle_empty_lines',
              title: 'حذف خطوط خالی',
              value: _removeEmptyLines,
              onChanged: (v) => setState(() => _removeEmptyLines = v),
            ),
            _OptionSwitch(
              keyName: 'text_cleaner_toggle_line_breaks',
              title: 'یکسان‌سازی خط جدید',
              value: _normalizeLineBreaks,
              onChanged: (v) => setState(() => _normalizeLineBreaks = v),
            ),
            _OptionSwitch(
              keyName: 'text_cleaner_toggle_trim',
              title: 'حذف فاصلهٔ ابتدا و انتها',
              value: _trimEdges,
              onChanged: (v) => setState(() => _trimEdges = v),
            ),
            _OptionSwitch(
              keyName: 'text_cleaner_toggle_arabic',
              title: 'تبدیل حروف عربی به فارسی (ي→ی, ك→ک)',
              value: _normalizeArabicChars,
              onChanged: (v) => setState(() => _normalizeArabicChars = v),
            ),
            const SizedBox(height: 16),
            Text('پیش‌نمایش نتیجه', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SelectableText(
                key: const Key('text_cleaner_output'),
                cleaned.isEmpty ? '—' : cleaned,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: cleaned.isEmpty ? null : () => _copy(cleaned),
              icon: const Icon(Icons.copy_rounded),
              label: const Text('کپی نتیجه'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionSwitch extends StatelessWidget {
  const _OptionSwitch({
    required this.keyName,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String keyName;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      key: Key(keyName),
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}

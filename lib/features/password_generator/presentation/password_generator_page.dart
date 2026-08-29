import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/tool_catalog.dart';
import '../../../core/utils/persian_numbers.dart';
import '../../../core/widgets/tool_scaffold.dart';
import '../domain/password_generator.dart';

class PasswordGeneratorPage extends StatefulWidget {
  const PasswordGeneratorPage({super.key});

  @override
  State<PasswordGeneratorPage> createState() => _PasswordGeneratorPageState();
}

class _PasswordGeneratorPageState extends State<PasswordGeneratorPage> {
  final Random _random = Random.secure();

  double _length = 16;
  bool _useUppercase = true;
  bool _useLowercase = true;
  bool _useNumbers = true;
  bool _useSymbols = true;
  String _password = '';

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    setState(() {
      _password = generatePassword(
        length: _length.round(),
        useUppercase: _useUppercase,
        useLowercase: _useLowercase,
        useNumbers: _useNumbers,
        useSymbols: _useSymbols,
        random: _random,
      );
    });
  }

  Future<void> _copy() async {
    if (_password.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _password));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('کپی شد.')));
  }

  bool get _hasAnyCategory =>
      _useUppercase || _useLowercase || _useNumbers || _useSymbols;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ToolItem tool = kToolsById['password_generator']!;

    return ToolScaffold(
      tool: tool,
      helperText:
          'رمزهای تولیدشده در برنامه ذخیره نمی‌شوند؛ حتماً آن را در جای امنی '
          'نگه دارید.',
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
                key: const Key('password_display'),
                _password.isEmpty
                    ? 'حداقل یک نوع کاراکتر را انتخاب کنید.'
                    : _password,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: 'monospace',
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('طول رمز: ${toPersianNumber(_length.round())}'),
            Slider(
              key: const Key('password_length_slider'),
              min: 4,
              max: 64,
              divisions: 60,
              value: _length,
              onChanged: (value) {
                _length = value;
                _generate();
              },
            ),
            SwitchListTile(
              key: const Key('password_toggle_uppercase'),
              contentPadding: EdgeInsets.zero,
              title: const Text('حروف بزرگ (A-Z)'),
              value: _useUppercase,
              onChanged: (value) {
                _useUppercase = value;
                _generate();
              },
            ),
            SwitchListTile(
              key: const Key('password_toggle_lowercase'),
              contentPadding: EdgeInsets.zero,
              title: const Text('حروف کوچک (a-z)'),
              value: _useLowercase,
              onChanged: (value) {
                _useLowercase = value;
                _generate();
              },
            ),
            SwitchListTile(
              key: const Key('password_toggle_numbers'),
              contentPadding: EdgeInsets.zero,
              title: const Text('اعداد (0-9)'),
              value: _useNumbers,
              onChanged: (value) {
                _useNumbers = value;
                _generate();
              },
            ),
            SwitchListTile(
              key: const Key('password_toggle_symbols'),
              contentPadding: EdgeInsets.zero,
              title: const Text('نمادها (!@#\$...)'),
              value: _useSymbols,
              onChanged: (value) {
                _useSymbols = value;
                _generate();
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('password_generate_action'),
                    onPressed: _hasAnyCategory ? _generate : null,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('تولید رمز'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _password.isEmpty ? null : _copy,
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

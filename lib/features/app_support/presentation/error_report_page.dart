import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/services/service_locator.dart';
import '../domain/app_support_gateway.dart';

class ErrorReportPage extends StatefulWidget {
  const ErrorReportPage({super.key});

  @override
  State<ErrorReportPage> createState() => _ErrorReportPageState();
}

class _ErrorReportPageState extends State<ErrorReportPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _controller = TextEditingController();
  final AppSupportGateway _gateway = getIt<AppSupportGateway>();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final String trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return 'شرح خطا را وارد کنید.';
    if (trimmed.length < 5) return 'شرح خطا باید حداقل ۵ کاراکتر باشد.';
    return null;
  }

  Future<void> _submit() async {
    // Guards re-entrancy directly, rather than relying only on the button's
    // disabled UI state (which needs a rebuild to take effect and so isn't
    // reliable against two taps dispatched before that rebuild happens).
    if (_submitting) return;
    if (!_gateway.isConfigured) {
      _showSnackBar('این قابلیت در حال حاضر پیکربندی نشده است.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      await _gateway.submitErrorReport(description: _controller.text);
      if (!mounted) return;
      _controller.clear();
      _showSnackBar('گزارش شما ثبت شد.');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e is ApiException ? e.message : 'ارسال گزارش ناموفق بود.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('ارسال گزارش خطا')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'لطفاً بگویید در کدام صفحه، چه کاری انجام دادید، چه نتیجه‌ای '
                    'گرفتید و چه نتیجه‌ای انتظار داشتید. این کمک می‌کند مشکل '
                    'را سریع‌تر پیدا و برطرف کنیم.',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('error_description'),
                  controller: _controller,
                  maxLines: 6,
                  maxLength: 4000,
                  validator: _validate,
                  decoration: const InputDecoration(
                    labelText: 'شرح خطا',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  key: const Key('submit_error_report'),
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('ارسال گزارش'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

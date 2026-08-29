import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/services/service_locator.dart';
import '../domain/app_support_gateway.dart';
import '../domain/phone_number_validator.dart';

final RegExp _kAllowedPhoneChars = RegExp(r'[^0-9٠-٩۰-۹+\-\s()]');

class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String filtered = newValue.text.replaceAll(_kAllowedPhoneChars, '');
    if (filtered == newValue.text) return newValue;
    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }
}

class AdvertisingRequestPage extends StatefulWidget {
  const AdvertisingRequestPage({super.key});

  @override
  State<AdvertisingRequestPage> createState() =>
      _AdvertisingRequestPageState();
}

class _AdvertisingRequestPageState extends State<AdvertisingRequestPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final AppSupportGateway _gateway = getIt<AppSupportGateway>();
  bool _submitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _provinceController.dispose();
    _cityController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  String? _validateFullName(String? value) {
    final String trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return 'نام و نام خانوادگی را وارد کنید.';
    if (trimmed.length < 3 || trimmed.length > 160) {
      return 'باید بین ۳ تا ۱۶۰ کاراکتر باشد.';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final String trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return 'شماره تماس را وارد کنید.';
    if (!isValidPhoneNumber(trimmed)) return 'شمارهٔ تماس معتبر نیست.';
    return null;
  }

  String? _validateProvince(String? value) {
    final String trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return 'استان را وارد کنید.';
    if (trimmed.length < 2 || trimmed.length > 100) {
      return 'باید بین ۲ تا ۱۰۰ کاراکتر باشد.';
    }
    return null;
  }

  String? _validateCity(String? value) {
    final String trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return 'شهر را وارد کنید.';
    if (trimmed.length < 2 || trimmed.length > 100) {
      return 'باید بین ۲ تا ۱۰۰ کاراکتر باشد.';
    }
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
      await _gateway.submitAdvertisingRequest(
        fullName: _fullNameController.text,
        phoneNumber: _phoneController.text,
        province: _provinceController.text,
        city: _cityController.text,
        details: _detailsController.text,
      );
      if (!mounted) return;
      _fullNameController.clear();
      _phoneController.clear();
      _provinceController.clear();
      _cityController.clear();
      _detailsController.clear();
      _showSnackBar(
        'درخواست شما ثبت شد؛ کارشناسان تبلیغات با شمارهٔ ثبت‌شده تماس '
        'می‌گیرند.',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e is ApiException ? e.message : 'ارسال درخواست ناموفق بود.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('درخواست تبلیغ')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('advertising_full_name'),
                  controller: _fullNameController,
                  maxLength: 160,
                  autofillHints: const [AutofillHints.name],
                  validator: _validateFullName,
                  decoration: const InputDecoration(
                    labelText: 'نام و نام خانوادگی',
                    border: OutlineInputBorder(),
                  ),
                ),
                TextFormField(
                  key: const Key('advertising_phone'),
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  maxLength: 20,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  inputFormatters: [_PhoneInputFormatter()],
                  validator: _validatePhone,
                  decoration: const InputDecoration(
                    labelText: 'شماره تماس',
                    border: OutlineInputBorder(),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final Widget province = TextFormField(
                      key: const Key('advertising_province'),
                      controller: _provinceController,
                      maxLength: 100,
                      validator: _validateProvince,
                      decoration: const InputDecoration(
                        labelText: 'استان',
                        border: OutlineInputBorder(),
                      ),
                    );
                    final Widget city = TextFormField(
                      key: const Key('advertising_city'),
                      controller: _cityController,
                      maxLength: 100,
                      validator: _validateCity,
                      decoration: const InputDecoration(
                        labelText: 'شهر',
                        border: OutlineInputBorder(),
                      ),
                    );
                    if (constraints.maxWidth >= 480) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: province),
                          const SizedBox(width: 12),
                          Expanded(child: city),
                        ],
                      );
                    }
                    return Column(children: [province, city]);
                  },
                ),
                TextFormField(
                  key: const Key('advertising_details'),
                  controller: _detailsController,
                  maxLines: 4,
                  maxLength: 4000,
                  decoration: const InputDecoration(
                    labelText: 'توضیحات تکمیلی (اختیاری)',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'اطلاعات شما فقط برای پیگیری همین درخواست استفاده می‌شود.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  key: const Key('submit_advertising_request'),
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
                      : const Text('ثبت درخواست'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_info.dart';
import '../../app_support/presentation/advertising_request_page.dart';
import '../../app_support/presentation/error_report_page.dart';
import '../../other_apps/presentation/other_apps_page.dart';
import 'about_page.dart';
import 'privacy_policy_page.dart';
import 'settings_cubit.dart';
import 'settings_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _confirmReset(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('بازنشانی تنظیمات'),
        content: const Text(
          'ظاهر برنامه و نمایش ابزارهای اخیر به حالت پیش‌فرض بازمی‌گردند. '
          'ادامه می‌دهید؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('بازنشانی'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<SettingsCubit>().resetToDefaults();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تنظیمات بازنشانی شد.')));
      }
    }
  }

  void _showEmailFallback(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('ایمیل تماس: $kContactEmail')));
  }

  Future<void> _contactUs(BuildContext context) async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: kContactEmail,
      query: 'subject=${Uri.encodeComponent(kAppName)}',
    );
    try {
      final bool launched = await launchUrl(uri);
      if (!launched && context.mounted) _showEmailFallback(context);
    } catch (_) {
      if (context.mounted) _showEmailFallback(context);
    }
  }

  Future<void> _shareApp(BuildContext context) async {
    try {
      await SharePlus.instance.share(
        ShareParams(text: '$kAppDescription\n\n$kBazaarUrl'),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('اشتراک‌گذاری ممکن نشد. دوباره تلاش کنید.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _SectionHeader('ظاهر برنامه'),
              SegmentedButton<ThemeMode>(
                key: const Key('settings_theme_mode_selector'),
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('روشن'),
                    icon: Icon(Icons.light_mode_rounded),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('تاریک'),
                    icon: Icon(Icons.dark_mode_rounded),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('سیستم'),
                    icon: Icon(Icons.brightness_auto_rounded),
                  ),
                ],
                selected: {state.themeMode},
                onSelectionChanged: (selection) {
                  context.read<SettingsCubit>().setThemeMode(selection.first);
                },
              ),
              const SizedBox(height: 24),
              const _SectionHeader('تنظیمات'),
              SwitchListTile(
                key: const Key('settings_toggle_show_recent'),
                contentPadding: EdgeInsets.zero,
                title: const Text('نمایش ابزارهای اخیر'),
                subtitle: const Text(
                  'بخش «آخرین ابزارهای استفاده‌شده» در خانه',
                ),
                value: state.showRecent,
                onChanged: (value) =>
                    context.read<SettingsCubit>().setShowRecent(value),
              ),
              ListTile(
                key: const Key('settings_reset_action'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.restart_alt_rounded),
                title: const Text('بازنشانی تنظیمات'),
                onTap: () => _confirmReset(context),
              ),
              const SizedBox(height: 24),
              const _SectionHeader('اطلاعات'),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('نسخه برنامه'),
                trailing: const Text(kAppVersion),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.apps_rounded),
                title: const Text('درباره برنامه'),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const AboutPage())),
              ),
              ListTile(
                key: const Key('settings_other_apps_entry'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.grid_view_rounded),
                title: const Text('اپلیکیشن‌های کاربردی دیگر'),
                subtitle: const Text('محصولات دیگر پارسیک در کافه‌بازار'),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OtherAppsPage()),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('حریم خصوصی'),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.mail_outline_rounded),
                title: const Text('تماس با ما'),
                subtitle: const Text(kContactEmail),
                onTap: () => _contactUs(context),
              ),
              const SizedBox(height: 24),
              const _SectionHeader('پشتیبانی و تبلیغات'),
              ListTile(
                key: const Key('settings_error_report_entry'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.bug_report_outlined),
                title: const Text('ارسال گزارش خطا'),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ErrorReportPage()),
                ),
              ),
              ListTile(
                key: const Key('settings_advertising_request_entry'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.campaign_outlined),
                title: const Text('درخواست تبلیغ'),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdvertisingRequestPage(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _shareApp(context),
                icon: const Icon(Icons.share_rounded),
                label: const Text('اشتراک‌گذاری برنامه'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/widgets/info_page_scaffold.dart';
import '../../../core/widgets/app_logo.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return InfoPageScaffold(
      title: 'درباره برنامه',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const AppLogo(size: 80),
          const SizedBox(height: 16),
          Text(
            kAppName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            kAppTagline,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            kAppDescription,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Text(
            'نسخه $kAppVersion',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => showLicensePage(
              context: context,
              applicationName: kAppName,
              applicationVersion: kAppVersion,
            ),
            child: const Text('مجوزهای متن‌باز'),
          ),
        ],
      ),
    );
  }
}

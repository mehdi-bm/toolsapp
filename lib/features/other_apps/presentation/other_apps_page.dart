import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/parsik_app.dart';

class OtherAppsPage extends StatelessWidget {
  const OtherAppsPage({super.key});

  Future<void> _openInBazaar(BuildContext context, ParsikApp app) async {
    try {
      final bool openedInBazaar = await launchUrl(
        app.bazaarAppUri,
        mode: LaunchMode.externalApplication,
      );
      if (openedInBazaar) return;

      final bool openedOnWeb = await launchUrl(
        app.bazaarWebUri,
        mode: LaunchMode.externalApplication,
      );
      if (openedOnWeb) return;
    } catch (_) {
      // The web fallback below also covers devices without Bazaar installed.
      try {
        if (await launchUrl(
          app.bazaarWebUri,
          mode: LaunchMode.externalApplication,
        )) {
          return;
        }
      } catch (_) {
        // A user-facing message is shown below.
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('باز کردن صفحه برنامه در کافه‌بازار ممکن نشد.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('اپلیکیشن‌های کاربردی دیگر')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final int columnCount = constraints.maxWidth >= 760 ? 2 : 1;

            return CustomScrollView(
              key: const Key('other_apps_scroll_view'),
              slivers: <Widget>[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Card(
                      color: colors.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Icon(
                              Icons.apps_rounded,
                              size: 32,
                              color: colors.onPrimaryContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'محصولات دیگر پارسیک',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: colors.onPrimaryContainer,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'برای مشاهده جزئیات و نصب هر برنامه، آن را انتخاب کنید.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: colors.onPrimaryContainer,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverGrid(
                    key: const Key('other_apps_grid'),
                    delegate: SliverChildBuilderDelegate((
                      BuildContext context,
                      int index,
                    ) {
                      final ParsikApp app = kOtherParsikApps[index];
                      return _AppCard(
                        app: app,
                        onTap: () => _openInBazaar(context, app),
                      );
                    }, childCount: kOtherParsikApps.length),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columnCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 92,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  const _AppCard({required this.app, required this.onTap});

  final ParsikApp app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('other_app_${app.packageName}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  app.iconAsset,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  semanticLabel: 'آیکون ${app.name}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      app.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'مشاهده در کافه‌بازار',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.open_in_new_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

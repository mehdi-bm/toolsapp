import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/ad_banner_model.dart';
import 'ad_banner_cubit.dart';
import 'ad_banner_state.dart';

const double _kBannerHeight = 160;

class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  Timer? _timer;
  bool _dragging = false;
  bool _resumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    if (_resumed) {
      context.read<AdBannerCubit>().onResumed();
      _restartTimer();
    } else {
      _stopTimer();
    }
  }

  void _restartTimer() {
    _stopTimer();
    if (!_resumed || _dragging || !mounted) return;
    final int count = context.read<AdBannerCubit>().state.banners.length;
    if (count < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _dragging || !_pageController.hasClients) return;
      final AdBannerCubit cubit = context.read<AdBannerCubit>();
      final int total = cubit.state.banners.length;
      if (total < 2) return;
      final int next = (cubit.state.currentIndex + 1) % total;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimer();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdBannerCubit, AdBannerState>(
      listenWhen: (previous, current) =>
          previous.banners.length != current.banners.length,
      listener: (context, state) => _restartTimer(),
      builder: (context, state) {
        if (state.initialLoading) {
          return const _BannerSkeleton(key: Key('ad_loading_placeholder'));
        }

        if (state.banners.isEmpty) {
          if (state.errorMessage != null) {
            return _BannerError(
              key: const Key('ad_load_error'),
              message: state.errorMessage!,
              onRetry: () => context.read<AdBannerCubit>().refresh(),
            );
          }
          return const SizedBox.shrink();
        }

        return _BannerCarousel(
          state: state,
          pageController: _pageController,
          onDragStart: () {
            _dragging = true;
            _stopTimer();
          },
          onDragEnd: () {
            _dragging = false;
            _restartTimer();
          },
        );
      },
    );
  }
}

class _BannerCarousel extends StatelessWidget {
  const _BannerCarousel({
    required this.state,
    required this.pageController,
    required this.onDragStart,
    required this.onDragEnd,
  });

  final AdBannerState state;
  final PageController pageController;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<AdBannerModel> banners = state.banners;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _kBannerHeight,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                onDragStart();
              } else if (notification is ScrollEndNotification) {
                onDragEnd();
              }
              return false;
            },
            child: PageView.builder(
              key: const Key('ad_banner_page_view'),
              controller: pageController,
              itemCount: banners.length,
              onPageChanged: (index) =>
                  context.read<AdBannerCubit>().setCurrentIndex(index),
              itemBuilder: (context, index) {
                final AdBannerModel banner = banners[index];
                return _BannerCard(
                  key: Key('ad_banner_${banner.bannerId}'),
                  banner: banner,
                  isOpeningLink: state.isOpeningLink,
                );
              },
            ),
          ),
        ),
        if (banners.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < banners.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == state.currentIndex ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == state.currentIndex
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    super.key,
    required this.banner,
    required this.isOpeningLink,
  });

  final AdBannerModel banner;
  final bool isOpeningLink;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final gateway = context.read<AdBannerCubit>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Semantics(
        label: 'تبلیغ، ${banner.bannerTitle}',
        button: true,
        child: Material(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isOpeningLink ? null : () => gateway.openBanner(banner),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _BannerImage(url: banner.imageUrl),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _AdBadge(theme: theme),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (banner.bannerTitle.isNotEmpty)
                        Text(
                          banner.bannerTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      if (banner.campaignTitle.isNotEmpty ||
                          banner.sectionName.isNotEmpty)
                        Text(
                          [
                            banner.campaignTitle,
                            banner.sectionName,
                          ].where((s) => s.isNotEmpty).join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: Icon(
                    Icons.open_in_new_rounded,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                if (isOpeningLink)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color.fromRGBO(0, 0, 0, 0.25),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdBadge extends StatelessWidget {
  const _AdBadge({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'تبلیغ',
        style: theme.textTheme.labelSmall?.copyWith(color: Colors.white),
      ),
    );
  }
}

class _BannerImage extends StatelessWidget {
  const _BannerImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (url.isEmpty) return _fallback(theme);

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _fallback(theme),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _fallback(theme, showProgress: true);
      },
    );
  }

  Widget _fallback(ThemeData theme, {bool showProgress = false}) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: showProgress
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              Icons.image_not_supported_outlined,
              color: theme.colorScheme.onSurfaceVariant,
              size: 32,
            ),
    );
  }
}

class _BannerSkeleton extends StatelessWidget {
  const _BannerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        height: _kBannerHeight,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _BannerError extends StatelessWidget {
  const _BannerError({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      height: _kBannerHeight,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'دریافت تبلیغات ناموفق بود',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('ad_retry_button'),
            onPressed: onRetry,
            child: const Text('تلاش مجدد'),
          ),
        ],
      ),
    );
  }
}

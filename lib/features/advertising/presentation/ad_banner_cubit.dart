import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_exception.dart';
import '../data/install_id_repository.dart';
import '../domain/ad_banner_model.dart';
import '../domain/advertising_gateway.dart';
import 'ad_banner_state.dart';

class AdBannerCubit extends Cubit<AdBannerState> {
  AdBannerCubit({
    required AdvertisingGateway gateway,
    required InstallIdRepository installIdRepository,
    // ignore: prefer_initializing_formals
  }) : _gateway = gateway,
       // ignore: prefer_initializing_formals
       _installIdRepository = installIdRepository,
       super(const AdBannerState()) {
    _load();
  }

  static const Duration _cacheDuration = Duration(minutes: 20);

  final AdvertisingGateway _gateway;
  final InstallIdRepository _installIdRepository;
  bool _fetchInFlight = false;
  bool _clickInFlight = false;

  Future<void> refresh() => _load(force: true);

  /// Called when the app returns to the foreground; only actually refetches
  /// if the cache has expired.
  void onResumed() => _load();

  void setCurrentIndex(int index) {
    if (index == state.currentIndex) return;
    emit(state.copyWith(currentIndex: index));
  }

  Future<void> _load({bool force = false}) async {
    if (_fetchInFlight) return;

    final DateTime? lastFetch = state.lastSuccessfulFetch;
    if (!force &&
        lastFetch != null &&
        DateTime.now().difference(lastFetch) < _cacheDuration) {
      return;
    }

    if (!_gateway.isConfigured) {
      emit(state.copyWith(initialLoading: false, refreshing: false));
      return;
    }

    _fetchInFlight = true;
    emit(
      state.copyWith(
        initialLoading: state.banners.isEmpty,
        refreshing: state.banners.isNotEmpty,
        clearError: true,
      ),
    );
    try {
      final List<AdBannerModel> fetched = await _gateway.fetchBanners();
      final List<AdBannerModel> banners = fetched
          .map(_withResolvedImageUrl)
          .toList();
      emit(
        state.copyWith(
          banners: banners,
          initialLoading: false,
          refreshing: false,
          lastSuccessfulFetch: DateTime.now(),
          currentIndex: 0,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          initialLoading: false,
          refreshing: false,
          errorMessage: e is ApiException ? e.message : 'دریافت تبلیغات ناموفق بود.',
        ),
      );
    } finally {
      _fetchInFlight = false;
    }
  }

  /// The API may return a relative `imageUrl` (e.g. `/uploads/x.jpg`);
  /// [Image.network] requires an absolute URL, so resolve it against the
  /// ads base URL the same way [openBanner] resolves destination links.
  AdBannerModel _withResolvedImageUrl(AdBannerModel banner) {
    if (banner.imageUrl.isEmpty) return banner;
    try {
      return banner.withImageUrl(_gateway.resolvePublicUrl(banner.imageUrl));
    } catch (_) {
      return banner.withImageUrl('');
    }
  }

  Future<void> openBanner(AdBannerModel banner) async {
    if (_clickInFlight || state.isOpeningLink) return;
    _clickInFlight = true;
    emit(state.copyWith(isOpeningLink: true));

    String destination = banner.destinationUrl;
    try {
      final String installId = await _installIdRepository.getOrCreateId();
      final result = await _gateway.registerClick(
        bannerId: banner.bannerId,
        externalUserId: installId,
      );
      destination = result.destinationUrl;
    } catch (_) {
      // Click registration failed, but the banner itself still carries a
      // destination — open that rather than wasting the user's tap.
    }

    emit(state.copyWith(isOpeningLink: false));
    _clickInFlight = false;

    try {
      final String resolved = _gateway.resolvePublicUrl(destination);
      final Uri? uri = Uri.tryParse(resolved);
      if (uri == null) return;
      if (uri.scheme != 'https' && uri.scheme != 'http') return;
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Nothing more we can do if the destination is unusable/unlaunchable.
    }
  }

  // Deliberately does not call _gateway.close(): the gateway wraps a
  // SecureApiClient shared with AppSupportGateway (see service_locator.dart)
  // and is registered as an app-lifetime singleton, not owned by this cubit.
}

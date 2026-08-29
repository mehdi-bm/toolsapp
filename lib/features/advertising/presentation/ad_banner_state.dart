import '../domain/ad_banner_model.dart';

class AdBannerState {
  const AdBannerState({
    this.banners = const [],
    this.initialLoading = true,
    this.refreshing = false,
    this.currentIndex = 0,
    this.errorMessage,
    this.lastSuccessfulFetch,
    this.isOpeningLink = false,
  });

  final List<AdBannerModel> banners;
  final bool initialLoading;
  final bool refreshing;
  final int currentIndex;
  final String? errorMessage;
  final DateTime? lastSuccessfulFetch;
  final bool isOpeningLink;

  AdBannerState copyWith({
    List<AdBannerModel>? banners,
    bool? initialLoading,
    bool? refreshing,
    int? currentIndex,
    String? errorMessage,
    bool clearError = false,
    DateTime? lastSuccessfulFetch,
    bool? isOpeningLink,
  }) {
    return AdBannerState(
      banners: banners ?? this.banners,
      initialLoading: initialLoading ?? this.initialLoading,
      refreshing: refreshing ?? this.refreshing,
      currentIndex: currentIndex ?? this.currentIndex,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastSuccessfulFetch: lastSuccessfulFetch ?? this.lastSuccessfulFetch,
      isOpeningLink: isOpeningLink ?? this.isOpeningLink,
    );
  }
}

class AdBannerModel {
  const AdBannerModel({
    required this.bannerId,
    required this.bannerTitle,
    required this.imageUrl,
    required this.destinationUrl,
    required this.campaignTitle,
    required this.sectionName,
    required this.sectionCode,
  });

  final String bannerId;
  final String bannerTitle;
  final String imageUrl;
  final String destinationUrl;
  final String campaignTitle;
  final String sectionName;
  final String sectionCode;

  AdBannerModel withImageUrl(String imageUrl) {
    return AdBannerModel(
      bannerId: bannerId,
      bannerTitle: bannerTitle,
      imageUrl: imageUrl,
      destinationUrl: destinationUrl,
      campaignTitle: campaignTitle,
      sectionName: sectionName,
      sectionCode: sectionCode,
    );
  }

  /// Tolerant parser: accepts missing/blank optional fields but rejects the
  /// whole item when `bannerId` is missing or empty.
  static AdBannerModel? tryParse(Map<String, dynamic> json) {
    final String bannerId = _string(json, 'bannerId');
    if (bannerId.isEmpty) return null;

    return AdBannerModel(
      bannerId: bannerId,
      bannerTitle: _string(json, 'bannerTitle'),
      imageUrl: _string(json, 'imageUrl'),
      destinationUrl: _string(json, 'destinationUrl'),
      campaignTitle: _string(json, 'campaignTitle'),
      sectionName: _string(json, 'sectionName'),
      sectionCode: _string(json, 'sectionCode'),
    );
  }

  static String _string(Map<String, dynamic> json, String key) {
    final Object? value = json[key];
    return value is String ? value.trim() : '';
  }
}

import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/advertising/data/advertising_service.dart';
import '../../features/advertising/data/install_id_repository.dart';
import '../../features/advertising/domain/advertising_gateway.dart';
import '../../features/app_support/data/app_support_service.dart';
import '../../features/audio_converter/data/audio_conversion_history_repository.dart';
import '../../features/app_support/domain/app_support_gateway.dart';
import '../../features/favorites/data/favorites_repository.dart';
import '../../features/image_compressor/data/image_compression_history_repository.dart';
import '../../features/home/data/recent_tools_repository.dart';
import '../../features/level/data/level_calibration_repository.dart';
import '../../features/ruler/data/ruler_calibration_repository.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/speed_test/data/speed_test_history_repository.dart';
import '../../features/video_compressor/data/compression_history_repository.dart';
import '../config/ads_config.dart';
import '../config/ads_runtime_config.dart';
import '../network/http_transport.dart';
import '../network/secure_api_client.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  getIt.registerLazySingleton<FavoritesRepository>(
    () => FavoritesRepository(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<RecentToolsRepository>(
    () => RecentToolsRepository(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<RulerCalibrationRepository>(
    () => RulerCalibrationRepository(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<LevelCalibrationRepository>(
    () => LevelCalibrationRepository(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepository(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<CompressionHistoryRepository>(
    () => CompressionHistoryRepository(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<AudioConversionHistoryRepository>(
    () => AudioConversionHistoryRepository(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<ImageCompressionHistoryRepository>(
    () => ImageCompressionHistoryRepository(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<SpeedTestHistoryRepository>(
    () => SpeedTestHistoryRepository(getIt<SharedPreferences>()),
  );

  // Shared transport for every Parsik API call (banners, clicks, error
  // reports, advertising requests) — one client, one timeout/redirect
  // policy, instead of each feature building its own.
  getIt.registerLazySingleton<SecureApiClient>(
    () => SecureApiClient(
      baseUrl: AdsConfig.baseUrl,
      transport: IoHttpTransport(),
    ),
  );
  getIt.registerLazySingleton<AdsRuntimeConfig>(
    AdsRuntimeConfig.fromEnvironment,
  );
  getIt.registerLazySingleton<AdvertisingGateway>(
    () => AdvertisingService(
      client: getIt<SecureApiClient>(),
      config: getIt<AdsRuntimeConfig>(),
    ),
  );
  getIt.registerLazySingleton<AppSupportGateway>(
    () => AppSupportService(
      client: getIt<SecureApiClient>(),
      config: getIt<AdsRuntimeConfig>(),
    ),
  );
  getIt.registerLazySingleton<InstallIdRepository>(
    () => InstallIdRepository(getIt<SharedPreferences>()),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/constants/app_info.dart';
import 'core/routing/app_router.dart';
import 'core/routing/app_routes.dart';
import 'core/services/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'features/advertising/data/install_id_repository.dart';
import 'features/advertising/domain/advertising_gateway.dart';
import 'features/advertising/presentation/ad_banner_cubit.dart';
import 'features/favorites/data/favorites_repository.dart';
import 'features/favorites/presentation/favorites_cubit.dart';
import 'features/home/data/recent_tools_repository.dart';
import 'features/home/presentation/recent_tools_cubit.dart';
import 'features/settings/data/settings_repository.dart';
import 'features/settings/presentation/settings_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Vazirmatn',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
  await setupServiceLocator();
  runApp(const ToolboxApp());
}

class ToolboxApp extends StatelessWidget {
  const ToolboxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => FavoritesCubit(getIt<FavoritesRepository>()),
        ),
        BlocProvider(
          create: (_) => RecentToolsCubit(getIt<RecentToolsRepository>()),
        ),
        BlocProvider(create: (_) => SettingsCubit(getIt<SettingsRepository>())),
        BlocProvider(
          create: (_) => AdBannerCubit(
            gateway: getIt<AdvertisingGateway>(),
            installIdRepository: getIt<InstallIdRepository>(),
          ),
        ),
      ],
      child: Builder(
        builder: (context) {
          final ThemeMode themeMode = context.select(
            (SettingsCubit cubit) => cubit.state.themeMode,
          );

          return MaterialApp(
            title: kAppName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            locale: const Locale('fa', 'IR'),
            supportedLocales: const [Locale('fa', 'IR')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: AppRoutes.root,
            onGenerateRoute: AppRouter.onGenerateRoute,
          );
        },
      ),
    );
  }
}

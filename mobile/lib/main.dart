import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'core/config/app_config.dart';
import 'core/constants/app_constants.dart';
import 'core/database/database_helper.dart';
import 'core/localization/app_localizations.dart';
import 'core/network/network_info.dart';
import 'core/security/secure_storage_service.dart';
import 'core/theme/accessible_theme.dart';

import 'data/datasources/local/caregiver_local_data_source.dart';
import 'data/datasources/local/game_local_data_source.dart';
import 'data/datasources/local/medication_local_data_source.dart';
import 'data/datasources/local/sync_queue_local_data_source.dart';
import 'data/datasources/local/user_local_data_source.dart';

import 'features/adaptive_difficulty/presentation/controllers/adaptive_difficulty_controller.dart';
import 'features/authentication/data/repositories/auth_repository_impl.dart';
import 'features/authentication/presentation/controllers/auth_controller.dart';
import 'features/caregiver/data/repositories/caregiver_dashboard_repository_impl.dart';
import 'features/caregiver/data/repositories/caregiver_repository_impl.dart';
import 'features/caregiver/data/services/caregiver_authorization_service_impl.dart';
import 'features/caregiver/presentation/controllers/caregiver_controller.dart';
import 'features/elderly_home/presentation/controllers/elderly_home_controller.dart';
import 'features/games/data/repositories/game_repository_impl.dart';
import 'features/games/presentation/controllers/face_match_controller.dart';
import 'features/games/presentation/controllers/pattern_completion_controller.dart';
import 'features/games/presentation/controllers/activity_sequence_controller.dart';
import 'features/games/presentation/controllers/object_sorting_controller.dart';
import 'features/games/presentation/controllers/games_controller.dart';
import 'features/games/presentation/screens/face_match_screen.dart';
import 'features/games/presentation/screens/pattern_completion_screen.dart';
import 'features/games/presentation/screens/activity_sequence_screen.dart';
import 'features/games/presentation/screens/object_sorting_screen.dart';
import 'features/localization/presentation/controllers/localization_controller.dart';
import 'features/medication/data/repositories/medication_repository_impl.dart';
import 'features/medication/data/services/local_notification_service.dart';
import 'features/medication/data/services/medication_reminder_scheduler.dart';
import 'features/medication/presentation/controllers/medication_controller.dart';
import 'features/offline_sync/data/repositories/sync_repository_impl.dart';
import 'features/offline_sync/data/services/sync_manager_impl.dart';
import 'features/offline_sync/presentation/controllers/sync_controller.dart';
import 'features/settings/presentation/controllers/settings_controller.dart';
import 'features/voice/data/services/voice_service_impl.dart';
import 'features/voice/presentation/controllers/voice_controller.dart';
import 'features/demo/presentation/controllers/demo_controller.dart';
import 'core/demo/demo_data_manager.dart';
import 'presentation/common_widgets/sih_demo_bar.dart';

import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/welcome/welcome_screen.dart';
import 'presentation/screens/login/login_screen.dart';
import 'presentation/screens/elderly_home/elderly_home_screen.dart';
import 'presentation/screens/games/games_screen.dart';
import 'presentation/screens/games/game_instructions_screen.dart';
import 'presentation/screens/games/game_results_screen.dart';
import 'presentation/screens/medication/medication_screen.dart';
import 'presentation/screens/medication/medication_reminder_screen.dart';
import 'presentation/screens/history/history_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'core/constants/navigation_keys.dart';
import 'presentation/screens/language/language_selection_screen.dart';
import 'presentation/screens/voice/voice_settings_screen.dart';
import 'presentation/screens/caregiver/caregiver_dashboard_screen.dart';
import 'presentation/screens/demo/sih_demo_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite Web Factory if running in browser
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  // Initialize App Configuration (auto-selects production in release mode, development in debug mode)
  AppConfig.initialize();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[FLUTTER ROOT ERROR] ${details.exceptionAsString()}');
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 64, color: Color(0xFFDC2626)),
                const SizedBox(height: 16),
                const Text(
                  'Smriti Setu Recovery',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'An unexpected visual state was encountered. Tap below to safely return to the home screen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    NavigationKeys.rootNavigatorKey.currentState
                        ?.pushNamedAndRemoveUntil('/', (route) => false);
                  },
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Return to Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  // Core singletons
  final dbHelper = DatabaseHelper.instance;
  final secureStorage = SecureStorageService();
  final tokenVault = TokenVault(secureStorage);
  final networkInfo = NetworkInfo();
  final httpClient = HttpClientWrapper(tokenVault: tokenVault);

  // Local Data Sources (UI -> Repository -> Local Data Source -> SQLite)
  final userLocalDataSource = UserLocalDataSourceImpl(dbHelper: dbHelper);
  final caregiverLocalDataSource = CaregiverLocalDataSourceImpl(dbHelper: dbHelper);
  final relationshipLocalDataSource = RelationshipLocalDataSourceImpl(dbHelper: dbHelper);
  final gameLocalDataSource = GameLocalDataSourceImpl(dbHelper: dbHelper);
  final medicationLocalDataSource = MedicationLocalDataSourceImpl(dbHelper: dbHelper);
  final syncLocalDataSource = SyncQueueLocalDataSourceImpl(dbHelper: dbHelper);

  // Concrete repositories
  final authRepo = AuthRepositoryImpl(
    userLocalDataSource: userLocalDataSource,
    tokenVault: tokenVault,
  );
  final gameRepo = GameRepositoryImpl(localDataSource: gameLocalDataSource);
  final medicationRepo = MedicationRepositoryImpl(localDataSource: medicationLocalDataSource);
  final caregiverRepo = CaregiverRepositoryImpl(
    caregiverDataSource: caregiverLocalDataSource,
    relationshipDataSource: relationshipLocalDataSource,
  );
  final caregiverAuthService = CaregiverAuthorizationServiceImpl(dbHelper: dbHelper);
  final caregiverDashboardRepo = CaregiverDashboardRepositoryImpl(
    authService: caregiverAuthService,
    dbHelper: dbHelper,
  );
  final syncRepo = SyncRepositoryImpl(localDataSource: syncLocalDataSource);

  // Concrete services
  final voiceService = VoiceServiceImpl();
  final notificationService = LocalNotificationService();
  final medicationScheduler = MedicationReminderScheduler(
    repository: medicationRepo,
    notificationService: notificationService,
  );
  final syncManager = SyncManagerImpl(
    repository: syncRepo,
    networkInfo: networkInfo,
    httpClient: httpClient,
  );

  try {
    await syncManager.initialize();
  } catch (e, stack) {
    debugPrint('SyncManager init notice: $e\n$stack');
  }

  // SIH Demo Controller and synthetic baseline seeding
  final demoController = DemoController(networkInfo: networkInfo, dbHelper: dbHelper);
  try {
    await DemoDataManager.seedDemoData(dbHelper: dbHelper, resetExisting: false);
  } catch (e, stack) {
    debugPrint('DemoDataManager init notice: $e\n$stack');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: demoController),
        ChangeNotifierProvider(create: (_) => SettingsController()),
        ChangeNotifierProvider(create: (_) => LocalizationController()),
        ChangeNotifierProvider(create: (_) => VoiceController(voiceService: voiceService)),
        ChangeNotifierProvider(create: (_) => AuthController(authRepository: authRepo)),
        ChangeNotifierProvider(create: (_) => ElderlyHomeController()),
        ChangeNotifierProvider(create: (_) => GamesController(gameRepository: gameRepo)),
        ChangeNotifierProvider(create: (_) => AdaptiveDifficultyController()),
        ChangeNotifierProvider(
          create: (ctx) => FaceMatchController(
            gameRepository: gameRepo,
            adaptiveController: ctx.read<AdaptiveDifficultyController>(),
            voiceController: ctx.read<VoiceController>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => PatternCompletionController(
            gameRepository: gameRepo,
            adaptiveController: ctx.read<AdaptiveDifficultyController>(),
            voiceController: ctx.read<VoiceController>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => ActivitySequenceController(
            gameRepository: gameRepo,
            adaptiveController: ctx.read<AdaptiveDifficultyController>(),
            voiceController: ctx.read<VoiceController>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => ObjectSortingController(
            gameRepository: gameRepo,
            adaptiveController: ctx.read<AdaptiveDifficultyController>(),
            voiceController: ctx.read<VoiceController>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => MedicationController(
            repository: medicationRepo,
            scheduler: medicationScheduler,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CaregiverController(
            caregiverRepo: caregiverRepo,
            gameRepo: gameRepo,
            medicationRepo: medicationRepo,
            dashboardRepo: caregiverDashboardRepo,
            authService: caregiverAuthService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SyncController(
            syncManager: syncManager,
            syncRepository: syncRepo,
          ),
        ),
      ],
      child: const SmritiSetuApp(),
    ),
  );
}

class SmritiSetuApp extends StatelessWidget {
  const SmritiSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locCtrl = context.watch<LocalizationController>();
    final settingsCtrl = context.watch<SettingsController>();

    return MaterialApp(
      navigatorKey: NavigationKeys.rootNavigatorKey,
      scaffoldMessengerKey: NavigationKeys.rootScaffoldMessengerKey,
      title: AppConstants.appName,
      locale: locCtrl.currentLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: settingsCtrl.highContrast
          ? AccessibleTheme.getHighContrastTheme(fontScale: settingsCtrl.fontScale)
          : AccessibleTheme.getLightTheme(fontScale: settingsCtrl.fontScale),
      builder: (context, child) {
        Widget effectiveChild = child ?? const SizedBox.shrink();
        if (child == null) {
          // If navigator popped all routes or hit null state, defensively auto-recover to root
          WidgetsBinding.instance.addPostFrameCallback((_) {
            NavigationKeys.rootNavigatorKey.currentState
                ?.pushNamedAndRemoveUntil('/', (route) => false);
          });
          effectiveChild = Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading Smriti Setu...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: settingsCtrl.highContrast ? Colors.white : const Color(0xFF0F3D78),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(settingsCtrl.fontScale),
          ),
          child: Directionality(
            textDirection: locCtrl.isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: Stack(
              children: [
                effectiveChild,
                const SihDemoBar(),
              ],
            ),
          ),
        );
      },
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(
              onLanguageChanged: (newLoc) => locCtrl.setLocale(newLoc),
              onToggleTheme: () => settingsCtrl.toggleHighContrast(),
              isHighContrast: settingsCtrl.highContrast,
            ),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/elderly_home': (context) => const ElderlyHomeScreen(),
        '/patient': (context) => const ElderlyHomeScreen(),
        '/home': (context) => const ElderlyHomeScreen(),
        '/games': (context) => const GamesScreen(),
        '/face_match': (context) => const FaceMatchScreen(),
        '/game/face_match': (context) => const FaceMatchScreen(),
        '/pattern_completion': (context) => const PatternCompletionScreen(),
        '/game/pattern_completion': (context) => const PatternCompletionScreen(),
        '/activity_sequence': (context) => const ActivitySequenceScreen(),
        '/game/activity_sequence': (context) => const ActivitySequenceScreen(),
        '/object_sorting': (context) => const ObjectSortingScreen(),
        '/game/object_sorting': (context) => const ObjectSortingScreen(),
        '/game_instructions': (context) => const GameInstructionsScreen(),
        '/game_results': (context) => const GameResultsScreen(),
        '/medication': (context) => const MedicationScreen(),
        '/medication_reminder': (context) => const MedicationReminderScreen(),
        '/history': (context) => const HistoryScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/language': (context) => const LanguageSelectionScreen(),
        '/voice_settings': (context) => const VoiceSettingsScreen(),
        '/caregiver': (context) => const CaregiverDashboardScreen(),
        '/dashboard': (context) => const CaregiverDashboardScreen(),
        '/caregiver_dashboard': (context) => const CaregiverDashboardScreen(),
        '/demo': (context) => const SihDemoScreen(),
        '/sih_demo': (context) => const SihDemoScreen(),
      },
      onUnknownRoute: (settings) {
        debugPrint('[ROUTER] Unknown route requested: ${settings.name}');
        return MaterialPageRoute(
          builder: (context) => SplashScreen(
            onLanguageChanged: (newLoc) => locCtrl.setLocale(newLoc),
            onToggleTheme: () => settingsCtrl.toggleHighContrast(),
            isHighContrast: settingsCtrl.highContrast,
          ),
          settings: settings,
        );
      },
    );
  }
}

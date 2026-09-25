import 'package:flutter/foundation.dart';

enum Environment { development, staging, production }

class AppConfig {
  final Environment environment;
  final String appName;
  final String appVersion;
  final String apiBaseUrl;
  final Duration apiTimeout;
  final int syncIntervalSeconds;
  final int syncBatchSize;
  final bool enableLogging;
  final bool enableMockVoice;
  final String medicalDisclaimer;

  const AppConfig._({
    required this.environment,
    required this.appName,
    required this.appVersion,
    required this.apiBaseUrl,
    required this.apiTimeout,
    required this.syncIntervalSeconds,
    required this.syncBatchSize,
    required this.enableLogging,
    required this.enableMockVoice,
    required this.medicalDisclaimer,
  });

  static AppConfig? _current;
  static AppConfig get current {
    if (_current == null) {
      initialize(Environment.development);
    }
    return _current!;
  }

  static void initialize([Environment? env]) {
    const customApiUrl = String.fromEnvironment('API_BASE_URL');
    const customEnvName = String.fromEnvironment('APP_ENV');

    Environment selectedEnv = env ?? (kReleaseMode ? Environment.production : Environment.development);
    if (customEnvName.isNotEmpty) {
      final normalized = customEnvName.toLowerCase();
      if (normalized == 'production' || normalized == 'prod') {
        selectedEnv = Environment.production;
      } else if (normalized == 'staging') {
        selectedEnv = Environment.staging;
      } else if (normalized == 'development' || normalized == 'dev') {
        selectedEnv = Environment.development;
      }
    }

    final String resolvedApiUrl;
    if (customApiUrl.isNotEmpty) {
      resolvedApiUrl = customApiUrl;
    } else {
      switch (selectedEnv) {
        case Environment.production:
          resolvedApiUrl = 'https://api.smritisetu.gov.in/api/v1';
          break;
        case Environment.staging:
          resolvedApiUrl = 'https://staging-api.smritisetu.gov.in/api/v1';
          break;
        case Environment.development:
          resolvedApiUrl = kIsWeb
              ? 'http://localhost:3000/api/v1'
              : (defaultTargetPlatform == TargetPlatform.android
                  ? 'http://10.0.2.2:3000/api/v1'
                  : 'http://localhost:3000/api/v1');
          break;
      }
    }

    switch (selectedEnv) {
      case Environment.development:
        _current = AppConfig._(
          environment: Environment.development,
          appName: 'SmritiSetu [DEV]',
          appVersion: '1.0.0-dev',
          apiBaseUrl: resolvedApiUrl,
          apiTimeout: const Duration(seconds: 15),
          syncIntervalSeconds: 30,
          syncBatchSize: 10,
          enableLogging: true,
          enableMockVoice: true,
          medicalDisclaimer:
              'NOTICE: SmritiSetu is an assistive cognitive-support prototype. '
              'It does NOT medically diagnose dementia or replace professional clinical care.',
        );
        break;

      case Environment.staging:
        _current = AppConfig._(
          environment: Environment.staging,
          appName: 'SmritiSetu [STAGING]',
          appVersion: '1.0.0-rc1',
          apiBaseUrl: resolvedApiUrl,
          apiTimeout: const Duration(seconds: 20),
          syncIntervalSeconds: 60,
          syncBatchSize: 25,
          enableLogging: true,
          enableMockVoice: false,
          medicalDisclaimer:
              'NOTICE: SmritiSetu is an assistive cognitive-support prototype. '
              'It does NOT medically diagnose dementia or replace professional clinical care.',
        );
        break;

      case Environment.production:
        _current = AppConfig._(
          environment: Environment.production,
          appName: 'SmritiSetu',
          appVersion: '1.0.0',
          apiBaseUrl: resolvedApiUrl,
          apiTimeout: const Duration(seconds: 10),
          syncIntervalSeconds: 60,
          syncBatchSize: 25,
          enableLogging: false,
          enableMockVoice: false,
          medicalDisclaimer:
              'NOTICE: SmritiSetu is an assistive cognitive-support and non-clinical monitoring prototype. '
              'It does NOT diagnose dementia, replace a doctor, prescribe medication, or determine clinical therapy.',
        );
        break;
    }
  }

  bool get isDevelopment => environment == Environment.development;
  bool get isProduction => environment == Environment.production;
}

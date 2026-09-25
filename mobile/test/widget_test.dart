import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:smriti_setu/features/localization/presentation/controllers/localization_controller.dart';
import 'package:smriti_setu/features/settings/presentation/controllers/settings_controller.dart';
import 'package:smriti_setu/main.dart';

void main() {
  testWidgets('SmritiSetuApp root smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsController()),
          ChangeNotifierProvider(create: (_) => LocalizationController()),
        ],
        child: const SmritiSetuApp(),
      ),
    );

    // Verify that SmritiSetuApp mounts MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

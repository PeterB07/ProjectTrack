import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:rate_my_app/rate_my_app.dart';
import 'package:traccar_client/geolocation_service.dart';
import 'package:traccar_client/push_service.dart';
import 'package:traccar_client/quick_actions.dart';
import 'package:traccar_client/websocket_service.dart';
import 'package:traccar_client/l10n/app_localizations.dart';
import 'package:traccar_client/main_screen.dart';
import 'package:traccar_client/preferences.dart';

final messengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Preferences.init();
  await Preferences.instance.setString(Preferences.url, 'http://3.17.110.39:8082');
  await Preferences.migrate();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final RateMyApp rateMyApp = RateMyApp(minDays: 0, minLaunches: 0);

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Crashlytics setup
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    // Enforce default preferences

    // Initialize services
    await GeolocationService.init();
    await PushService.init();
    await WebSocketService.instance.start();
    // Prompt for rating if needed
    await rateMyApp.init();
    if (mounted && rateMyApp.shouldOpenDialog) {
      try {
        await rateMyApp.showRateDialog(context);
      } catch (error) {
        developer.log('Failed to show rate dialog', error: error);
      }
    }

  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: messengerKey,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.light),
      ),
      darkTheme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.dark),
      ),
      home: const MainScreen(),
    );
  }
}

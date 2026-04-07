import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/controller/home_controller.dart';
import 'package:telecaller_app/controller/lead_repository.dart';
import 'package:telecaller_app/controller/lead_screen_controller.dart';
import 'package:telecaller_app/controller/followup_controller.dart';
import 'package:telecaller_app/controller/performance_controller.dart';
import 'package:telecaller_app/controller/report_controller.dart';
import 'package:telecaller_app/controller/call_tracking_controller.dart';
import 'package:telecaller_app/view/home_screen/bottomnavigation_bar.dart';
import 'package:telecaller_app/view/login_screen.dart';
import 'package:telecaller_app/services/auth_service.dart';
import 'package:telecaller_app/services/api_service.dart';
import 'package:telecaller_app/services/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().initialize();
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  ApiService.onSessionExpired = () {
    AuthService.clearAuth();
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HeaderController()),
        ChangeNotifierProvider(create: (_) => HomeController()),
        ChangeNotifierProvider(create: (_) => LeadScreenController()),
        ChangeNotifierProvider(create: (_) => FollowupController()),
        ChangeNotifierProvider(create: (_) => PerformanceController()),
        ChangeNotifierProvider(create: (_) => ReportController()),
        ChangeNotifierProvider(create: (_) => CallTrackingController()),
        ChangeNotifierProvider(create: (_) => LeadRepository()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Demo',
        theme: ThemeData(useMaterial3: true),
        navigatorKey: navigatorKey,
        home: const RootScreen(),
        routes: {'/login': (context) => const LoginScreen()},
      ),
    );
  }
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: AuthService.isAuthenticated(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      if (snapshot.data == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await Provider.of<LeadRepository>(
            context,
            listen: false,
          ).forceReloadFromStorage();
        });
        return const BottomNav();
      }
      return const LoginScreen();
    },
  );
}

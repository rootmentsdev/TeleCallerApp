import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telecaller_app/controller/header_controller.dart';
import 'package:telecaller_app/controller/home_controller.dart';
import 'package:telecaller_app/controller/lead_repository.dart';
import 'package:telecaller_app/controller/lead_screen_controller.dart';
import 'package:telecaller_app/controller/followup_controller.dart';
import 'package:telecaller_app/controller/report_controller.dart';
import 'package:telecaller_app/controller/call_tracking_controller.dart';
import 'package:telecaller_app/view/bottomnavigation_bar.dart';
import 'package:telecaller_app/view/login_screen.dart';
import 'package:telecaller_app/services/auth_service.dart';
import 'package:telecaller_app/services/api_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  final config = ClarityConfig(projectId: "uns0n3uysr");
  // Set up session expiry callback
  ApiService.onSessionExpired = () {
    // Clear auth and navigate to login
    AuthService.clearAuth();
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  };

  runApp(ClarityWidget(app: MyApp(), clarityConfig: config));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HeaderController()),
        ChangeNotifierProvider(create: (_) => HomeController()),
        ChangeNotifierProvider(create: (_) => LeadScreenController()),
        ChangeNotifierProvider(create: (_) => FollowupController()),
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

/// RootScreen decides whether to show Login or Home based on authentication state.
class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isAuthenticated(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isAuth = snapshot.data == true;
        if (isAuth) {
          // When user is authenticated, ensure data is properly loaded
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final leadRepository = Provider.of<LeadRepository>(
              context,
              listen: false,
            );
            await leadRepository.forceReloadFromStorage();
            print('RootScreen: Data reloaded after authentication check');
          });
          return const BottomNav();
        }

        return const LoginScreen();
      },
    );
  }
}

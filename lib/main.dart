import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geliyor_app/app_navigator.dart';
import 'package:geliyor_app/firebase_options.dart';
import 'package:geliyor_app/screens/login_screen.dart';
import 'package:geliyor_app/screens/splash_screen.dart';
import 'package:geliyor_app/services/food_reminder_sync.dart';
import 'package:geliyor_app/services/push_service.dart';
import 'package:geliyor_app/services/user_profile_sync.dart';
import 'package:geliyor_app/state/health_calendar_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/login_gate.dart';
import 'package:geliyor_app/widgets/in_app_notice_host.dart';
import 'package:geliyor_app/widgets/mobile_web_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await PushService.instance.start();
  UserProfileSync.start();
  FoodReminderSync.start();
  HealthCalendarStore.start();
  LoginGate.openLogin = (context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(returnToPrevious: true),
      ),
    );
    return result == true;
  };

  // Durum çubuğu (saat / Wi‑Fi) ile uygulama aynı zeminde görünsün;
  // gri şerit “sayfa üstünde sayfa” etkisini kaldırır.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(_appSystemUi);

  runApp(const GeliyorApp());
}

const SystemUiOverlayStyle _appSystemUi = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.dark,
  systemNavigationBarContrastEnforced: false,
);

class GeliyorApp extends StatelessWidget {
  const GeliyorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'geliyor.tr',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.primaryLight,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: _appSystemUi,
          backgroundColor: AppColors.background,
          elevation: 0,
        ),
      ),
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: _appSystemUi,
          child: InAppNoticeHost(
            child: MobileWebShell(child: child ?? const SizedBox.shrink()),
          ),
        );
      },
      home: const SplashScreen(),
    );
  }
}

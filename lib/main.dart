import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geliyor_app/app_bootstrap.dart';
import 'package:geliyor_app/app_navigator.dart';
import 'package:geliyor_app/admin/category_repository.dart';
import 'package:geliyor_app/data/brand_repository.dart';
import 'package:geliyor_app/data/courier_fee_repository.dart';
import 'package:geliyor_app/data/system_feeding_repository.dart';
import 'package:geliyor_app/data/welcome_splash_repository.dart';
import 'package:geliyor_app/firebase_options.dart';
import 'package:geliyor_app/screens/login_screen.dart';
import 'package:geliyor_app/screens/splash_screen.dart';
import 'package:geliyor_app/services/food_reminder_sync.dart';
import 'package:geliyor_app/services/network_reconnect.dart';
import 'package:geliyor_app/services/push_service.dart';
import 'package:geliyor_app/services/user_profile_sync.dart';
import 'package:geliyor_app/state/health_calendar_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/login_gate.dart';
import 'package:geliyor_app/widgets/in_app_notice_host.dart';
import 'package:geliyor_app/widgets/mobile_web_shell.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  widgetsBinding.deferFirstFrame();
  imageCache.maximumSize = 200;
  imageCache.maximumSizeBytes = 120 << 20;

  try {
    await WelcomeSplashRepository.instance.preloadLocal();
  } catch (error, stack) {
    debugPrint('Splash cache: $error\n$stack');
  }

  try {
    await _ensureFirebase();
    AppBootstrap.markFirebaseReady();
    await PushService.instance.start();
    NetworkReconnect.instance.start();
    UserProfileSync.start();
    FoodReminderSync.start();
    HealthCalendarStore.start();
    BrandRepository.instance.startListening();
    CourierFeeRepository.instance.startListening();
    CategoryRepository.instance.startListening();
    SystemFeedingRepository.instance.startListening();
    LoginGate.openLogin = (context) async {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(returnToPrevious: true),
        ),
      );
      return result == true;
    };
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(_appSystemUi);
  } catch (error, stack) {
    debugPrint('Backend start failed: $error\n$stack');
    AppBootstrap.markFirebaseReady();
  }

  runApp(const GeliyorApp());
  widgetsBinding.allowFirstFrame();
}

Future<void> _ensureFirebase() async {
  if (Firebase.apps.isNotEmpty) return;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    if (Firebase.apps.isNotEmpty) return;
    final text = '$error';
    if (text.contains('duplicate-app')) return;
    rethrow;
  }
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

import 'package:flutter/material.dart';
import 'package:geliyor_app/screens/splash_screen.dart';
import 'package:geliyor_app/theme/app_colors.dart';

void main() {
  runApp(const GeliyorApp());
}

class GeliyorApp extends StatelessWidget {
  const GeliyorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'geliyor.tr',
      debugShowCheckedModeBanner: false,
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
      ),
      home: const SplashScreen(),
    );
  }
}

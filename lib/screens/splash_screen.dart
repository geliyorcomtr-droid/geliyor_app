import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geliyor_app/screens/home_screen.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_brand_logo.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/paw_print_background.dart';
import 'package:geliyor_app/widgets/welcome_feature_circles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _autoNavigateDelay = Duration(seconds: 4);
  static const _tapEnabledAfter = Duration(seconds: 1);

  Timer? _autoNavigateTimer;
  Timer? _tapEnableTimer;
  bool _canTapNavigate = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _tapEnableTimer = Timer(_tapEnabledAfter, () {
      if (!mounted) return;
      setState(() => _canTapNavigate = true);
    });
    _autoNavigateTimer = Timer(_autoNavigateDelay, _goHome);
  }

  @override
  void dispose() {
    _autoNavigateTimer?.cancel();
    _tapEnableTimer?.cancel();
    super.dispose();
  }

  void _goHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _autoNavigateTimer?.cancel();
    _tapEnableTimer?.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _onTapAnywhere() {
    if (!_canTapNavigate) return;
    _goHome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame(
        backgroundColor: AppColors.background,
        pawPrintStyle: PawPrintStyle.splash,
        child: GestureDetector(
          onTap: _onTapAnywhere,
          behavior: HitTestBehavior.opaque,
          child: const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppBrandLogo(height: 320, errorIconSize: 88),
                  SizedBox(height: 8),
                  WelcomePhoneLine(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geliyor_app/screens/home_screen.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _logoPath = 'assets/images/geliyor_splash_logo.png';

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
      backgroundColor: AppColors.surface,
      body: AppPageFrame(
        backgroundColor: AppColors.surface,
        child: GestureDetector(
          onTap: _onTapAnywhere,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primary, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Image.asset(
                    _logoPath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.pets_rounded,
                      color: AppColors.primary,
                      size: 88,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

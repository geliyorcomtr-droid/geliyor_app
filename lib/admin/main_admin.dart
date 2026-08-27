import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/admin/admin_auth.dart';
import 'package:geliyor_app/admin/screens/admin_login_screen.dart';
import 'package:geliyor_app/admin/screens/admin_shell.dart';
import 'package:geliyor_app/firebase_options.dart';
import 'package:geliyor_app/theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AdminAuth.instance.init();
  runApp(const GeliyorAdminApp());
}

class GeliyorAdminApp extends StatelessWidget {
  const GeliyorAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'geliyor.tr Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      ),
      home: const _AdminGate(),
    );
  }
}

class _AdminGate extends StatelessWidget {
  const _AdminGate();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AdminAuth.instance,
      builder: (context, _) {
        final auth = AdminAuth.instance;
        if (!auth.ready) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (auth.isAdmin) {
          return const AdminShell();
        }
        return const AdminLoginScreen();
      },
    );
  }
}

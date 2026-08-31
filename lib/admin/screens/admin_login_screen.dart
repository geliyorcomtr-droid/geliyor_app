import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geliyor_app/admin/admin_auth.dart';
import 'package:geliyor_app/theme/app_colors.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscure = true;
  late bool _rememberMe;

  @override
  void initState() {
    super.initState();
    final auth = AdminAuth.instance;
    _rememberMe = auth.rememberMe;
    final saved = auth.rememberedEmail;
    if (saved != null && saved.isNotEmpty) {
      _email.text = saved;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _passwordFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await AdminAuth.instance.signIn(
      email: _email.text,
      password: _password.text,
      rememberMe: _rememberMe,
    );
    // Tarayıcının şifre yöneticisine kaydetme teklifi sunması için gerekli.
    if (AdminAuth.instance.isAdmin) {
      TextInput.finishAutofillContext();
    }
  }

  void _toggleRemember(bool value) {
    setState(() => _rememberMe = value);
    AdminAuth.instance.setRememberMe(value);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AdminAuth.instance,
      builder: (context, _) {
        final auth = AdminAuth.instance;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE8F3FF),
                  Color(0xFFF5F3FF),
                  Color(0xFFFFF7ED),
                ],
              ),
            ),
            child: Center(
              child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 0,
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                  child: AutofillGroup(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'geliyor.tr',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Yönetim paneli v2',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Sipariş · Ürün · Üye · Kampanya · Banner',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.subText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'E-posta',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _password,
                          focusNode: _passwordFocus,
                          obscureText: _obscure,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Şifre',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: auth.busy
                              ? null
                              : () => _toggleRemember(!_rememberMe),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  activeColor: AppColors.primary,
                                  onChanged: auth.busy
                                      ? null
                                      : (value) =>
                                            _toggleRemember(value ?? false),
                                ),
                                const Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Beni hatırla',
                                          style: TextStyle(
                                            color: AppColors.text,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Yalnızca bu bilgisayarın bu tarayıcısında '
                                          'oturum açık kalır.',
                                          style: TextStyle(
                                            color: AppColors.subText,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (auth.error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              auth.error!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Text(
                            'Oturumun açık kalması için paneli her zaman '
                            'https://geliyortrapp.web.app adresinden açın.',
                            style: TextStyle(
                              color: AppColors.subText,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: auth.busy ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: auth.busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Giriş Yap'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        );
      },
    );
  }
}

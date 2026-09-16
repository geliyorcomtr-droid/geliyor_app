import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geliyor_app/screens/home_screen.dart';
import 'package:geliyor_app/screens/register_screen.dart';
import 'package:geliyor_app/services/user_profile_sync.dart';
import 'package:geliyor_app/state/auth_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_brand_logo.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.returnToPrevious = false,
  });

  /// Sipariş / sepet gibi bir işlemden geldiyse giriş sonrası geri döner.
  final bool returnToPrevious;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  bool _obscurePassword = true;

  bool get _isEmailEntry {
    return _identifierController.text.trim().contains('@');
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _identifierController.text.trim();
    if (phone.length < 10) {
      _showMessage('Geçerli bir telefon numarası girin.');
      return;
    }
    setState(() => _busy = true);
    try {
      await AuthStore.instance.sendCode(phone);
      if (!mounted) return;
      setState(() => _codeSent = true);
      _showMessage('Giriş kodu telefonunuza gönderildi.');
    } catch (e) {
      if (!mounted) return;
      _showMessage(AuthStore.friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finishLogin() async {
    await UserProfileSync.sync(force: true);
    if (!mounted) return;
    if (widget.returnToPrevious) {
      Navigator.of(context).pop(true);
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'home'),
        builder: (_) => const HomeScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> _loginWithEmail() async {
    final email = _identifierController.text.trim();
    final password = _passwordController.text;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showMessage('Geçerli bir e-posta adresi girin.');
      return;
    }
    if (password.trim().length < 6) {
      _showMessage('Şifrenizi girin.');
      return;
    }

    setState(() => _busy = true);
    try {
      await AuthStore.instance.signInWithEmail(
        email: email,
        password: password,
      );
      if (!mounted) return;
      await _finishLogin();
    } catch (e) {
      if (!mounted) return;
      _showMessage(AuthStore.friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _login() async {
    if (_isEmailEntry) {
      await _loginWithEmail();
      return;
    }

    final phone = _identifierController.text.trim();
    final code = _codeController.text.trim();

    if (phone.length < 10) {
      _showMessage('Geçerli bir telefon numarası veya e-posta girin.');
      return;
    }
    if (!_codeSent) {
      await _sendCode();
      return;
    }
    if (code.length < 4) {
      _showMessage('Telefonunuza gelen giriş kodunu girin.');
      return;
    }

    setState(() => _busy = true);
    try {
      await AuthStore.instance.verifyCode(
        smsCode: code,
        requireExistingUser: true,
      );
      if (!mounted) return;
      await _finishLogin();
    } catch (e) {
      if (!mounted) return;
      _showMessage(AuthStore.friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame.standard(
        backgroundColor: AppColors.background,
        activeTab: AppNavTab.profile,
        showNavbar: false,
        header: _buildHeader(context),
        content: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppPageFrame.contentHorizontalPadding,
            0,
            AppPageFrame.contentHorizontalPadding,
            10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBrand(),
              const SizedBox(height: 18),
              const Text(
                'Giriş Yap',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Telefon numaranız veya e-posta adresinizle giriş yapın',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.subText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 22),
              _fieldLabel('Telefon numarası / e-posta adresi'),
              const SizedBox(height: 6),
              _inputField(
                controller: _identifierController,
                hint: '05XX XXX XX XX veya e-posta',
                icon: _isEmailEntry
                    ? Icons.mail_outline_rounded
                    : Icons.phone_outlined,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {
                  if (_codeSent) {
                    _codeSent = false;
                    _codeController.clear();
                  }
                }),
              ),
              if (_isEmailEntry) ...[
                const SizedBox(height: 14),
                _fieldLabel('Şifre'),
                const SizedBox(height: 6),
                _inputField(
                  controller: _passwordController,
                  hint: 'Doğrulanmış e-posta şifreniz',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  keyboardType: TextInputType.visiblePassword,
                  suffix: IconButton(
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.subText,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'E-posta ile giriş için önce telefonla girip e-postanı doğrula ve şifre belirle.',
                  style: TextStyle(
                    color: AppColors.subText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 14),
                _fieldLabel('SMS Doğrulama Kodu'),
                const SizedBox(height: 6),
                _inputField(
                  controller: _codeController,
                  hint: _codeSent
                      ? 'SMS ile gelen 6 haneli kod'
                      : 'Önce kod gönderin',
                  icon: Icons.sms_outlined,
                  enabled: _codeSent && !_busy,
                  obscureText: false,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              AppPressableButton.primary(
                onTap: _busy
                    ? null
                    : (_isEmailEntry || _codeSent ? _login : _sendCode),
                enabled: !_busy,
                width: double.infinity,
                height: 48,
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEmailEntry || _codeSent ? 'Giriş Yap' : 'Kod Gönder',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Hesabınız yok mu? ',
                    style: TextStyle(
                      color: AppColors.subText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Kayıt Ol',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          const SizedBox(width: 40),
          const Spacer(),
          SizedBox(
            width: 40,
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.text,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrand() {
    return const AppBrandLogo(height: 240, errorIconSize: 48);
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    bool enabled = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffix,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(
        color: enabled ? AppColors.text : AppColors.subText,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.subText,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: AppColors.subText, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: enabled ? AppColors.surface : AppColors.selected,
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }

}

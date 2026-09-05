import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geliyor_app/screens/account_screen.dart';
import 'package:geliyor_app/screens/register_screen.dart';
import 'package:geliyor_app/services/user_profile_sync.dart';
import 'package:geliyor_app/state/auth_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
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
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
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

  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();

    if (phone.length < 10) {
      _showMessage('Geçerli bir telefon numarası girin.');
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
      await UserProfileSync.sync(force: true);
      if (!mounted) return;
      if (widget.returnToPrevious) {
        Navigator.of(context).pop(true);
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          settings: const RouteSettings(name: 'profile'),
          builder: (_) => const AccountScreen(),
        ),
        (route) => false,
      );
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
                'Telefon numaranızla giriş yapın ve alışverişe başlayın',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.subText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 22),
              _fieldLabel('Telefon Numarası'),
              const SizedBox(height: 6),
              _inputField(
                controller: _phoneController,
                hint: '05XX XXX XX XX',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                onChanged: (_) {
                  if (_codeSent) {
                    setState(() {
                      _codeSent = false;
                      _codeController.clear();
                    });
                  }
                },
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
              ),
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
              const SizedBox(height: 16),
              AppPressableButton.primary(
                onTap: _busy ? null : (_codeSent ? _login : _sendCode),
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
                        _codeSent ? 'Giriş Yap' : 'Kod Gönder',
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
    return Image.asset(
      'assets/images/geliyor_splash_logo.png',
      height: 240,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.pets_rounded, color: AppColors.primary, size: 48),
    );
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geliyor_app/screens/account_screen.dart';
import 'package:geliyor_app/screens/login_screen.dart';
import 'package:geliyor_app/services/user_profile_sync.dart';
import 'package:geliyor_app/state/auth_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();
  bool _smsCodeSent = false;
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _smsCodeController.dispose();
    super.dispose();
  }

  Future<void> _sendSmsCode() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.length < 3) {
      _showMessage('Lütfen ad soyad bilginizi girin.');
      return;
    }
    if (phone.length < 10) {
      _showMessage('Önce geçerli bir telefon numarası girin.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await AuthStore.instance.sendCode(phone);
      if (!mounted) return;
      setState(() => _smsCodeSent = true);
      _showMessage('SMS doğrulama kodu gönderildi.');
    } catch (e) {
      if (!mounted) return;
      _showMessage(AuthStore.friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final smsCode = _smsCodeController.text.trim();

    if (name.length < 3) {
      _showMessage('Lütfen ad soyad bilginizi girin.');
      return;
    }
    if (phone.length < 10) {
      _showMessage('Geçerli bir telefon numarası girin.');
      return;
    }
    if (!_smsCodeSent) {
      await _sendSmsCode();
      return;
    }
    if (smsCode.length < 4) {
      _showMessage('SMS doğrulama kodunu girin.');
      return;
    }

    setState(() => _busy = true);
    try {
      await AuthStore.instance.verifyCode(smsCode: smsCode, fullName: name);
      await UserProfileSync.sync(force: true);
      if (!mounted) return;
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
                'Kayıt Ol',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Hesap oluşturun ve alışverişe başlayın',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.subText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 22),
              _fieldLabel('İsim Soyisim'),
              const SizedBox(height: 6),
              _inputField(
                controller: _nameController,
                hint: 'Adınız Soyadınız',
                icon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 14),
              _fieldLabel('Telefon Numarası'),
              const SizedBox(height: 6),
              _inputField(
                controller: _phoneController,
                hint: '05XX XXX XX XX',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                onChanged: (_) {
                  if (_smsCodeSent) {
                    setState(() {
                      _smsCodeSent = false;
                      _smsCodeController.clear();
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
                controller: _smsCodeController,
                hint: _smsCodeSent
                    ? 'SMS ile gelen 6 haneli kod'
                    : 'Önce kod gönderin',
                icon: Icons.sms_outlined,
                enabled: _smsCodeSent && !_busy,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
              ),
              const SizedBox(height: 20),
              AppPressableButton.primary(
                onTap: _busy ? null : (_smsCodeSent ? _register : _sendSmsCode),
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
                        _smsCodeSent ? 'Kayıt Ol' : 'Kod Gönder',
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
                    'Zaten hesabınız var mı? ',
                    style: TextStyle(
                      color: AppColors.subText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      'Giriş Yap',
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
    bool enabled = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
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
        filled: true,
        fillColor: enabled ? AppColors.surface : AppColors.selected,
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
        disabledBorder: OutlineInputBorder(
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

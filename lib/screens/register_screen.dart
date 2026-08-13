import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geliyor_app/screens/account_screen.dart';
import 'package:geliyor_app/screens/login_screen.dart';
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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _smsCodeController.dispose();
    super.dispose();
  }

  void _sendSmsCode() {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      _showMessage('Önce geçerli bir telefon numarası girin.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _smsCodeSent = true);
    _showMessage('SMS doğrulama kodu gönderildi.');
  }

  void _register() {
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
      _showMessage('Lütfen önce SMS kodu gönderin.');
      return;
    }
    if (smsCode.length < 4) {
      _showMessage('SMS doğrulama kodunu girin.');
      return;
    }

    AuthStore.instance.register(fullName: name, phone: phone);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'profile'),
        builder: (_) => const AccountScreen(),
      ),
      (route) => false,
    );
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
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
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
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: AppPressableButton.primary(
                  onTap: _sendSmsCode,
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    _smsCodeSent ? 'Kodu Tekrar Gönder' : 'SMS Kodu Gönder',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (_smsCodeSent) ...[
                const SizedBox(height: 14),
                _fieldLabel('SMS Doğrulama Kodu'),
                const SizedBox(height: 6),
                _inputField(
                  controller: _smsCodeController,
                  hint: '6 haneli kod',
                  icon: Icons.sms_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              AppPressableButton.primary(
                onTap: _register,
                width: double.infinity,
                height: 48,
                child: const Text(
                  'Kayıt Ol',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _orDivider(),
              const SizedBox(height: 14),
              _socialButton(
                label: 'Apple ile Kayıt Ol',
                icon: Icons.apple,
                onTap: () => _showMessage('Apple ile kayıt yakında eklenecek.'),
              ),
              const SizedBox(height: 10),
              _socialButton(
                label: 'Google ile Kayıt Ol',
                icon: Icons.g_mobiledata_rounded,
                onTap: () => _showMessage('Google ile kayıt yakında eklenecek.'),
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
      'assets/images/geliyor_auth_logo.png',
      height: 138,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) => const Icon(
        Icons.pets_rounded,
        color: AppColors.primary,
        size: 48,
      ),
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
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      style: const TextStyle(
        color: AppColors.text,
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
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

  Widget _orDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.border, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'veya',
            style: TextStyle(
              color: AppColors.subText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.border, thickness: 1)),
      ],
    );
  }

  Widget _socialButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return AppPressableButton.outline(
      onTap: onTap,
      width: double.infinity,
      height: 46,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

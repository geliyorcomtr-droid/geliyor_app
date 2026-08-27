import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';

enum _SecuritySection { none, password, phone, email }

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  bool _editing = false;
  _SecuritySection _securitySection = _SecuritySection.none;
  String? _formError;

  final _nameController = TextEditingController(text: 'Can Dostu');
  final _emailController = TextEditingController(text: 'candostu@gmail.com');
  final _phoneController = TextEditingController(text: '+90 555 123 45 67');
  final _birthController = TextEditingController(text: '15.05.1995');
  String _gender = 'Erkek';

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _securityPhoneController = TextEditingController();
  final _securityEmailController = TextEditingController();
  final _otpController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _phoneVerified = true;
  bool _emailVerified = true;
  bool _otpSent = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _securityPhoneController.dispose();
    _securityEmailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  bool get _inSecurityFlow => _securitySection != _SecuritySection.none;

  void _toggleEdit() {
    setState(() => _editing = !_editing);
    if (!_editing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bilgilerin güncellendi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openSecurity(_SecuritySection section) {
    FocusScope.of(context).unfocus();
    setState(() {
      _securitySection = section;
      _formError = null;
      _otpSent = false;
      _otpController.clear();
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _securityPhoneController.text = _phoneController.text;
      _securityEmailController.text = _emailController.text;
    });
  }

  void _closeSecurity() {
    FocusScope.of(context).unfocus();
    setState(() {
      _securitySection = _SecuritySection.none;
      _formError = null;
      _otpSent = false;
    });
  }

  void _onBack() {
    if (_inSecurityFlow) {
      _closeSecurity();
      return;
    }
    Navigator.of(context).maybePop();
  }

  void _savePassword() {
    FocusScope.of(context).unfocus();
    final current = _currentPasswordController.text.trim();
    final next = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      setState(() => _formError = 'Lütfen tüm şifre alanlarını doldurun.');
      return;
    }
    if (next.length < 6) {
      setState(() => _formError = 'Yeni şifre en az 6 karakter olmalı.');
      return;
    }
    if (next != confirm) {
      setState(() => _formError = 'Yeni şifreler birbiriyle eşleşmiyor.');
      return;
    }

    setState(() {
      _formError = null;
      _securitySection = _SecuritySection.none;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Şifren güncellendi.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _sendOtp({required bool forPhone}) {
    FocusScope.of(context).unfocus();
    final value = forPhone
        ? _securityPhoneController.text.trim()
        : _securityEmailController.text.trim();

    if (value.isEmpty) {
      setState(() {
        _formError = forPhone
            ? 'Telefon numarası boş olamaz.'
            : 'E-posta adresi boş olamaz.';
      });
      return;
    }
    if (!forPhone && !value.contains('@')) {
      setState(() => _formError = 'Geçerli bir e-posta girin.');
      return;
    }

    setState(() {
      _formError = null;
      _otpSent = true;
      _otpController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          forPhone
              ? 'Doğrulama kodu telefonuna gönderildi.'
              : 'Doğrulama kodu e-postana gönderildi.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _verifyOtp({required bool forPhone}) {
    FocusScope.of(context).unfocus();
    final code = _otpController.text.trim();
    if (code.length < 4) {
      setState(() => _formError = 'Doğrulama kodunu girin.');
      return;
    }

    setState(() {
      _formError = null;
      if (forPhone) {
        _phoneController.text = _securityPhoneController.text.trim();
        _phoneVerified = true;
      } else {
        _emailController.text = _securityEmailController.text.trim();
        _emailVerified = true;
      }
      _securitySection = _SecuritySection.none;
      _otpSent = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          forPhone
              ? 'Telefon numaran doğrulandı.'
              : 'E-posta adresin doğrulandı.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_inSecurityFlow,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _inSecurityFlow) _closeSecurity();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: AppPageFrame.standard(
          backgroundColor: AppColors.background,
          activeTab: AppNavTab.profile,
          header: _buildHeader(),
          content: _inSecurityFlow
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppPageFrame.contentHorizontalPadding,
                    0,
                    AppPageFrame.contentHorizontalPadding,
                    8,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          child: _buildSecurityFlow(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSecurityActions(),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppPageFrame.contentHorizontalPadding,
                    0,
                    AppPageFrame.contentHorizontalPadding,
                    8,
                  ),
                  child: Column(
                    children: [
                      _buildProfileSummary(),
                      const SizedBox(height: 10),
                      _buildPersonalInfoCard(),
                      const SizedBox(height: 10),
                      _buildSecurityCard(),
                    ],
                  ),
                ),
          navbar: const AppBottomNavbar(activeTab: AppNavTab.profile),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final title = switch (_securitySection) {
      _SecuritySection.password => 'Şifre Güncelle',
      _SecuritySection.phone => 'Telefon Doğrulama',
      _SecuritySection.email => 'E-posta Doğrulama',
      _SecuritySection.none => 'Kişisel Bilgilerim',
    };
    final subtitle = switch (_securitySection) {
      _SecuritySection.password => 'Hesabını korumak için şifreni yenile.',
      _SecuritySection.phone => 'Telefon numaranı güncelle ve doğrula.',
      _SecuritySection.email => 'E-posta adresini güncelle ve doğrula.',
      _SecuritySection.none => 'Hesap bilgilerini görüntüle ve düzenle.',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          AppBackButton(onPressed: _onBack),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.pageHeader,
                ),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.subText.withValues(alpha: 0.95),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const AppNotificationButton(badgeColor: AppColors.error),
        ],
      ),
    );
  }

  Widget _buildProfileSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.selected,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/luna_kopek.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.surface,
                      child: const Icon(
                        Icons.pets_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: const Icon(
                    Icons.photo_camera_rounded,
                    color: AppColors.surface,
                    size: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _emailController.text,
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 11,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Doğrulanmış Hesap',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kişisel Bilgiler',
            style: AppTextStyles.sectionHeader,
          ),
          const SizedBox(height: 10),
          _buildField(
            label: 'Ad Soyad',
            icon: Icons.person_outline_rounded,
            controller: _nameController,
          ),
          const SizedBox(height: 8),
          _buildField(
            label: 'E-posta',
            icon: Icons.mail_outline_rounded,
            controller: _emailController,
          ),
          const SizedBox(height: 8),
          _buildField(
            label: 'Telefon Numarası',
            icon: Icons.phone_outlined,
            controller: _phoneController,
            trailing: _verifiedBadge('Doğrulanmış'),
          ),
          const SizedBox(height: 8),
          _buildField(
            label: 'Doğum Tarihi',
            icon: Icons.calendar_today_outlined,
            controller: _birthController,
            trailing: const Icon(
              Icons.calendar_month_outlined,
              color: AppColors.primary,
              size: 16,
            ),
          ),
          const SizedBox(height: 8),
          _buildGenderField(),
          const SizedBox(height: 12),
          AppPressableButton.primary(
            onTap: _toggleEdit,
            width: double.infinity,
            height: 40,
            padding: EdgeInsets.zero,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _editing ? Icons.check_rounded : Icons.edit_outlined,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _editing ? 'Kaydet' : 'Bilgileri Düzenle',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: _editing,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cinsiyet',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _editing
                    ? DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _gender,
                          isExpanded: true,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Erkek',
                              child: Text('Erkek'),
                            ),
                            DropdownMenuItem(
                              value: 'Kadın',
                              child: Text('Kadın'),
                            ),
                            DropdownMenuItem(
                              value: 'Belirtmek istemiyorum',
                              child: Text('Belirtmek istemiyorum'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _gender = value);
                          },
                        ),
                      )
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _gender,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Güvenlik Bilgileri',
            style: AppTextStyles.sectionHeader,
          ),
          const SizedBox(height: 4),
          _buildSecurityRow(
            icon: Icons.lock_outline_rounded,
            title: 'Şifre',
            subtitle: 'Şifreni güncelle ve hesabını koru.',
            onTap: () => _openSecurity(_SecuritySection.password),
          ),
          _buildSecurityRow(
            icon: Icons.phone_android_outlined,
            title: 'Telefon Doğrulama',
            subtitle: _phoneVerified
                ? 'Telefon numaran doğrulanmış.'
                : 'Telefon numaranı doğrula.',
            verified: _phoneVerified,
            onTap: () => _openSecurity(_SecuritySection.phone),
          ),
          _buildSecurityRow(
            icon: Icons.mail_outline_rounded,
            title: 'E-posta Doğrulama',
            subtitle: _emailVerified
                ? 'E-posta adresin doğrulanmış.'
                : 'E-posta adresini doğrula.',
            verified: _emailVerified,
            onTap: () => _openSecurity(_SecuritySection.email),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool verified = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.selected,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(icon, color: AppColors.primary, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.subText,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (verified) _verifiedBadge('Doğrulandı'),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.subText.withValues(alpha: 0.7),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityFlow() {
    return switch (_securitySection) {
      _SecuritySection.password => _buildPasswordForm(),
      _SecuritySection.phone => _buildContactVerifyForm(forPhone: true),
      _SecuritySection.email => _buildContactVerifyForm(forPhone: false),
      _SecuritySection.none => const SizedBox.shrink(),
    };
  }

  Widget _buildPasswordForm() {
    return _buildFormCard(
      children: [
        _buildSecureField(
          label: 'Mevcut Şifre',
          controller: _currentPasswordController,
          obscure: _obscureCurrent,
          onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
        ),
        const SizedBox(height: 10),
        _buildSecureField(
          label: 'Yeni Şifre',
          controller: _newPasswordController,
          obscure: _obscureNew,
          onToggle: () => setState(() => _obscureNew = !_obscureNew),
        ),
        const SizedBox(height: 10),
        _buildSecureField(
          label: 'Yeni Şifre (Tekrar)',
          controller: _confirmPasswordController,
          obscure: _obscureConfirm,
          onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
        if (_formError != null) ...[
          const SizedBox(height: 10),
          Text(
            _formError!,
            style: const TextStyle(
              color: AppColors.error,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContactVerifyForm({required bool forPhone}) {
    final controller = forPhone
        ? _securityPhoneController
        : _securityEmailController;
    return _buildFormCard(
      children: [
        _buildPlainField(
          label: forPhone ? 'Telefon Numarası' : 'E-posta Adresi',
          controller: controller,
          keyboardType: forPhone
              ? TextInputType.phone
              : TextInputType.emailAddress,
          icon: forPhone ? Icons.phone_outlined : Icons.mail_outline_rounded,
        ),
        if (_otpSent) ...[
          const SizedBox(height: 10),
          _buildPlainField(
            label: 'Doğrulama Kodu',
            controller: _otpController,
            keyboardType: TextInputType.number,
            icon: Icons.pin_outlined,
          ),
        ],
        if (_formError != null) ...[
          const SizedBox(height: 10),
          Text(
            _formError!,
            style: const TextStyle(
              color: AppColors.error,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFormCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSecurityActions() {
    return Row(
      children: [
        Expanded(
          child: AppPressableButton(
            onTap: _closeSecurity,
            height: 42,
            padding: EdgeInsets.zero,
            backgroundColor: AppColors.surface,
            pressedBackgroundColor: AppColors.selected,
            borderColor: AppColors.border,
            pressedBorderColor: AppColors.primaryLight,
            child: const Text(
              'İptal',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: AppPressableButton.primary(
            onTap: () {
              switch (_securitySection) {
                case _SecuritySection.password:
                  _savePassword();
                case _SecuritySection.phone:
                  if (_otpSent) {
                    _verifyOtp(forPhone: true);
                  } else {
                    _sendOtp(forPhone: true);
                  }
                case _SecuritySection.email:
                  if (_otpSent) {
                    _verifyOtp(forPhone: false);
                  } else {
                    _sendOtp(forPhone: false);
                  }
                case _SecuritySection.none:
                  break;
              }
            },
            height: 42,
            padding: EdgeInsets.zero,
            child: Text(
              switch (_securitySection) {
                _SecuritySection.password => 'Şifreyi Güncelle',
                _SecuritySection.phone ||
                _SecuritySection.email => _otpSent ? 'Doğrula' : 'Kod Gönder',
                _SecuritySection.none => 'Kaydet',
              },
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecureField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onToggle,
                child: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.subText,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlainField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _verifiedBadge(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.selected,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 10,
            color: AppColors.primary,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

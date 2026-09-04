import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geliyor_app/state/auth_store.dart';
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

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthController = TextEditingController();
  String _gender = 'Belirtmek istemiyorum';

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _securityPhoneController = TextEditingController();
  final _securityEmailController = TextEditingController();
  final _otpController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _otpSent = false;

  bool get _phoneVerified => AuthStore.instance.isPhoneVerified;
  bool get _emailVerified => AuthStore.instance.isEmailVerified;

  @override
  void initState() {
    super.initState();
    _fillFromAuth();
    AuthStore.instance.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    if (_editing) return;
    _fillFromAuth();
    if (mounted) setState(() {});
  }

  void _fillFromAuth() {
    final auth = AuthStore.instance;
    final name = auth.fullName.trim();
    _nameController.text = name.isEmpty || name.toLowerCase() == 'üye'
        ? ''
        : name;
    _emailController.text = auth.email.trim();
    _phoneController.text = _formatPhone(auth.phone);
    _birthController.text = auth.birthDate.trim();
    final gender = auth.gender.trim();
    _gender = switch (gender) {
      'Erkek' || 'Kadın' || 'Belirtmek istemiyorum' => gender,
      _ => 'Belirtmek istemiyorum',
    };
  }

  String _formatPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('90')) {
      return '+90 ${digits.substring(2, 5)} ${digits.substring(5, 8)} ${digits.substring(8, 10)} ${digits.substring(10)}';
    }
    if (digits.length == 10) {
      return '+90 ${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 8)} ${digits.substring(8)}';
    }
    return raw.trim();
  }

  @override
  void dispose() {
    AuthStore.instance.removeListener(_onAuthChanged);
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

  Future<void> _toggleEdit() async {
    if (_editing) {
      FocusScope.of(context).unfocus();
      await AuthStore.instance.updateProfile(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        birthDate: _birthController.text.trim(),
        gender: _gender,
      );
      if (!mounted) return;
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bilgilerin güncellendi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _editing = true);
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

  Future<void> _sendOtp({required bool forPhone}) async {
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
    if (!forPhone &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
      setState(() => _formError = 'Geçerli bir e-posta girin.');
      return;
    }

    if (!forPhone) {
      try {
        await AuthStore.instance.sendEmailCode(value);
      } catch (error) {
        if (!mounted) return;
        setState(() => _formError = AuthStore.friendlyError(error));
        return;
      }
      if (!mounted) return;
    }

    setState(() {
      _formError = null;
      _otpSent = true;
      _otpController.clear();
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          forPhone
              ? 'Doğrulama kodu telefonuna gönderildi.'
              : 'Doğrulama kodu e-posta adresine gönderildi.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _verifyOtp({required bool forPhone}) async {
    FocusScope.of(context).unfocus();
    final code = _otpController.text.trim();
    if (code.length < 4) {
      setState(() => _formError = 'Doğrulama kodunu girin.');
      return;
    }

    if (!forPhone) {
      try {
        await AuthStore.instance.verifyEmailCode(
          email: _securityEmailController.text.trim(),
          code: code,
        );
      } catch (error) {
        if (!mounted) return;
        setState(() => _formError = AuthStore.friendlyError(error));
        return;
      }
      if (!mounted) return;
    }

    setState(() {
      _formError = null;
      if (forPhone) {
        _phoneController.text = _securityPhoneController.text.trim();
      } else {
        _emailController.text = _securityEmailController.text.trim();
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
            subtitle: 'Giriş telefon ve SMS kodu ile yapılır. Şifre kullanılmaz.',
            enabled: false,
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
                : _emailController.text.trim().isEmpty
                    ? 'E-posta adresini ekle ve doğrula.'
                    : 'E-posta adresin henüz doğrulanmadı.',
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
    VoidCallback? onTap,
    bool verified = false,
    bool enabled = true,
  }) {
    final canTap = enabled && onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canTap ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: enabled ? AppColors.selected : AppColors.background,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  icon,
                  color: enabled ? AppColors.primary : AppColors.subText,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: enabled ? AppColors.text : AppColors.subText,
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
              if (!enabled)
                _statusBadge('Kullanılmaz')
              else
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
          if (!forPhone) ...[
            const SizedBox(height: 8),
            const Text(
              '6 haneli kod yazdığın e-posta adresine gider. Gelen kutunu ve spam klasörünü kontrol et.',
              style: TextStyle(
                color: AppColors.subText,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
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
    return ListenableBuilder(
      listenable: AuthStore.instance,
      builder: (context, _) {
        final busy = AuthStore.instance.isBusy;
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
            enabled: !busy,
            onTap: busy
                ? null
                : () {
                    switch (_securitySection) {
                      case _SecuritySection.password:
                        _savePassword();
                      case _SecuritySection.phone:
                        if (_otpSent) {
                          unawaited(_verifyOtp(forPhone: true));
                        } else {
                          unawaited(_sendOtp(forPhone: true));
                        }
                      case _SecuritySection.email:
                        if (_otpSent) {
                          unawaited(_verifyOtp(forPhone: false));
                        } else {
                          unawaited(_sendOtp(forPhone: false));
                        }
                      case _SecuritySection.none:
                        break;
                    }
                  },
            height: 42,
            padding: EdgeInsets.zero,
            child: Text(
              busy
                  ? 'Gönderiliyor...'
                  : switch (_securitySection) {
                      _SecuritySection.password => 'Şifreyi Güncelle',
                      _SecuritySection.phone ||
                      _SecuritySection.email =>
                        _otpSent ? 'Doğrula' : 'Kod Gönder',
                      _SecuritySection.none => 'Kaydet',
                    },
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
      },
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
    return _statusBadge(
      label,
      icon: Icons.check_circle_rounded,
      color: AppColors.primary,
    );
  }

  Widget _statusBadge(
    String label, {
    IconData? icon,
    Color color = AppColors.subText,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

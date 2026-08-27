import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';

enum _PrivacyTopic {
  none,
  personalData,
  dataSecurity,
  cookies,
  disclosure,
  changePassword,
  sessions,
}

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _loginNotifications = true;
  bool _twoFactorEnabled = false;
  _PrivacyTopic _topic = _PrivacyTopic.none;
  String? _formError;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  final List<_SessionItem> _sessions = [
    const _SessionItem(
      id: 'this',
      device: 'Bu Cihaz',
      detail: 'Android • İstanbul',
      lastActive: 'Şu an aktif',
      isCurrent: true,
    ),
    const _SessionItem(
      id: 'web',
      device: 'Chrome (Windows)',
      detail: 'Web • İstanbul',
      lastActive: '2 saat önce',
    ),
  ];

  bool get _inDetail => _topic != _PrivacyTopic.none;
  bool get _isInteractiveDetail =>
      _topic == _PrivacyTopic.changePassword ||
      _topic == _PrivacyTopic.sessions;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _openTopic(_PrivacyTopic topic) {
    setState(() {
      _topic = topic;
      _formError = null;
      if (topic == _PrivacyTopic.changePassword) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    });
  }

  void _closeTopic() {
    FocusScope.of(context).unfocus();
    setState(() {
      _topic = _PrivacyTopic.none;
      _formError = null;
    });
  }

  void _onBack() {
    if (_inDetail) {
      _closeTopic();
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
      _topic = _PrivacyTopic.none;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Şifreniz güncellendi.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _endSession(String id) {
    setState(() {
      _sessions.removeWhere((s) => s.id == id && !s.isCurrent);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Oturum sonlandırıldı.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _endOtherSessions() {
    setState(() {
      _sessions.removeWhere((s) => !s.isCurrent);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Diğer oturumlar sonlandırıldı.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_inDetail,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _inDetail) _closeTopic();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: AppPageFrame.standard(
          backgroundColor: AppColors.background,
          activeTab: AppNavTab.profile,
          header: _buildHeader(),
          content: _inDetail
              ? (_isInteractiveDetail
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
                                child: _topic == _PrivacyTopic.changePassword
                                    ? _buildPasswordForm()
                                    : _buildSessionsView(),
                              ),
                            ),
                            if (_topic == _PrivacyTopic.changePassword) ...[
                              const SizedBox(height: 8),
                              _buildPasswordActions(),
                            ],
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
                        child: _buildTopicDetail(),
                      ))
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppPageFrame.contentHorizontalPadding,
                    0,
                    AppPageFrame.contentHorizontalPadding,
                    8,
                  ),
                  child: _buildMainContent(),
                ),
          navbar: const AppBottomNavbar(activeTab: AppNavTab.profile),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopBanner(),
        const SizedBox(height: 12),
        const Text(
          'Veri Gizliliğimiz',
          style: TextStyle(
            color: AppColors.subText,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        _buildPrivacyCard(),
        const SizedBox(height: 12),
        const Text(
          'Hesap Güvenliği',
          style: TextStyle(
            color: AppColors.subText,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        _buildSecurityCard(),
        const SizedBox(height: 12),
        _buildTrustBanner(),
      ],
    );
  }

  Widget _buildHeader() {
    final title = switch (_topic) {
      _PrivacyTopic.personalData => 'Kişisel Verilerin Korunması',
      _PrivacyTopic.dataSecurity => 'Veri Güvenliği',
      _PrivacyTopic.cookies => 'Çerez Politikası',
      _PrivacyTopic.disclosure => 'Aydınlatma Metni',
      _PrivacyTopic.changePassword => 'Şifre Değiştir',
      _PrivacyTopic.sessions => 'Oturum Yönetimi',
      _PrivacyTopic.none => 'Gizlilik ve Güvenlik',
    };
    final subtitle = switch (_topic) {
      _PrivacyTopic.none =>
        'Kişisel verilerinizin güvenliği bizim için önceliklidir',
      _PrivacyTopic.changePassword =>
        'Hesap şifrenizi güvenli şekilde güncelleyin',
      _PrivacyTopic.sessions => 'Aktif cihazları görüntüleyin ve yönetin',
      _ => 'Standart bilgilendirme metni',
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.subText.withValues(alpha: 0.95),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
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

  Widget _buildTopBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.selected,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -2,
            bottom: -8,
            child: Icon(
              Icons.pets_rounded,
              size: 48,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Güvenliğiniz Bizim Önceliğimiz',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Verileriniz yüksek güvenlik standartlarıyla korunur. Ayarlarınızı istediğiniz zaman güncelleyebilirsiniz.',
                      style: TextStyle(
                        color: AppColors.subText,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard() {
    final items = [
      (
        _PrivacyTopic.personalData,
        const _MenuRowData(
          icon: Icons.person_outline_rounded,
          title: 'Kişisel Verilerin Korunması',
          subtitle: 'KVKK kapsamında veri işleme ilkelerimiz',
        ),
      ),
      (
        _PrivacyTopic.dataSecurity,
        const _MenuRowData(
          icon: Icons.admin_panel_settings_outlined,
          title: 'Veri Güvenliği',
          subtitle: 'Verilerinizin nasıl korunduğunu öğrenin',
        ),
      ),
      (
        _PrivacyTopic.cookies,
        const _MenuRowData(
          icon: Icons.cookie_outlined,
          title: 'Çerez Politikası',
          subtitle: 'Çerez kullanımı ve tercih yönetimi',
        ),
      ),
      (
        _PrivacyTopic.disclosure,
        const _MenuRowData(
          icon: Icons.description_outlined,
          title: 'Aydınlatma Metni',
          subtitle: 'Kişisel verilerin işlenmesine ilişkin bilgilendirme',
        ),
      ),
    ];

    return _buildGroupedCard(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _buildNavRow(items[i].$2, onTap: () => _openTopic(items[i].$1)),
          if (i != items.length - 1) _buildDivider(),
        ],
      ],
    );
  }

  Widget _buildTopicDetail() {
    final sections = switch (_topic) {
      _PrivacyTopic.personalData => _personalDataSections,
      _PrivacyTopic.dataSecurity => _dataSecuritySections,
      _PrivacyTopic.cookies => _cookieSections,
      _PrivacyTopic.disclosure => _disclosureSections,
      _PrivacyTopic.changePassword ||
      _PrivacyTopic.sessions ||
      _PrivacyTopic.none => const <_InfoSection>[],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < sections.length; i++) ...[
                if (i > 0) const SizedBox(height: 14),
                Text(
                  sections[i].title,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  sections[i].body,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.selected,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bu metin bilgilendirme amaçlıdır. Güncel yasal metinler için destek ekibimizle iletişime geçebilirsiniz.',
                  style: TextStyle(
                    color: AppColors.subText,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static const _personalDataSections = [
    _InfoSection(
      title: '1. Veri Sorumlusu',
      body:
          'geliyor.tr olarak kişisel verilerinizi 6698 sayılı Kişisel Verilerin Korunması Kanunu (KVKK) kapsamında işleriz. Veri sorumlusu sıfatıyla verilerinizin hukuka uygun, dürüst ve şeffaf şekilde işlenmesini sağlarız.',
    ),
    _InfoSection(
      title: '2. İşlenen Veri Kategorileri',
      body:
          'Kimlik (ad soyad), iletişim (telefon, e-posta), adres, hesap bilgileri, sipariş ve ödeme kayıtları, cihaz/oturum bilgileri ile uygulama kullanım verileri işlenebilir.',
    ),
    _InfoSection(
      title: '3. İşleme Amaçları',
      body:
          'Hesap oluşturma, sipariş ve teslimat, müşteri destek, güvenlik, yasal yükümlülükler, kişiselleştirilmiş öneriler ve hizmet kalitesinin iyileştirilmesi amacıyla verileriniz işlenir.',
    ),
    _InfoSection(
      title: '4. Haklarınız',
      body:
          'KVKK m.11 kapsamında verilerinizin işlenip işlenmediğini öğrenme, düzeltme, silme, itiraz etme ve şikayette bulunma haklarına sahipsiniz. Taleplerinizi hesap ayarlarından veya destek kanalından iletebilirsiniz.',
    ),
  ];

  static const _dataSecuritySections = [
    _InfoSection(
      title: '1. Teknik Tedbirler',
      body:
          'Verileriniz iletim sırasında SSL/TLS şifreleme ile korunur. Yetkisiz erişimi engellemek için erişim kontrolü, güncel güvenlik yamaları ve izleme mekanizmaları uygulanır.',
    ),
    _InfoSection(
      title: '2. İdari Tedbirler',
      body:
          'Verilere yalnızca yetkili personel erişebilir. Personel gizlilik taahhütleri ve düzenli güvenlik farkındalık süreçleri uygulanır. Veri işleme faaliyetleri kayıt altına alınır.',
    ),
    _InfoSection(
      title: '3. Saklama Süresi',
      body:
          'Kişisel verileriniz, işleme amacının gerektirdiği süre ve ilgili mevzuatta öngörülen zamanaşımı süreleri boyunca saklanır. Süre sonunda silinir, yok edilir veya anonim hale getirilir.',
    ),
    _InfoSection(
      title: '4. İhlal Bildirimi',
      body:
          'Veri ihlali durumunda yasal yükümlülüklerimize uygun şekilde ilgili mercilere ve gerektiğinde kullanıcılara bildirim yapılır. Güvenlik olayları kayıt altına alınarak incelenir.',
    ),
  ];

  static const _cookieSections = [
    _InfoSection(
      title: '1. Çerez Nedir?',
      body:
          'Çerezler; uygulamada oturumunuzu sürdürmek, tercihlerinizi hatırlamak ve hizmeti güvenli/performanslı sunmak için kullanılan küçük veri kayıtlarıdır.',
    ),
    _InfoSection(
      title: '2. Kullandığımız Çerez Türleri',
      body:
          'Zorunlu çerezler (giriş ve güvenlik), işlevsel çerezler (dil/tercih), performans çerezleri (hata ve kullanım analizi) kullanılabilir. Pazarlama çerezleri yalnızca açık rızanızla işlenir.',
    ),
    _InfoSection(
      title: '3. Tercih Yönetimi',
      body:
          'Zorunlu olmayan çerezleri cihaz ve uygulama ayarlarından sınırlayabilirsiniz. Bazı tercihleri kapatmanız halinde bazı özellikler sınırlı çalışabilir.',
    ),
    _InfoSection(
      title: '4. Üçüncü Taraflar',
      body:
          'Ödeme, analitik veya bildirim servisleri kendi çerezlerini kullanabilir. Bu tarafların gizlilik politikaları kendi sorumluluklarındadır; mümkün olduğunca sözleşmesel güvenceler alınır.',
    ),
  ];

  static const _disclosureSections = [
    _InfoSection(
      title: '1. Aydınlatma Yükümlülüğü',
      body:
          'KVKK m.10 uyarınca; veri sorumlusunun kimliği, işleme amaçları, aktarım yapılan taraflar, toplama yöntemi, hukuki sebepler ve haklarınız hakkında sizi bilgilendiririz.',
    ),
    _InfoSection(
      title: '2. Hukuki Sebepler',
      body:
          'Verileriniz; sözleşmenin kurulması/ifası, hukuki yükümlülük, meşru menfaat ve gerektiğinde açık rıza hukuki sebeplerine dayanılarak işlenir.',
    ),
    _InfoSection(
      title: '3. Veri Aktarımı',
      body:
          'Sipariş teslimatı, ödeme altyapısı, bulut barındırma ve destek süreçleri için hizmet aldığımız iş ortaklarına, yalnızca gerekli ölçüde ve güvenli kanallarla veri aktarılabilir.',
    ),
    _InfoSection(
      title: '4. İletişim',
      body:
          'Aydınlatma metni ve KVKK talepleriniz için Hesabım > Destek üzerinden veya uygulama içi yardım kanallarından bize ulaşabilirsiniz. Talepleriniz makul sürede yanıtlanır.',
    ),
  ];

  Widget _buildSecurityCard() {
    return _buildGroupedCard(
      children: [
        _buildNavRow(
          const _MenuRowData(
            icon: Icons.lock_outline_rounded,
            title: 'Şifre Değiştir',
            subtitle: 'Hesap şifrenizi güvenli şekilde güncelleyin',
          ),
          onTap: () => _openTopic(_PrivacyTopic.changePassword),
        ),
        _buildDivider(),
        _buildNavRow(
          const _MenuRowData(
            icon: Icons.phone_iphone_rounded,
            title: 'Oturum Yönetimi',
            subtitle: 'Cihazlarınızı ve aktif oturumları yönetin',
          ),
          onTap: () => _openTopic(_PrivacyTopic.sessions),
          trailing: Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.selected,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '${_sessions.length} aktif oturum',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        _buildDivider(),
        _buildToggleRow(
          icon: Icons.notifications_none_rounded,
          title: 'Giriş Bildirimleri',
          subtitle: 'Yeni cihazdan giriş yapıldığında bilgilendirilin',
          value: _loginNotifications,
          onChanged: (value) {
            setState(() => _loginNotifications = value);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  value
                      ? 'Giriş bildirimleri açıldı.'
                      : 'Giriş bildirimleri kapatıldı.',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        _buildDivider(),
        _buildToggleRow(
          icon: Icons.verified_user_outlined,
          title: 'İki Adımlı Doğrulama',
          subtitle: 'Hesabınıza ekstra güvenlik katmanı ekleyin',
          value: _twoFactorEnabled,
          onChanged: (value) {
            setState(() => _twoFactorEnabled = value);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  value
                      ? 'İki adımlı doğrulama açıldı.'
                      : 'İki adımlı doğrulama kapatıldı.',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        _buildDivider(),
        _buildNavRow(
          const _MenuRowData(
            icon: Icons.delete_outline_rounded,
            title: 'Hesabımı Sil',
            subtitle: 'Hesabınızı ve verilerinizi kalıcı olarak silin',
            isDestructive: true,
          ),
          onTap: _confirmDeleteAccount,
        ),
      ],
    );
  }

  Widget _buildPasswordForm() {
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
      ),
    );
  }

  Widget _buildPasswordActions() {
    return Row(
      children: [
        Expanded(
          child: AppPressableButton(
            onTap: _closeTopic,
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
            onTap: _savePassword,
            height: 42,
            padding: EdgeInsets.zero,
            child: const Text(
              'Şifreyi Güncelle',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (int i = 0; i < _sessions.length; i++) ...[
                _buildSessionRow(_sessions[i]),
                if (i != _sessions.length - 1) _buildDivider(),
              ],
            ],
          ),
        ),
        if (_sessions.any((s) => !s.isCurrent)) ...[
          const SizedBox(height: 12),
          AppPressableButton.primary(
            onTap: _endOtherSessions,
            width: double.infinity,
            height: 42,
            padding: EdgeInsets.zero,
            child: const Text(
              'Diğer Oturumları Sonlandır',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSessionRow(_SessionItem session) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.selected,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              session.isCurrent
                  ? Icons.smartphone_rounded
                  : Icons.laptop_mac_rounded,
              color: AppColors.primary,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.device,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${session.detail} • ${session.lastActive}',
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (session.isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.selected,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'Bu cihaz',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => _endSession(session.id),
              child: const Text(
                'Çıkış',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
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

  Widget _buildGroupedCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
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
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 54,
      endIndent: 14,
      color: AppColors.border.withValues(alpha: 0.7),
    );
  }

  Widget _buildNavRow(
    _MenuRowData item, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final color = item.isDestructive ? AppColors.error : AppColors.text;
    final iconColor = item.isDestructive ? AppColors.error : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {},
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: item.isDestructive
                      ? AppColors.error.withValues(alpha: 0.08)
                      : AppColors.selected,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(item.icon, color: iconColor, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        color: AppColors.subText,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
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

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.selected,
              borderRadius: BorderRadius.circular(18),
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.78,
            child: Switch.adaptive(
              value: value,
              activeTrackColor: AppColors.primary,
              activeThumbColor: AppColors.surface,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBanner() {
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.workspace_premium_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '%100 Güvenli Alışveriş',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Ödeme ve hesap işlemleriniz 256-bit SSL şifreleme ile korunur.',
                  style: TextStyle(
                    color: AppColors.subText,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.shield_rounded,
                  color: AppColors.primary.withValues(alpha: 0.85),
                  size: 28,
                ),
                const Positioned(
                  child: Icon(
                    Icons.lock_rounded,
                    color: AppColors.surface,
                    size: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppPageFrame.width),
            child: Material(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.error,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hesabınızı silmek istediğinize emin misiniz?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Bu işlem geri alınamaz. Sipariş geçmişiniz ve kayıtlı verileriniz silinir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.subText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: const Text('Vazgeç'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Hesap silme talebi alındı. Destek ekibi sizinle iletişime geçecek.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: AppColors.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: const Text('Hesabı Sil'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoSection {
  const _InfoSection({required this.title, required this.body});

  final String title;
  final String body;
}

class _SessionItem {
  const _SessionItem({
    required this.id,
    required this.device,
    required this.detail,
    required this.lastActive,
    this.isCurrent = false,
  });

  final String id;
  final String device;
  final String detail;
  final String lastActive;
  final bool isCurrent;
}

class _MenuRowData {
  const _MenuRowData({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDestructive;
}

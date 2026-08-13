import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:flutter/services.dart';
import 'package:geliyor_app/screens/smart_plan_screen.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';

class CampaignsPointsScreen extends StatefulWidget {
  const CampaignsPointsScreen({super.key});

  @override
  State<CampaignsPointsScreen> createState() => _CampaignsPointsScreenState();
}

class _CampaignsPointsScreenState extends State<CampaignsPointsScreen> {
  static const int _points = 1250;
  static const String _referralCode = 'GELIYOR100';

  bool _inviteOpen = false;
  bool _inviteSuccess = false;
  _InviteChannel _inviteChannel = _InviteChannel.phone;
  final TextEditingController _inviteController = TextEditingController();
  String? _inviteError;

  static const List<_RewardProduct> _rewards = [
    _RewardProduct(
      name: 'Renkli İp Oyuncak',
      points: '500 Puan',
      imagePath: 'assets/images/mama_kabi.png',
    ),
    _RewardProduct(
      name: 'Somonlu Konserve',
      points: '750 Puan',
      imagePath: 'assets/images/app_ikonlar/somon.png',
    ),
    _RewardProduct(
      name: 'Doğal Ödül Maması',
      points: '1000 Puan',
      imagePath: 'assets/images/app_ikonlar/dogal_icerik.png',
    ),
  ];

  static const List<_TierInfo> _tiers = [
    _TierInfo(
      name: 'Bronz Dost',
      range: '1 - 1.999 Puan',
      color: Color(0xFFCD7F32),
      imagePath: 'assets/images/son_ikonlar/kampanya_bronz_dost.png',
      isCurrent: true,
    ),
    _TierInfo(
      name: 'Gold Dost',
      range: '2.000 - 4.999 Puan',
      color: Color(0xFFF59E0B),
      imagePath: 'assets/images/son_ikonlar/kampanya_altin_dost.png',
      isLocked: true,
    ),
    _TierInfo(
      name: 'Premium Dost',
      range: '5.000+ Puan',
      color: Color(0xFF60A5FA),
      imagePath: 'assets/images/son_ikonlar/kampanya_premium_dost.png',
      isLocked: true,
    ),
  ];

  @override
  void dispose() {
    _inviteController.dispose();
    super.dispose();
  }

  void _copyReferralCode() {
    Clipboard.setData(const ClipboardData(text: _referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Davet kodu kopyalandı.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openSmartPlan() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SmartPlanScreen()),
    );
  }

  void _openInviteForm() {
    setState(() {
      _inviteOpen = true;
      _inviteSuccess = false;
      _inviteError = null;
      _inviteController.clear();
      _inviteChannel = _InviteChannel.phone;
    });
  }

  void _closeInviteForm() {
    setState(() {
      _inviteOpen = false;
      _inviteSuccess = false;
      _inviteError = null;
      _inviteController.clear();
    });
  }

  void _submitInvite() {
    final value = _inviteController.text.trim();
    if (value.isEmpty) {
      setState(() {
        _inviteError = _inviteChannel == _InviteChannel.phone
            ? 'Telefon numarası girin.'
            : 'E-posta adresi girin.';
      });
      return;
    }

    if (_inviteChannel == _InviteChannel.email) {
      final emailOk = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
      if (!emailOk) {
        setState(() => _inviteError = 'Geçerli bir e-posta girin.');
        return;
      }
    } else {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 10) {
        setState(() => _inviteError = 'Geçerli bir telefon numarası girin.');
        return;
      }
    }

    setState(() {
      _inviteError = null;
      _inviteSuccess = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame.standard(
        backgroundColor: AppColors.background,
        activeTab: AppNavTab.campaigns,
        header: _buildHeader(context),
        content: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBanner(),
              const SizedBox(height: 12),
              _buildGiftSection(context),
              const SizedBox(height: 10),
              _buildGiftActions(context),
              const SizedBox(height: 12),
              _buildReferralCard(context),
              const SizedBox(height: 14),
              _buildRewardsSection(context),
              const SizedBox(height: 14),
              _buildTiersSection(),
            ],
          ),
        ),
        navbar: const AppBottomNavbar(activeTab: AppNavTab.campaigns),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const AppBackButton(),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Kampanyalar & Kuponlar',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.pageHeader,
                ),
                const SizedBox(height: 2),
                Text(
                  'Dostun için alışveriş yap, puan kazan, ödülleri kaçırma!',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.subText.withValues(alpha: 0.95),
                    fontSize: 8.5,
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

  Widget _buildBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.asset(
        'assets/images/kampanya_puan_banner.png',
        width: double.infinity,
        height: 150,
        fit: BoxFit.cover,
        cacheWidth: 800,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 150,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Merhaba, Can Dostu! 👋',
                style: TextStyle(
                  color: AppColors.surface,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Toplam Dost Puanın',
                style: TextStyle(
                  color: AppColors.surface,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$_points',
                style: const TextStyle(
                  color: AppColors.surface,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGiftSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dost Hediyeni Sen Seç 🎁',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Puanlarını dilediğin gibi değerlendir!',
          style: TextStyle(
            color: AppColors.subText.withValues(alpha: 0.95),
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _GiftOptionCard(
                imagePath: 'assets/images/son_ikonlar/kampanya_2kat_odul.png',
                title: '2 Kat Ödül',
                subtitle: 'Bu ürünlerde puanların 2 katına çıkar!',
                onTap: () {},
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GiftOptionCard(
                imagePath: 'assets/images/son_ikonlar/kampanya_indirim_kupon.png',
                title: 'İndirim Kuponu',
                subtitle: 'Sana özel indirim kuponu kazan!',
                onTap: () {},
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GiftOptionCard(
                imagePath: 'assets/images/son_ikonlar/kampanya_sokaktaki_dost.png',
                title: 'Sokaktaki Dostlar',
                subtitle: 'Puanlarını sokaktaki dostlar için bağışla!',
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGiftActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppPressableButton.primary(
            onTap: _openSmartPlan,
            height: 42,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_month_rounded, size: 15),
                SizedBox(width: 6),
                Text(
                  'Siparişi Planla',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AppPressableButton.outline(
            onTap: () {},
            height: 42,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none_rounded, size: 15),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Daha Sonra Hatırlat',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReferralCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
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
      child: _inviteOpen ? _buildInvitePanel() : _buildReferralContent(),
    );
  }

  Widget _buildReferralContent() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/son_ikonlar/kampanya_arkadasini_getir.png',
                width: 64,
                height: 64,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.card_giftcard_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Arkadaşını Getir,\nDost Puan Kazan!',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Arkadaşın ilk alışverişini yapsın, sen de 100 Dost Puan kazan.',
                    style: TextStyle(
                      color: AppColors.subText.withValues(alpha: 0.95),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            AppPressableButton.primary(
              onTap: _openInviteForm,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: const Text(
                'Arkadaşını\nDavet Et',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      color: AppColors.subText,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                    children: [
                      TextSpan(text: 'Davet Kodun: '),
                      TextSpan(
                        text: _referralCode,
                        style: TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppPressableButton(
                onTap: _copyReferralCode,
                padding: const EdgeInsets.all(6),
                backgroundColor: AppColors.selected,
                pressedBackgroundColor: AppColors.primary,
                foregroundColor: AppColors.primary,
                pressedForegroundColor: AppColors.surface,
                borderColor: AppColors.border,
                pressedBorderColor: AppColors.primary,
                child: const Icon(Icons.copy_rounded, size: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvitePanel() {
    if (_inviteSuccess) {
      return Column(
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'İşlem başarıyla tamamlanmıştır',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
              ),
              AppPressableButton(
                onTap: _closeInviteForm,
                padding: const EdgeInsets.all(4),
                backgroundColor: Colors.transparent,
                pressedBackgroundColor: AppColors.selected,
                foregroundColor: AppColors.subText,
                pressedForegroundColor: AppColors.text,
                borderColor: Colors.transparent,
                pressedBorderColor: Colors.transparent,
                borderWidth: 0,
                child: const Icon(Icons.close_rounded, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _inviteChannel == _InviteChannel.phone
                  ? 'Davet kodu telefona gönderildi.'
                  : 'Davet kodu e-postaya gönderildi.',
              style: TextStyle(
                color: AppColors.subText.withValues(alpha: 0.95),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          AppPressableButton.primary(
            onTap: _closeInviteForm,
            width: double.infinity,
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: const Text(
              'Tamam',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Arkadaşını Davet Et',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              'Kod: $_referralCode',
              style: TextStyle(
                color: AppColors.subText.withValues(alpha: 0.95),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            AppPressableButton(
              onTap: _closeInviteForm,
              padding: const EdgeInsets.all(4),
              backgroundColor: Colors.transparent,
              pressedBackgroundColor: AppColors.selected,
              foregroundColor: AppColors.subText,
              pressedForegroundColor: AppColors.text,
              borderColor: Colors.transparent,
              pressedBorderColor: Colors.transparent,
              borderWidth: 0,
              child: const Icon(Icons.close_rounded, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _InviteChannelChip(
                label: 'Telefon',
                icon: Icons.phone_rounded,
                selected: _inviteChannel == _InviteChannel.phone,
                onTap: () {
                  setState(() {
                    _inviteChannel = _InviteChannel.phone;
                    _inviteError = null;
                    _inviteController.clear();
                  });
                },
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _InviteChannelChip(
                label: 'E-posta',
                icon: Icons.mail_outline_rounded,
                selected: _inviteChannel == _InviteChannel.email,
                onTap: () {
                  setState(() {
                    _inviteChannel = _InviteChannel.email;
                    _inviteError = null;
                    _inviteController.clear();
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 32,
          child: TextField(
            controller: _inviteController,
            keyboardType: _inviteChannel == _InviteChannel.phone
                ? TextInputType.phone
                : TextInputType.emailAddress,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: _inviteChannel == _InviteChannel.phone
                  ? 'Telefon numarası'
                  : 'E-posta adresi',
              hintStyle: TextStyle(
                color: AppColors.subText.withValues(alpha: 0.8),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
            onChanged: (_) {
              if (_inviteError != null) setState(() => _inviteError = null);
            },
          ),
        ),
        if (_inviteError != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _inviteError!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const SizedBox(height: 6),
        AppPressableButton.primary(
          onTap: _submitInvite,
          width: double.infinity,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: const Text(
            'Tamam',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _buildRewardsSection(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Puanlarını Ödüllere Dönüştür',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            AppPressableButton(
              onTap: () {},
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              backgroundColor: Colors.transparent,
              pressedBackgroundColor: AppColors.selected,
              foregroundColor: AppColors.primary,
              pressedForegroundColor: AppColors.primary,
              borderColor: Colors.transparent,
              pressedBorderColor: Colors.transparent,
              borderWidth: 0,
              child: const Text(
                'Tüm Ödüller >',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < _rewards.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: _RewardCard(product: _rewards[i])),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTiersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dost Seviyeleri',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (int i = 0; i < _tiers.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: _TierCard(tier: _tiers[i])),
            ],
          ],
        ),
      ],
    );
  }
}

class _GiftOptionCard extends StatelessWidget {
  const _GiftOptionCard({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String imagePath;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPressableButton(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
      backgroundColor: AppColors.surface,
      pressedBackgroundColor: AppColors.selected,
      foregroundColor: AppColors.text,
      pressedForegroundColor: AppColors.text,
      borderColor: AppColors.border,
      pressedBorderColor: AppColors.primary,
      borderRadius: 18,
      builder: (pressed) => Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ColoredBox(
                color: AppColors.white,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.card_giftcard_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.subText.withValues(alpha: 0.95),
              fontSize: 7.5,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.product});

  final _RewardProduct product;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            height: 20,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.selected,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                product.points,
                maxLines: 1,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 56,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ColoredBox(
                color: AppColors.white,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(
                    product.imagePath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.card_giftcard_rounded,
                      size: 28,
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 26,
            child: Text(
              product.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(height: 6),
          AppPressableButton.soft(
            onTap: () {},
            width: double.infinity,
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.redeem_rounded, size: 12),
                  SizedBox(width: 3),
                  Text(
                    'Puanla Al',
                    style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({required this.tier});

  final _TierInfo tier;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: tier.isCurrent ? AppColors.primary : AppColors.border,
          width: tier.isCurrent ? 1.5 : 1,
        ),
        boxShadow: tier.isCurrent
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ColoredBox(
                    color: AppColors.white,
                    child: Image.asset(
                      tier.imagePath,
                      fit: BoxFit.contain,
                      width: 56,
                      height: 56,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.shield_rounded,
                        color: tier.color,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -2,
                right: -2,
                child: tier.isCurrent
                    ? Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: AppColors.surface,
                          size: 10,
                        ),
                      )
                    : tier.isLocked
                        ? Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColors.subText.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_rounded,
                              color: AppColors.subText.withValues(alpha: 0.8),
                              size: 9,
                            ),
                          )
                        : const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tier.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: tier.isCurrent ? AppColors.primary : AppColors.text,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            tier.range,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.subText.withValues(alpha: 0.95),
              fontSize: 7.5,
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteChannelChip extends StatelessWidget {
  const _InviteChannelChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPressableButton(
      onTap: onTap,
      height: 30,
      padding: EdgeInsets.zero,
      backgroundColor: selected ? AppColors.selected : AppColors.background,
      pressedBackgroundColor: AppColors.selected,
      foregroundColor: selected ? AppColors.primary : AppColors.subText,
      pressedForegroundColor: AppColors.primary,
      borderColor: selected ? AppColors.primary : AppColors.border,
      pressedBorderColor: AppColors.primary,
      borderRadius: 999,
      builder: (pressed) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

enum _InviteChannel { phone, email }

class _RewardProduct {
  const _RewardProduct({
    required this.name,
    required this.points,
    required this.imagePath,
  });

  final String name;
  final String points;
  final String imagePath;
}

class _TierInfo {
  const _TierInfo({
    required this.name,
    required this.range,
    required this.color,
    required this.imagePath,
    this.isCurrent = false,
    this.isLocked = false,
  });

  final String name;
  final String range;
  final Color color;
  final String imagePath;
  final bool isCurrent;
  final bool isLocked;
}

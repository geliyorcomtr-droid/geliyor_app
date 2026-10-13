import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/admin/admin_models.dart';
import 'package:geliyor_app/data/banner_repository.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/product_repository.dart';
import 'package:geliyor_app/state/auth_store.dart';
import 'package:geliyor_app/utils/product_image.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:flutter/services.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/login_gate.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_banner_slider.dart';
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
  static const String _referralCode = 'GELIYOR100';

  bool _inviteOpen = false;
  bool _streetDonated = false;
  int _heldPoints = 0;
  bool _inviteSuccess = false;
  bool _inviteSending = false;
  _InviteChannel _inviteChannel = _InviteChannel.phone;
  final TextEditingController _inviteController = TextEditingController();
  String? _inviteError;

  static const List<_TierInfo> _tiers = [
    _TierInfo(
      name: 'Bronz Dost',
      range: '1 - 1.999 Puan',
      color: AppColors.primary,
      imagePath: 'assets/images/son_ikonlar/kampanya_bronz_dost.png',
      isCurrent: true,
    ),
    _TierInfo(
      name: 'Gold Dost',
      range: '2.000 - 4.999 Puan',
      color: AppColors.primary,
      imagePath: 'assets/images/son_ikonlar/kampanya_altin_dost.png',
      isLocked: true,
    ),
    _TierInfo(
      name: 'Premium Dost',
      range: '5.000+ Puan',
      color: AppColors.primary,
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

  void _donateStreetPoints() {
    final next = !_streetDonated;
    setState(() => _streetDonated = next);
    final uid = AuthStore.instance.uid;
    if (uid == null || uid.isEmpty) return;
    final ref = FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .doc(uid);
    if (!next) {
      final restore = _heldPoints;
      _heldPoints = 0;
      if (restore <= 0) return;
      ref.set({
        UserFields.dostPoints: FieldValue.increment(restore),
        UserFields.updatedAt: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }
    FirebaseFirestore.instance.runTransaction<int>((tx) async {
      final current = await tx.get(ref);
      final balance =
          (current.data()?[UserFields.dostPoints] as num?)?.round() ?? 0;
      if (balance <= 0) return 0;
      tx.set(ref, {
        UserFields.dostPoints: 0,
        UserFields.updatedAt: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return balance;
    }).then((taken) {
      if (!mounted) return;
      if (!_streetDonated) {
        if (taken > 0) {
          ref.set({
            UserFields.dostPoints: FieldValue.increment(taken),
            UserFields.updatedAt: FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        return;
      }
      _heldPoints = taken;
    });
  }

  Future<void> _openInviteForm() async {
    final ok = await LoginGate.require(
      context: context,
      message: 'Arkadaşını davet etmek için giriş yapmanız gerekir.',
    );
    if (!ok || !mounted) return;
    setState(() {
      _inviteOpen = true;
      _inviteSuccess = false;
      _inviteSending = false;
      _inviteError = null;
      _inviteController.clear();
      _inviteChannel = _InviteChannel.phone;
    });
  }

  void _closeInviteForm() {
    if (_inviteSending) return;
    setState(() {
      _inviteOpen = false;
      _inviteSuccess = false;
      _inviteSending = false;
      _inviteError = null;
      _inviteController.clear();
    });
  }

  Future<void> _submitInvite() async {
    if (_inviteSending) return;
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

    final loggedIn = await LoginGate.require(
      context: context,
      message: 'Arkadaşını davet etmek için giriş yapmanız gerekir.',
    );
    if (!loggedIn || !mounted) return;

    setState(() {
      _inviteError = null;
      _inviteSending = true;
    });

    try {
      await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('sendReferralInvite')
          .call(<String, dynamic>{
            'channel': _inviteChannel == _InviteChannel.email
                ? 'email'
                : 'phone',
            'to': value,
          });
      if (!mounted) return;
      setState(() {
        _inviteSending = false;
        _inviteSuccess = true;
      });
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      setState(() {
        _inviteSending = false;
        _inviteError = error.message?.trim().isNotEmpty == true
            ? error.message
            : 'Davet gönderilemedi. Tekrar deneyin.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _inviteSending = false;
        _inviteError = 'Davet gönderilemedi. Tekrar deneyin.';
      });
    }
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
          padding: const EdgeInsets.fromLTRB(
            AppPageFrame.contentHorizontalPadding,
            0,
            AppPageFrame.contentHorizontalPadding,
            10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBanner(),
              const SizedBox(height: 12),
              _buildGiftSection(context),
              const SizedBox(height: 14),
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
    return const AppBannerSlot(
      placement: BannerPlacement.campaignsPoints,
      fallbackAssets: ['assets/images/kampanya_puan_banner.png'],
    );
  }

  Widget _buildGiftSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text('Dost Hediyeni Sen Seç', style: AppTextStyles.sectionHeader),
            SizedBox(width: 4),
            Icon(
              Icons.card_giftcard_rounded,
              size: 15,
              color: AppColors.primary,
            ),
          ],
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
        _CampaignGiftRow(
          onDonate: _donateStreetPoints,
          donated: _streetDonated,
        ),
      ],
    );
  }

  Widget _buildReferralCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text('Arkadaşını Davet Et', style: AppTextStyles.sectionHeader),
            SizedBox(width: 4),
            Icon(
              Icons.person_add_alt_1_rounded,
              size: 15,
              color: AppColors.primary,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
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
        ),
      ],
    );
  }

  Widget _buildReferralContent() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Arkadaşını Getir, Dost Puan Kazan!',
                      maxLines: 1,
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
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
                  const SizedBox(height: 8),
                  AppPressableButton.soft(
                    onTap: _openInviteForm,
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: const Text(
                      'Davet Et',
                      maxLines: 1,
                      style: TextStyle(fontSize: 11.5),
                    ),
                  ),
                ],
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
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 28,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'İşlem başarıyla tamamlanmıştır',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
              ),
              AppPressableButton(
                onTap: _closeInviteForm,
                padding: const EdgeInsets.all(6),
                backgroundColor: Colors.transparent,
                pressedBackgroundColor: AppColors.selected,
                foregroundColor: AppColors.subText,
                pressedForegroundColor: AppColors.text,
                borderColor: Colors.transparent,
                pressedBorderColor: Colors.transparent,
                borderWidth: 0,
                child: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _inviteChannel == _InviteChannel.phone
                  ? 'Davet kodu telefona gönderildi.'
                  : 'Davet kodu e-postaya gönderildi.',
              style: TextStyle(
                color: AppColors.subText.withValues(alpha: 0.95),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppPressableButton.primary(
            onTap: _closeInviteForm,
            width: double.infinity,
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: const Text(
              'Tamam',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
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
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              'Kod: $_referralCode',
              style: TextStyle(
                color: AppColors.subText.withValues(alpha: 0.95),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            AppPressableButton(
              onTap: _closeInviteForm,
              padding: const EdgeInsets.all(6),
              backgroundColor: Colors.transparent,
              pressedBackgroundColor: AppColors.selected,
              foregroundColor: AppColors.subText,
              pressedForegroundColor: AppColors.text,
              borderColor: Colors.transparent,
              pressedBorderColor: Colors.transparent,
              borderWidth: 0,
              child: const Icon(Icons.close_rounded, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _InviteChannelChip(
                label: 'Telefon',
                icon: Icons.phone_rounded,
                selected: _inviteChannel == _InviteChannel.phone,
                onTap: _inviteSending
                    ? () {}
                    : () {
                        setState(() {
                          _inviteChannel = _InviteChannel.phone;
                          _inviteError = null;
                          _inviteController.clear();
                        });
                      },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InviteChannelChip(
                label: 'E-posta',
                icon: Icons.mail_outline_rounded,
                selected: _inviteChannel == _InviteChannel.email,
                onTap: _inviteSending
                    ? () {}
                    : () {
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
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: TextField(
            controller: _inviteController,
            enabled: !_inviteSending,
            keyboardType: _inviteChannel == _InviteChannel.phone
                ? TextInputType.phone
                : TextInputType.emailAddress,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
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
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _inviteError!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        AppPressableButton.primary(
          onTap: _inviteSending ? null : _submitInvite,
          enabled: !_inviteSending,
          width: double.infinity,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            _inviteSending ? 'Gönderiliyor...' : 'Tamam',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Future<void> _redeemReward(AdminProduct product) async {
    final ok = await LoginGate.require(
      context: context,
      message: 'Puanla almak için giriş yapmanız gerekir.',
    );
    if (!ok || !mounted) return;
    final uid = AuthStore.instance.uid;
    if (uid == null || uid.isEmpty) return;
    final cost = product.rewardPoints;
    if (cost <= 0) return;
    final ref = FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .doc(uid);
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final points =
            (snap.data()?[UserFields.dostPoints] as num?)?.round() ?? 0;
        if (points < cost) {
          throw StateError('yetersiz');
        }
        tx.set(ref, {
          UserFields.dostPoints: points - cost,
          UserFields.updatedAt: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.title} puanla alındı.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on StateError {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dost puanın bu ürün için yeterli değil.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildRewardsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Puanlarını Ödüllere Dönüştür',
          style: AppTextStyles.sectionHeader,
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<AdminProduct>>(
          stream: ProductRepository.instance.watchAll(activeOnly: true),
          builder: (context, snapshot) {
            final rewards = [
              for (final product in snapshot.data ?? const <AdminProduct>[])
                if (product.isPointReward) product,
            ];
            if (rewards.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'Henüz puan ödülü seçilmedi.',
                  style: TextStyle(
                    color: AppColors.subText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }
            return _rewardGrid(rewards);
          },
        ),
      ],
    );
  }

  Widget _rewardGrid(List<AdminProduct> products) {
    const columns = 4;
    const gap = 6.0;
    final rows = <Widget>[];
    for (var start = 0; start < products.length; start += columns) {
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var column = 0; column < columns; column++) ...[
              if (column > 0) const SizedBox(width: gap),
              Expanded(
                child: start + column < products.length
                    ? _RewardCard(
                        product: products[start + column],
                        onRedeem: () => _redeemReward(products[start + column]),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      );
      if (start + columns < products.length) {
        rows.add(const SizedBox(height: gap));
      }
    }
    return Column(children: rows);
  }

  Widget _buildTiersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dost Seviyeleri',
          style: AppTextStyles.sectionHeader,
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

class _CampaignGiftRow extends StatelessWidget {
  const _CampaignGiftRow({required this.onDonate, required this.donated});

  final VoidCallback onDonate;
  final bool donated;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(FirestoreCollections.banners)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _CampaignGiftArt(
                imagePath: _campaignArtPath(
                  docs: docs,
                  placement: BannerPlacement.campaignDiscount,
                  seededId: 'campaign-discount',
                  fallback: 'assets/images/kampanya_yuzde5_indirim.jpg',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CampaignGiftArt(
                imagePath: _campaignArtPath(
                  docs: docs,
                  placement: BannerPlacement.campaignDouble,
                  seededId: 'campaign-double',
                  fallback: 'assets/images/kampanya_ilk_siparis_2kat.jpg',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CampaignGiftArt(
                imagePath: _campaignArtPath(
                  docs: docs,
                  placement: BannerPlacement.campaignDonate,
                  seededId: 'campaign-donate',
                  fallback: 'assets/images/kampanya_sokak_bagis.jpg',
                ),
                onTap: onDonate,
                checked: donated,
              ),
            ),
          ],
        );
      },
    );
  }
}

String? _campaignArtPath({
  required List<QueryDocumentSnapshot<Map<String, dynamic>>>? docs,
  required BannerPlacement placement,
  required String seededId,
  required String fallback,
}) {
  if (docs == null) return fallback;
  final deleted = <String>{};
  for (final doc in docs) {
    if (doc.id != BannerRepository.seededDocId) continue;
    final raw = doc.data()['deletedIds'];
    if (raw is Iterable) {
      deleted.addAll(raw.map((item) => item.toString()));
    }
  }
  final forSlot = [
    for (final doc in docs)
      if (!doc.id.startsWith('_')) AppBanner.fromDoc(doc),
  ].where((banner) => banner.placement == placement.id).toList();
  final visible = forSlot
      .where(
        (banner) => banner.active && banner.displayImage.trim().isNotEmpty,
      )
      .toList();
  final picked = AppBanner.latestLive(visible);
  if (picked != null && picked.displayImage.trim().isNotEmpty) {
    return picked.displayImage;
  }
  if (deleted.contains(seededId) || forSlot.isNotEmpty) return null;
  return fallback;
}

class _CampaignGiftArt extends StatelessWidget {
  const _CampaignGiftArt({
    required this.imagePath,
    this.onTap,
    this.checked = false,
  });

  final String? imagePath;
  final VoidCallback? onTap;
  final bool checked;

  @override
  Widget build(BuildContext context) {
    final path = imagePath?.trim() ?? '';
    final art = AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.statNumber,
            width: 1.6,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ColoredBox(
            color: AppColors.surface,
            child: path.isEmpty
                ? const SizedBox.expand()
                : buildProductImage(
                    path,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.high,
                  ),
          ),
        ),
      ),
    );
    final marked = Stack(
      children: [
        art,
        if (checked)
          const Positioned(
            top: 6,
            right: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.statNumber,
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 22,
                height: 22,
                child: Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: AppColors.surface,
                ),
              ),
            ),
          ),
      ],
    );
    if (onTap == null) return marked;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: marked,
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.product, required this.onRedeem});

  final AdminProduct product;
  final VoidCallback onRedeem;

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
                '${product.rewardPoints} Puan',
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
                  child: buildProductImage(
                    product.imageUrl,
                    fit: BoxFit.contain,
                    errorWidget: Icon(
                      Icons.card_giftcard_rounded,
                      size: 22,
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
              product.title,
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
            onTap: onRedeem,
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
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                    ),
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
      height: 42,
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
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

enum _InviteChannel { phone, email }

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

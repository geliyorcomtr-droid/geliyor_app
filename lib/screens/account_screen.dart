import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/screens/orders_screen.dart';
import 'package:geliyor_app/screens/addresses_screen.dart';
import 'package:geliyor_app/screens/favorites_screen.dart';
import 'package:geliyor_app/screens/help_support_screen.dart';
import 'package:geliyor_app/screens/notification_settings_screen.dart';
import 'package:geliyor_app/screens/payment_methods_screen.dart';
import 'package:geliyor_app/screens/privacy_security_screen.dart';
import 'package:geliyor_app/screens/logout_success_screen.dart';
import 'package:geliyor_app/screens/personal_info_screen.dart';
import 'package:geliyor_app/state/auth_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  static const int _points = 1250;
  static const int _nextTierPoints = 1500;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame.standard(
        backgroundColor: AppColors.background,
        activeTab: AppNavTab.profile,
        header: _buildHeader(context),
        content: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppPageFrame.contentHorizontalPadding,
            0,
            AppPageFrame.contentHorizontalPadding,
            8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileCard(),
              const SizedBox(height: 12),
              _buildMenuCard(
                context: context,
                title: 'Hesap Bilgilerim',
                items: [
                  const _MenuItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Kişisel Bilgilerim',
                    opensPersonalInfo: true,
                  ),
                  const _MenuItem(
                    icon: Icons.location_on_outlined,
                    label: 'Adreslerim',
                    opensAddresses: true,
                  ),
                  const _MenuItem(
                    icon: Icons.credit_card_outlined,
                    label: 'Ödeme Yöntemlerim',
                    opensPaymentMethods: true,
                  ),
                  const _MenuItem(
                    icon: Icons.notifications_none_rounded,
                    label: 'Bildirim Ayarlarım',
                    opensNotificationSettings: true,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildMenuCard(
                context: context,
                title: 'Diğer İşlemler',
                items: const [
                  _MenuItem(
                    icon: Icons.receipt_long_outlined,
                    label: 'Siparişler',
                    opensOrders: true,
                  ),
                  _MenuItem(
                    icon: Icons.favorite_border_rounded,
                    label: 'Favorilerim',
                    opensFavorites: true,
                  ),
                  _MenuItem(
                    icon: Icons.headset_mic_outlined,
                    label: 'Yardım & Destek',
                    opensHelpSupport: true,
                  ),
                  _MenuItem(
                    icon: Icons.verified_user_outlined,
                    label: 'Gizlilik & Güvenlik',
                    opensPrivacySecurity: true,
                  ),
                  _MenuItem(
                    icon: Icons.logout_rounded,
                    label: 'Çıkış Yap',
                    isDestructive: true,
                    opensLogout: true,
                  ),
                ],
              ),
            ],
          ),
        ),
        navbar: const AppBottomNavbar(activeTab: AppNavTab.profile),
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
            child: IgnorePointer(
              child: Text(
                'Hesabım',
                textAlign: TextAlign.center,
                style: AppTextStyles.pageHeader,
              ),
            ),
          ),
          const AppNotificationButton(badgeColor: AppColors.error),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    final progress = _points / _nextTierPoints;
    final remaining = _nextTierPoints - _points;
    final auth = AuthStore.instance;
    final displayName = auth.fullName.trim().isEmpty
        ? 'Can Dostu'
        : auth.fullName.trim();
    final phoneLabel = auth.phone.trim().isEmpty
        ? 'Üye hesabı'
        : auth.phone.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
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
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/luna_kopek.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.selected,
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
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                      child: const Icon(
                        Icons.photo_camera_rounded,
                        color: AppColors.surface,
                        size: 11,
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
                      displayName,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phoneLabel,
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
                        color: AppColors.selected,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.pets_rounded,
                            size: 11,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Bronz Dost',
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Dost Puanım',
                    style: TextStyle(
                      color: AppColors.subText,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_points',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.pets_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.subText.withValues(alpha: 0.8),
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$remaining puan sonra Silver Dost',
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$_points / $_nextTierPoints',
                style: const TextStyle(
                  color: AppColors.subText,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.border,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required List<_MenuItem> items,
  }) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Text(
              title,
              style: AppTextStyles.sectionHeader,
            ),
          ),
          for (int i = 0; i < items.length; i++) ...[
            _buildMenuRow(context, items[i]),
            if (i != items.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 52,
                endIndent: 14,
                color: AppColors.border.withValues(alpha: 0.7),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuRow(BuildContext context, _MenuItem item) {
    final color = item.isDestructive ? AppColors.error : AppColors.text;
    final iconColor = item.isDestructive ? AppColors.error : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.opensPersonalInfo
            ? () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PersonalInfoScreen()),
                );
              }
            : item.opensAddresses
            ? () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddressesScreen()),
                );
              }
            : item.opensPaymentMethods
            ? () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PaymentMethodsScreen(),
                  ),
                );
              }
            : item.opensNotificationSettings
            ? () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationSettingsScreen(),
                  ),
                );
              }
            : item.opensOrders
            ? () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const OrdersScreen()));
              }
            : item.opensFavorites
            ? () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                );
              }
            : item.opensHelpSupport
            ? () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                );
              }
            : item.opensPrivacySecurity
            ? () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PrivacySecurityScreen(),
                  ),
                );
              }
            : item.opensLogout
            ? () async {
                await AuthStore.instance.logout();
                if (!context.mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const LogoutSuccessScreen(),
                  ),
                );
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: item.isDestructive
                      ? AppColors.error.withValues(alpha: 0.08)
                      : AppColors.selected,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(item.icon, color: iconColor, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
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
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.label,
    this.isDestructive = false,
    this.opensPersonalInfo = false,
    this.opensAddresses = false,
    this.opensPaymentMethods = false,
    this.opensNotificationSettings = false,
    this.opensFavorites = false,
    this.opensOrders = false,
    this.opensHelpSupport = false,
    this.opensPrivacySecurity = false,
    this.opensLogout = false,
  });

  final IconData icon;
  final String label;
  final bool isDestructive;
  final bool opensPersonalInfo;
  final bool opensAddresses;
  final bool opensPaymentMethods;
  final bool opensNotificationSettings;
  final bool opensFavorites;
  final bool opensOrders;
  final bool opensHelpSupport;
  final bool opensPrivacySecurity;
  final bool opensLogout;
}

import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/state/notification_settings_store.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = NotificationSettingsStore.instance;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame.standard(
        backgroundColor: AppColors.background,
        activeTab: AppNavTab.profile,
        header: _buildHeader(context),
        content: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            return SingleChildScrollView(
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
                  _buildMasterToggle(store),
                  const SizedBox(height: 12),
                  const Text(
                    'Bildirim Tercihlerim',
                    style: TextStyle(
                      color: AppColors.subText,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPreferenceCard(store),
                  const SizedBox(height: 12),
                  const Text(
                    'Bildirim Kanalları',
                    style: TextStyle(
                      color: AppColors.subText,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildChannelCard(store),
                  const SizedBox(height: 12),
                  _buildInfoBox(),
                ],
              ),
            );
          },
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Bildirim Ayarları',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.pageHeader,
                ),
                Text(
                  'Hangi bildirimleri almak istediğinizi seçebilir ve yönetebilirsiniz.',
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

  Widget _buildMasterToggle(NotificationSettingsStore store) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
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
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.selected,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tüm Bildirimler',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Tüm bildirimleri açabilir veya kapatabilirsiniz.',
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
          Transform.scale(
            scale: 0.82,
            child: Switch.adaptive(
              value: store.allEnabled,
              activeTrackColor: AppColors.primary,
              activeThumbColor: AppColors.surface,
              onChanged: store.setAllEnabled,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceCard(NotificationSettingsStore store) {
    final items = <_SettingItem>[
      const _SettingItem(
        id: 'orders',
        icon: Icons.shopping_bag_outlined,
        title: 'Sipariş Bildirimleri',
        subtitle: 'Siparişinizin durumu, kargo ve teslimat bildirimleri.',
      ),
      const _SettingItem(
        id: 'campaigns',
        icon: Icons.local_offer_outlined,
        title: 'Kampanya ve İndirimler',
        subtitle: 'Size özel kampanya, indirim ve fırsatlardan haberdar olun.',
      ),
      const _SettingItem(
        id: 'products',
        icon: Icons.inventory_2_outlined,
        title: 'Ürün Bildirimleri',
        subtitle: 'Stok güncellemeleri, yeni ürünler ve fiyat değişiklikleri.',
      ),
      const _SettingItem(
        id: 'petWorld',
        icon: Icons.pets_rounded,
        title: 'Dostumun Dünyası',
        subtitle: 'Evcil dostunuz için bakım, sağlık ve ipuçları.',
      ),
      const _SettingItem(
        id: 'points',
        icon: Icons.favorite_border_rounded,
        title: 'Puan ve Sadakat Bildirimleri',
        subtitle: 'Dost Puan kazanımları ve sadakat programı bildirimleri.',
      ),
      const _SettingItem(
        id: 'reminders',
        icon: Icons.notifications_none_rounded,
        title: 'Hatırlatıcılar',
        subtitle:
            'Sepet hatırlatıcıları, alışveriş hatırlatıcıları ve diğer uyarılar.',
      ),
    ];

    return _buildSettingsCard(
      items: items,
      values: store.preferences,
      enabled: store.allEnabled,
      onChanged: store.setPreference,
    );
  }

  Widget _buildChannelCard(NotificationSettingsStore store) {
    final items = <_SettingItem>[
      const _SettingItem(
        id: 'inApp',
        icon: Icons.phone_iphone_rounded,
        title: 'Uygulama İçi Bildirimler',
        subtitle: 'Uygulama içindeki bildirimleri alırsınız.',
      ),
      const _SettingItem(
        id: 'email',
        icon: Icons.mail_outline_rounded,
        title: 'E-posta Bildirimleri',
        subtitle: 'E-posta adresinize bildirim gönderilir.',
      ),
      const _SettingItem(
        id: 'sms',
        icon: Icons.sms_outlined,
        title: 'SMS Bildirimleri',
        subtitle: 'Telefon numaranıza SMS ile bildirim gönderilir.',
      ),
    ];

    return _buildSettingsCard(
      items: items,
      values: store.channels,
      enabled: store.allEnabled,
      onChanged: store.setChannel,
    );
  }

  Widget _buildSettingsCard({
    required List<_SettingItem> items,
    required Map<String, bool> values,
    required bool enabled,
    required void Function(String id, bool value) onChanged,
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
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _buildSettingRow(
              item: items[i],
              value: values[items[i].id] ?? false,
              enabled: enabled,
              onChanged: (value) => onChanged(items[i].id, value),
            ),
            if (i != items.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 54,
                endIndent: 14,
                color: AppColors.border.withValues(alpha: 0.7),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required _SettingItem item,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.selected,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(item.icon, color: AppColors.primary, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: AppColors.text,
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
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.78,
            child: Switch.adaptive(
              value: enabled ? value : false,
              activeTrackColor: AppColors.primary,
              activeThumbColor: AppColors.surface,
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
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
            right: -4,
            bottom: -8,
            child: Icon(
              Icons.pets_rounded,
              size: 52,
              color: AppColors.primary.withValues(alpha: 0.08),
            ),
          ),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bilgilendirme',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Bildirim ayarlarınızı dilediğiniz zaman değiştirebilirsiniz. Ayarlarınız, tüm cihazlarınızda senkronize edilir.',
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
}

class _SettingItem {
  const _SettingItem({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
}

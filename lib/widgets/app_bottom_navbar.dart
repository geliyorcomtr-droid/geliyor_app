import 'package:flutter/material.dart';
import 'package:geliyor_app/screens/account_screen.dart';
import 'package:geliyor_app/screens/assistant_screen.dart';
import 'package:geliyor_app/screens/campaigns_points_screen.dart';
import 'package:geliyor_app/screens/cart_screen.dart';
import 'package:geliyor_app/screens/home_screen.dart';
import 'package:geliyor_app/screens/welcome_screen.dart';
import 'package:geliyor_app/state/auth_store.dart';
import 'package:geliyor_app/state/cart_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';

enum AppNavTab { assistant, home, cart, campaigns, profile }

class AppBottomNavbar extends StatelessWidget {
  const AppBottomNavbar({
    super.key,
    this.activeTab = AppNavTab.home,
    this.height = AppPageFrame.bottomNavHeight,
  });

  final AppNavTab activeTab;
  final double height;

  void _goAssistant(BuildContext context) {
    if (activeTab == AppNavTab.assistant) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'assistant'),
        builder: (_) => const AssistantScreen(),
      ),
    );
  }

  void _goProfile(BuildContext context) {
    final loggedIn = AuthStore.instance.isLoggedIn;
    final targetName = loggedIn ? 'profile' : 'welcome';
    final Widget target =
        loggedIn ? const AccountScreen() : const WelcomeScreen();

    if (activeTab == AppNavTab.profile) {
      final navigator = Navigator.of(context);
      var landedOnProfileRoot = false;
      navigator.popUntil((route) {
        final name = route.settings.name;
        if (name == 'profile' || name == 'welcome') {
          landedOnProfileRoot = true;
          return true;
        }
        return route.isFirst;
      });
      if (!landedOnProfileRoot) {
        navigator.push(
          MaterialPageRoute(
            settings: RouteSettings(name: targetName),
            builder: (_) => target,
          ),
        );
      }
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        settings: RouteSettings(name: targetName),
        builder: (_) => target,
      ),
    );
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  void _goCart(BuildContext context) {
    if (activeTab == AppNavTab.cart) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'cart'),
        builder: (_) => const CartScreen(),
      ),
    );
  }

  void _goCampaigns(BuildContext context) {
    if (activeTab == AppNavTab.campaigns) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'campaigns'),
        builder: (_) => const CampaignsPointsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CartStore.instance,
      builder: (context, _) {
        final quantity = CartStore.instance.totalQuantity;

        return Container(
          height: height,
          clipBehavior: Clip.none,
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                icon: Icons.smart_toy_outlined,
                label: 'Asistan',
                active: activeTab == AppNavTab.assistant,
                onTap: () => _goAssistant(context),
              ),
              _navItem(
                icon: Icons.local_offer_outlined,
                label: 'Kampanya',
                active: activeTab == AppNavTab.campaigns,
                onTap: () => _goCampaigns(context),
              ),
              Transform.translate(
                offset: const Offset(0, -22),
                child: GestureDetector(
                  onTap: () => _goHome(context),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.pets_rounded, color: AppColors.surface, size: 28),
                  ),
                ),
              ),
              _cartItem(context, quantity),
              _navItem(
                icon: Icons.person_outline_rounded,
                label: 'Profil',
                active: activeTab == AppNavTab.profile,
                onTap: () => _goProfile(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _cartItem(BuildContext context, int quantity) {
    final active = activeTab == AppNavTab.cart;
    final color = active ? AppColors.primary : AppColors.subText;

    return GestureDetector(
      onTap: () => _goCart(context),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 28,
              height: 22,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, color: color, size: 22),
                  if (quantity > 0)
                    Positioned(
                      top: -4,
                      right: -6,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$quantity',
                          style: const TextStyle(
                            color: AppColors.surface,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Sepetim',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required bool active,
    VoidCallback? onTap,
  }) {
    final color = active ? AppColors.primary : AppColors.subText;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

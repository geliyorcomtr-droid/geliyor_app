import 'package:flutter/material.dart';
import 'package:geliyor_app/data/banner_repository.dart';
import 'package:geliyor_app/screens/add_pet_screen.dart';
import 'package:geliyor_app/state/pet_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/theme/app_icons.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/utils/login_gate.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_banner_slider.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';
import 'package:geliyor_app/widgets/pet_photo.dart';

class MeetPetScreen extends StatelessWidget {
  const MeetPetScreen({super.key});

  static Color get _addPressed =>
      Color.lerp(AppColors.error, AppColors.text, 0.12)!;

  void _openAdd(BuildContext context, {int? editIndex, PetData? pet}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddPetScreen(editIndex: editIndex, pet: pet),
      ),
    );
  }

  void _openEdit(BuildContext context, int index, PetData pet) {
    PetStore.instance.selectPet(index);
    _openAdd(context, editIndex: index, pet: pet);
  }

  Future<void> _deletePet(BuildContext context, int index, PetData pet) async {
    final ok = await LoginGate.require(
      context: context,
      message: 'Dost silmek için giriş yapmanız gerekir.',
    );
    if (!ok || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: AppColors.error.withValues(alpha: 0.28)),
          ),
          title: const Text(
            'Dostu sil',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            '“${pet.name}” silinsin mi?',
            style: const TextStyle(
              color: AppColors.subText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Vazgeç',
                style: TextStyle(
                  color: AppColors.subText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Sil',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    PetStore.instance.removePet(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: AppPageFrame.standard(
        backgroundColor: AppColors.surface,
        pawPrintColor: AppColors.error,
        header: const _MeetPetHeader(),
        content: ListenableBuilder(
          listenable: PetStore.instance,
          builder: (context, _) {
            final pets = PetStore.instance.pets;
            final activeIndex = PetStore.instance.activePetIndex;
            return LayoutBuilder(
              builder: (context, constraints) {
                const bannerH = 132.0;
                const addH = 36.0;
                const sectionH = 22.0;
                const gap = 8.0;
                const cardGap = 6.0;
                const visibleCards = 3;
                final reserved = bannerH + gap + addH + gap + sectionH + gap;
                final cardsSpace =
                    (constraints.maxHeight - reserved).clamp(320.0, 420.0);
                final cardH =
                    ((cardsSpace - cardGap * (visibleCards - 1)) / visibleCards)
                        .clamp(108.0, 128.0);

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppPageFrame.contentHorizontalPadding,
                    0,
                    AppPageFrame.contentHorizontalPadding,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AppBannerSlot(
                        placement: BannerPlacement.meetPet,
                        fallbackAssets: [
                          'assets/images/dostunu_taniyalim_banner.png',
                        ],
                      ),
                      const SizedBox(height: gap),
                      AppPressableButton(
                        onTap: () => _openAdd(context),
                        width: double.infinity,
                        height: addH,
                        padding: EdgeInsets.zero,
                        backgroundColor: AppColors.error,
                        pressedBackgroundColor: _addPressed,
                        foregroundColor: AppColors.surface,
                        pressedForegroundColor: AppColors.surface,
                        borderColor: AppColors.error,
                        pressedBorderColor: _addPressed,
                        builder: (_) => const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              size: 18,
                              color: AppColors.surface,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Yeni dost ekle',
                              style: TextStyle(
                                color: AppColors.surface,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: AppColors.surface,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: gap),
                      SizedBox(
                        height: sectionH,
                        child: Row(
                          children: [
                            Icon(
                              Icons.pets_rounded,
                              size: 16,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Benim Dostlarım',
                              style: AppTextStyles.sectionHeader.copyWith(
                                color: AppColors.error,
                                fontSize: 15,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              pets.isEmpty
                                  ? 'Henüz dost yok'
                                  : 'Toplam ${pets.length} dostum',
                              style: const TextStyle(
                                color: AppColors.subText,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: gap),
                      if (pets.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: Text(
                            'Henüz kayıtlı dostun yok. Yeni dost ekle ile başla.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.subText,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        )
                      else
                        for (var i = 0; i < pets.length; i++) ...[
                          if (i > 0) const SizedBox(height: cardGap),
                          _PetSummaryCard(
                            pet: pets[i],
                            height: cardH,
                            fill: Color.lerp(
                              AppColors.surface,
                              AppColors.error,
                              0.08,
                            )!,
                            isDefault: i == activeIndex,
                            onEdit: () => _openEdit(context, i, pets[i]),
                            onDelete: () => _deletePet(context, i, pets[i]),
                          ),
                        ],
                    ],
                  ),
                );
              },
            );
          },
        ),
        navbar: const AppBottomNavbar(
          activeTab: AppNavTab.home,
          homeColor: AppColors.error,
        ),
      ),
    );
  }
}

class _MeetPetHeader extends StatelessWidget {
  const _MeetPetHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const SizedBox(
            width: 40,
            child: AppBackButton(color: AppColors.error),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.pets_rounded,
                  size: 16,
                  color: AppColors.error.withValues(alpha: 0.38),
                ),
                const SizedBox(width: 8),
                Text(
                  'Dostlarım',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.pageHeader.copyWith(
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.pets_rounded,
                  size: 16,
                  color: AppColors.error.withValues(alpha: 0.38),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _PetSummaryCard extends StatelessWidget {
  const _PetSummaryCard({
    required this.pet,
    required this.height,
    required this.fill,
    required this.isDefault,
    required this.onEdit,
    required this.onDelete,
  });

  final PetData pet;
  final double height;
  final Color fill;
  final bool isDefault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final meta = [
      pet.species,
      if ((pet.gender ?? '').isNotEmpty) pet.gender,
      pet.shortAge,
    ].whereType<String>().where((item) => item.isNotEmpty && item != '-').join(' • ');

    return GestureDetector(
      onTap: onEdit,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Stack(
        children: [
          Positioned(
            right: 46,
            top: 6,
            child: Icon(
              Icons.pets_rounded,
              size: 54,
              color: AppColors.error.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _PhotoBadge(pet: pet, onTap: onEdit),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    pet.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.sectionHeader.copyWith(
                                      color: AppColors.error,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                if (isDefault) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      'Varsayılan',
                                      style: TextStyle(
                                        color: AppColors.error,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Image.asset(
                                  pet.species == 'Köpek'
                                      ? AppIcons.kopek
                                      : AppIcons.normalKedi,
                                  width: 14,
                                  height: 14,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    meta,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.subText,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _MetaChip(
                                  icon: Icons.monitor_weight_outlined,
                                  label: pet.weight ?? '-',
                                ),
                                const SizedBox(width: 8),
                                _MetaChip(
                                  icon: Icons.directions_run_rounded,
                                  label: pet.activityLevel ?? '-',
                                ),
                                const SizedBox(width: 8),
                                _MetaChip(
                                  icon: Icons.star_rounded,
                                  label: pet.shortBodyType,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _CircleAction(
                            icon: Icons.edit_outlined,
                            onTap: onEdit,
                          ),
                          _CircleAction(
                            icon: Icons.delete_outline_rounded,
                            onTap: onDelete,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 28,
                  child: Row(
                    children: [
                      Expanded(
                        child: _ActionPill(
                          icon: Icons.calendar_month_rounded,
                          label: 'Aşı Takvimi',
                          onTap: onEdit,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _ActionPill(
                          icon: Icons.rice_bowl_rounded,
                          label: 'Mama Takibi',
                          onTap: onEdit,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _ActionPill(
                          icon: Icons.favorite_rounded,
                          label: 'Sağlık Notları',
                          onTap: onEdit,
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
        ),
      ),
    );
  }
}

class _PhotoBadge extends StatelessWidget {
  const _PhotoBadge({required this.pet, required this.onTap});

  final PetData pet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.error, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: ClipOval(child: PetPhoto(pet: pet, iconSize: 26)),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: AppColors.error,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: Icon(
                    Icons.photo_camera_rounded,
                    size: 11,
                    color: AppColors.surface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.error),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
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
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPressableButton(
      onTap: onTap,
      width: 28,
      height: 28,
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.surface,
      pressedBackgroundColor: AppColors.error,
      foregroundColor: AppColors.error,
      pressedForegroundColor: AppColors.surface,
      borderColor: AppColors.error.withValues(alpha: 0.28),
      pressedBorderColor: AppColors.error,
      builder: (pressed) => Icon(
        icon,
        size: 15,
        color: pressed ? AppColors.surface : AppColors.error,
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPressableButton(
      onTap: onTap,
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      backgroundColor: AppColors.surface,
      pressedBackgroundColor: AppColors.error,
      foregroundColor: AppColors.error,
      pressedForegroundColor: AppColors.surface,
      borderColor: AppColors.error.withValues(alpha: 0.18),
      pressedBorderColor: AppColors.error,
      builder: (pressed) {
        final color = pressed ? AppColors.surface : AppColors.error;
        return Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 14, color: color),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:geliyor_app/data/banner_repository.dart';
import 'package:geliyor_app/screens/add_pet_screen.dart';
import 'package:geliyor_app/state/pet_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/utils/login_gate.dart';
import 'package:geliyor_app/widgets/app_banner_slider.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';
import 'package:geliyor_app/widgets/pet_photo.dart';

class MeetPetScreen extends StatelessWidget {
  const MeetPetScreen({super.key});

  static const _cardAccents = [
    AppColors.success,
    AppColors.error,
    AppColors.warning,
    AppColors.violet,
  ];

  void _openAdd(BuildContext context, {int? editIndex, PetData? pet}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddPetScreen(editIndex: editIndex, pet: pet),
      ),
    );
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
            side: const BorderSide(color: AppColors.border),
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
      backgroundColor: AppColors.background,
      body: AppPageFrame.standard(
        backgroundColor: AppColors.background,
        header: const AppPageHeader(title: 'Dostların'),
        content: ListenableBuilder(
          listenable: PetStore.instance,
          builder: (context, _) {
            final pets = PetStore.instance.pets;
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppBannerSlot(
                    placement: BannerPlacement.meetPet,
                    fallbackAssets: [
                      'assets/images/dostunu_taniyalim_banner.png',
                    ],
                  ),
                  const SizedBox(height: 10),
                  AppPressableButton.primary(
                    onTap: () => _openAdd(context),
                    width: double.infinity,
                    height: 42,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Yeni dost ekle',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
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
                      if (i > 0) const SizedBox(height: 10),
                      _PetSummaryCard(
                        pet: pets[i],
                        accent: _cardAccents[i % _cardAccents.length],
                        onEdit: () =>
                            _openAdd(context, editIndex: i, pet: pets[i]),
                        onDelete: () => _deletePet(context, i, pets[i]),
                      ),
                    ],
                ],
              ),
            );
          },
        ),
        navbar: const AppBottomNavbar(activeTab: AppNavTab.home),
      ),
    );
  }
}

class _PetSummaryCard extends StatelessWidget {
  const _PetSummaryCard({
    required this.pet,
    required this.accent,
    required this.onEdit,
    required this.onDelete,
  });

  final PetData pet;
  final Color accent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final frame = accent.withValues(alpha: 0.45);

    return GestureDetector(
      onTap: onEdit,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: frame),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 78,
              height: 96,
              child: Center(
                child: Container(
                  width: 78,
                  height: 78,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: PetPhoto(pet: pet, iconSize: 32),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 96,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      pet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sectionHeader.copyWith(color: accent),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _SummaryChip(
                                    icon: Icons.pets_rounded,
                                    label: pet.species,
                                    color: accent,
                                  ),
                                ),
                                Expanded(
                                  child: _SummaryChip(
                                    icon: Icons.calendar_month_rounded,
                                    label: pet.shortAge,
                                    color: accent,
                                  ),
                                ),
                                Expanded(
                                  child: _SummaryChip(
                                    icon: Icons.monitor_weight_outlined,
                                    label: pet.weight ?? '-',
                                    color: accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _SummaryChip(
                                    icon: Icons.accessibility_new_rounded,
                                    label: pet.shortBodyType,
                                    color: accent,
                                  ),
                                ),
                                Expanded(
                                  child: _SummaryChip(
                                    icon: Icons.directions_run_rounded,
                                    label: pet.activityLevel ?? '-',
                                    color: accent,
                                  ),
                                ),
                                const Expanded(child: SizedBox()),
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
            const SizedBox(width: 4),
            SizedBox(
              height: 96,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _IconAction(
                    icon: Icons.edit_outlined,
                    color: accent,
                    onTap: onEdit,
                  ),
                  _IconAction(
                    icon: Icons.delete_outline_rounded,
                    color: accent,
                    onTap: onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPressableButton(
      onTap: onTap,
      width: 36,
      height: 36,
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.surface,
      pressedBackgroundColor: color,
      foregroundColor: color,
      pressedForegroundColor: AppColors.surface,
      borderColor: color.withValues(alpha: 0.45),
      pressedBorderColor: color,
      builder: (pressed) => Icon(
        icon,
        size: 18,
        color: pressed ? AppColors.surface : color,
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:geliyor_app/data/mini_adult_dog_feeding_guide.dart';
import 'package:geliyor_app/theme/app_colors.dart';

class MiniAdultDogFeedingTableCard extends StatefulWidget {
  const MiniAdultDogFeedingTableCard({
    super.key,
    this.highlightedLabel,
    this.activityLevel,
    this.bodyType,
    this.neutered,
    this.extraFood,
    this.accent = AppColors.primary,
  });

  final String? highlightedLabel;
  final String? activityLevel;
  final String? bodyType;
  final String? neutered;
  final String? extraFood;
  final Color accent;

  @override
  State<MiniAdultDogFeedingTableCard> createState() =>
      _MiniAdultDogFeedingTableCardState();
}

class _MiniAdultDogFeedingTableCardState
    extends State<MiniAdultDogFeedingTableCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final highlight = MiniAdultDogFeedingGuide.nearestWeightLabel(
      widget.highlightedLabel,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: widget.accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Mini ırk yetişkin köpek tüketimi (kg)',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: widget.accent,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 8),
            for (final row in MiniAdultDogFeedingGuide.rows)
              Container(
                height: 34,
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: row.kgLabel == highlight
                      ? widget.accent.withValues(alpha: 0.12)
                      : AppColors.selected,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.kgLabel,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${MiniAdultDogFeedingGuide.dailyGramsFor(
                            weightLabel: row.kgLabel,
                            activityLevel: widget.activityLevel,
                            bodyType: widget.bodyType,
                            neutered: widget.neutered,
                            extraFood: widget.extraFood,
                          ) ?? row.dailyGrams} g/gün',
                      style: TextStyle(
                        color: widget.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

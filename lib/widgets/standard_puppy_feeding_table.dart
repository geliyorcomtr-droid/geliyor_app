import 'package:flutter/material.dart';
import 'package:geliyor_app/data/standard_puppy_feeding_guide.dart';
import 'package:geliyor_app/theme/app_colors.dart';

class StandardPuppyFeedingTableCard extends StatefulWidget {
  const StandardPuppyFeedingTableCard({
    super.key,
    this.highlightedLabel,
    this.ageLabel,
    this.months,
    this.activityLevel,
    this.bodyType,
    this.neutered,
    this.extraFood,
    this.accent = AppColors.primary,
  });

  final String? highlightedLabel;
  final String? ageLabel;
  final int? months;
  final String? activityLevel;
  final String? bodyType;
  final String? neutered;
  final String? extraFood;
  final Color accent;

  @override
  State<StandardPuppyFeedingTableCard> createState() =>
      _StandardPuppyFeedingTableCardState();
}

class _StandardPuppyFeedingTableCardState
    extends State<StandardPuppyFeedingTableCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final highlight = StandardPuppyFeedingGuide.nearestWeightLabel(
      widget.highlightedLabel,
    );
    final age = StandardPuppyFeedingGuide.ageBandFromLabel(widget.ageLabel) ??
        StandardPuppyFeedingGuide.nearestAgeLabel(widget.months);
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
                    Expanded(
                      child: Text(
                        'Yavru köpek tüketimi ($age)',
                        style: const TextStyle(
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
            for (final kg in StandardPuppyFeedingGuide.weightLabels)
              Container(
                height: 34,
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: kg == highlight
                      ? widget.accent.withValues(alpha: 0.12)
                      : AppColors.selected,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        kg,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${StandardPuppyFeedingGuide.dailyGramsFor(
                            weightLabel: kg,
                            ageLabel: age,
                            activityLevel: widget.activityLevel,
                            bodyType: widget.bodyType,
                            neutered: widget.neutered,
                            extraFood: widget.extraFood,
                          ) ?? 0} g/gün',
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

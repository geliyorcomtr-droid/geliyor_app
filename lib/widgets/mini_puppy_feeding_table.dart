import 'package:flutter/material.dart';
import 'package:geliyor_app/data/mini_puppy_feeding_guide.dart';
import 'package:geliyor_app/theme/app_colors.dart';

class MiniPuppyFeedingTableCard extends StatefulWidget {
  const MiniPuppyFeedingTableCard({
    super.key,
    this.highlightedLabel,
    this.ageLabel,
    this.months,
    this.activityLevel,
    this.bodyType,
    this.extraFood,
    this.accent = AppColors.primary,
  });

  final String? highlightedLabel;
  final String? ageLabel;
  final int? months;
  final String? activityLevel;
  final String? bodyType;
  final String? extraFood;
  final Color accent;

  @override
  State<MiniPuppyFeedingTableCard> createState() =>
      _MiniPuppyFeedingTableCardState();
}

class _MiniPuppyFeedingTableCardState extends State<MiniPuppyFeedingTableCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final highlight = MiniPuppyFeedingGuide.nearestWeightLabel(
      widget.highlightedLabel,
    );
    final age = MiniPuppyFeedingGuide.ageBandFromLabel(widget.ageLabel) ??
        MiniPuppyFeedingGuide.nearestAgeLabel(widget.months);
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
                        'Mini ırk yavru tüketimi ($age)',
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
            for (final kg in MiniPuppyFeedingGuide.weightLabels)
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
                      '${MiniPuppyFeedingGuide.dailyGramsFor(
                            weightLabel: kg,
                            ageLabel: age,
                            activityLevel: widget.activityLevel,
                            bodyType: widget.bodyType,
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

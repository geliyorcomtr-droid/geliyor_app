import 'package:flutter/material.dart';
import 'package:geliyor_app/data/dog_feeding_guide.dart';
import 'package:geliyor_app/theme/app_colors.dart';

class DogFeedingTableCard extends StatefulWidget {
  const DogFeedingTableCard({
    super.key,
    this.highlighted,
    this.activityLevel,
  });

  final DogFeedingRow? highlighted;
  final String? activityLevel;

  @override
  State<DogFeedingTableCard> createState() => _DogFeedingTableCardState();
}

class _DogFeedingTableCardState extends State<DogFeedingTableCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final activity = DogFeedingGuide.normalizeActivity(widget.activityLevel);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Köpek mama tüketim rehberi',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Aktivite: $activity',
                            style: const TextStyle(
                              color: AppColors.subText,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            child: _expanded
                ? Column(
                    children: [
                      const SizedBox(height: 8),
                      _row(
                        const ['Boyut', 'Kilo', 'Günlük'],
                        header: true,
                      ),
                      for (final row in DogFeedingGuide.rows)
                        _row(
                          [
                            row.size,
                            row.weightLabel,
                            row.rangeFor(widget.activityLevel),
                          ],
                          selected: widget.highlighted?.size == row.size,
                        ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _row(
    List<String> values, {
    bool header = false,
    bool selected = false,
  }) {
    return Container(
      height: 28,
      margin: EdgeInsets.only(top: header ? 0 : 2),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: header || selected ? AppColors.selected : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Text(
                values[i],
                textAlign: i == 0 ? TextAlign.left : TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: header || selected
                      ? AppColors.primary
                      : AppColors.text,
                  fontSize: header ? 9.5 : 10.5,
                  fontWeight:
                      header || selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

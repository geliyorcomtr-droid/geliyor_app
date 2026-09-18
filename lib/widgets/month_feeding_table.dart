import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_colors.dart';

class MonthFeedingTableCard extends StatefulWidget {
  const MonthFeedingTableCard({
    super.key,
    required this.title,
    required this.rows,
    this.highlightedMonths,
    this.accent = AppColors.primary,
    this.initiallyExpanded = true,
  });

  final String title;
  final List<({int months, int grams})> rows;
  final int? highlightedMonths;
  final Color accent;
  final bool initiallyExpanded;

  @override
  State<MonthFeedingTableCard> createState() => _MonthFeedingTableCardState();
}

class _MonthFeedingTableCardState extends State<MonthFeedingTableCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
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
                        widget.title,
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
            for (final row in widget.rows)
              Container(
                height: 34,
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: row.months == widget.highlightedMonths
                      ? AppColors.selected
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${row.months} ay',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: row.months == widget.highlightedMonths
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${row.grams} g / gün',
                      style: TextStyle(
                        color: row.months == widget.highlightedMonths
                            ? widget.accent
                            : AppColors.subText,
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

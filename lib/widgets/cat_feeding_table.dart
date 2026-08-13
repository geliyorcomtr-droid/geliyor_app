import 'package:flutter/material.dart';
import 'package:geliyor_app/data/cat_feeding_guide.dart';
import 'package:geliyor_app/theme/app_colors.dart';

class CatFeedingTableCard extends StatefulWidget {
  const CatFeedingTableCard({
    super.key,
    this.highlighted,
    this.bodyType,
    this.activityLevel,
  });

  final CatFeedingRow? highlighted;
  final String? bodyType;
  final String? activityLevel;

  @override
  State<CatFeedingTableCard> createState() => _CatFeedingTableCardState();
}

class _CatFeedingTableCardState extends State<CatFeedingTableCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                            'Kedi mama tüketim rehberi',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Profil: ${CatFeedingGuide.profileLabel(bodyType: widget.bodyType, activityLevel: widget.activityLevel)}',
                            style: const TextStyle(
                              color: AppColors.subText,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
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
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Column(
                    children: [
                      const SizedBox(height: 8),
                      const _HeaderRow(),
                      const SizedBox(height: 4),
                      for (final row in CatFeedingGuide.rows)
                        _DataRow(
                          row: row,
                          daily: row.gramsFor(
                            bodyType: widget.bodyType,
                            activityLevel: widget.activityLevel,
                          ),
                          selected: widget.highlighted != null &&
                              widget.highlighted!.catKg == row.catKg,
                        ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.selected,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        children: [
          Expanded(flex: 22, child: _Cell('Kedi kilosu', header: true, align: TextAlign.left)),
          Expanded(flex: 24, child: _Cell('Günlük', header: true)),
          Expanded(flex: 28, child: _Cell('30 günlük', header: true)),
          Expanded(flex: 26, child: _Cell('10 kg mama', header: true)),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.row,
    required this.daily,
    required this.selected,
  });

  final CatFeedingRow row;
  final int daily;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.selected : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 22,
            child: _Cell(row.catKgLabel, align: TextAlign.left, emphasize: true),
          ),
          Expanded(flex: 24, child: _Cell('$daily g')),
          Expanded(flex: 28, child: _Cell(row.monthlyFor(daily))),
          Expanded(
            flex: 26,
            child: _Cell('${row.daysForBagKg(10, daily: daily)} gün'),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(
    this.text, {
    this.header = false,
    this.emphasize = false,
    this.align = TextAlign.right,
  });

  final String text;
  final bool header;
  final bool emphasize;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: header || emphasize ? AppColors.primary : AppColors.text,
        fontSize: header ? 9.5 : 10.5,
        fontWeight: header || emphasize ? FontWeight.w800 : FontWeight.w600,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:geliyor_app/data/brand_feeding_guide.dart';
import 'package:geliyor_app/data/dog_feeding_guide.dart';
import 'package:geliyor_app/theme/app_colors.dart';

class BrandFeedingTableCard extends StatefulWidget {
  const BrandFeedingTableCard({
    super.key,
    required this.brandName,
    required this.feeding,
    required this.isDog,
    this.highlightWeight,
    this.highlightSize,
  });

  final String brandName;
  final BrandFeedingGuide feeding;
  final bool isDog;
  final String? highlightWeight;
  final String? highlightSize;

  @override
  State<BrandFeedingTableCard> createState() => _BrandFeedingTableCardState();
}

class _BrandFeedingTableCardState extends State<BrandFeedingTableCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final isDog = widget.isDog;
    final rows = isDog ? _dogRows() : _catRows();
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
                      child: Text(
                        '${widget.brandName} ${isDog ? 'köpek' : 'kedi'} tüketimi',
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
          if (_expanded) ...[
            const SizedBox(height: 8),
            for (final row in rows)
              Container(
                height: 34,
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: row.highlight
                      ? AppColors.selected
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.label,
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight:
                              row.highlight ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${row.grams} g / gün',
                      style: TextStyle(
                        color: row.highlight
                            ? AppColors.primary
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

  List<({String label, int grams, bool highlight})> _catRows() {
    final matchKey = widget.feeding.closestCatKey(widget.highlightWeight);
    return [
      for (final kg in BrandFeedingGuide.catKgRows)
        if ((widget.feeding.catGrams[BrandFeedingGuide.catKey(kg)] ?? 0) > 0)
          (
            label: '${kg.toStringAsFixed(1).replaceAll('.', ',')} kg',
            grams: widget.feeding.catGrams[BrandFeedingGuide.catKey(kg)]!,
            highlight: matchKey == BrandFeedingGuide.catKey(kg),
          ),
    ];
  }

  List<({String label, int grams, bool highlight})> _dogRows() {
    final size = DogFeedingGuide.fromSizeLabel(widget.highlightSize)?.size;
    return [
      for (final row in DogFeedingGuide.rows)
        if ((widget.feeding.dogGrams[row.size] ?? 0) > 0)
          (
            label: '${row.size} · ${row.weightLabel}',
            grams: widget.feeding.dogGrams[row.size]!,
            highlight: size == row.size,
          ),
    ];
  }
}

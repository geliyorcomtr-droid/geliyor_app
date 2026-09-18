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
    this.isPuppy = false,
    this.isMiniBreed = false,
    this.highlightWeight,
    this.highlightSize,
    this.highlightMonths,
  });

  final String brandName;
  final BrandFeedingGuide feeding;
  final bool isDog;
  final bool isPuppy;
  final bool isMiniBreed;
  final String? highlightWeight;
  final String? highlightSize;
  final int? highlightMonths;

  @override
  State<BrandFeedingTableCard> createState() => _BrandFeedingTableCardState();
}

class _BrandFeedingTableCardState extends State<BrandFeedingTableCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final rows = widget.isPuppy ? _monthRows() : (widget.isDog ? _dogRows() : _catRows());
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
                        '${widget.brandName} ${_titleSuffix()}',
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

  String _titleSuffix() {
    if (widget.isPuppy && widget.isDog && widget.isMiniBreed) {
      return 'mini ırk yavru tüketimi';
    }
    if (widget.isPuppy && widget.isDog) return 'yavru köpek tüketimi';
    if (widget.isPuppy) return 'yavru kedi tüketimi';
    return widget.isDog ? 'köpek tüketimi' : 'kedi tüketimi';
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
    final size = DogFeedingGuide.fromSizeLabel(
          widget.isMiniBreed ? 'Mini' : widget.highlightSize,
        )?.size;
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

  List<({String label, int grams, bool highlight})> _monthRows() {
    final source = widget.isDog
        ? (widget.isMiniBreed
            ? widget.feeding.dogMiniPuppyGrams
            : widget.feeding.dogPuppyGrams)
        : widget.feeding.catKittenGrams;
    final matchKey = widget.feeding.closestMonthKey(
      source,
      widget.highlightMonths,
    );
    return [
      for (final months in BrandFeedingGuide.monthRows)
        if ((source[BrandFeedingGuide.monthKey(months)] ?? 0) > 0)
          (
            label: '$months ay',
            grams: source[BrandFeedingGuide.monthKey(months)]!,
            highlight: matchKey == BrandFeedingGuide.monthKey(months),
          ),
    ];
  }
}

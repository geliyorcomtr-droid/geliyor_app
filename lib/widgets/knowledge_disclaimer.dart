import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_colors.dart';

/// Bilgi Bankası akışı sayfalarının sonundaki standart uyarı alanı.
class KnowledgeDisclaimer extends StatelessWidget {
  const KnowledgeDisclaimer({super.key});

  static const String text =
      'Bu içerik genel bilgilendirme amaçlıdır ve veteriner hekim '
      'görüşünün yerine geçmez. Ciddi veya devam eden durumlarda '
      'veteriner hekiminize başvurun.';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.selected,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
            size: 17,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

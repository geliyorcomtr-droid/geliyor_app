import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geliyor_app/data/campaign_repository.dart';
import 'package:geliyor_app/screens/pet_market_products_screen.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/filter_subpage_layout.dart';

class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({super.key});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(CampaignRepository.instance.ensureDefaults());
  }

  void _openProducts(
    BuildContext context, {
    String mainCategory = 'cat',
    String? subCategory,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PetMarketProductsScreen(
          initialMainCategory: mainCategory,
          initialSubCategory: subCategory,
        ),
      ),
    );
  }

  List<FilterSubpageItem> _items(List<AppCampaign>? campaigns) {
    final source = campaigns == null
        ? defaultCampaigns
        : campaigns.where((c) => c.active).toList();
    return [
      for (final campaign in source)
        FilterSubpageItem(
          title: campaign.title,
          subtitle: campaign.subtitle,
          imagePath: campaign.assetPath.isNotEmpty ? campaign.assetPath : null,
          icon: campaign.assetPath.isEmpty ? Icons.campaign_rounded : null,
          iconColor: AppColors.primary,
          badgeIcon: Icons.card_giftcard_rounded,
          onTap: () => _openProducts(
            context,
            mainCategory: campaign.mainCategory,
            subCategory: campaign.subCategory.isEmpty
                ? null
                : campaign.subCategory,
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppCampaign>>(
      stream: CampaignRepository.instance.watchAll(),
      builder: (context, snapshot) {
        return FilterSubpageLayout(
          title: 'Kampanyalar',
          items: _items(snapshot.data),
        );
      },
    );
  }
}


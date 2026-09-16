import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geliyor_app/state/pet_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/product_image.dart';

/// Dost görseli: yüklenen foto, aksi halde tür varsayılanı.
class PetPhoto extends StatelessWidget {
  const PetPhoto({
    super.key,
    required this.pet,
    this.photoBytes,
    this.fit,
    this.iconSize = 22,
  });

  final PetData pet;
  final Uint8List? photoBytes;
  final BoxFit? fit;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final bytes = photoBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(
        bytes,
        fit: fit ?? BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallbackIcon(),
      );
    }

    final url = pet.photoUrl?.trim() ?? '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return buildProductImage(
        url,
        fit: fit ?? BoxFit.cover,
        errorWidget: _asset(),
      );
    }
    return _asset();
  }

  Widget _asset() {
    return buildProductImage(
      pet.fallbackAsset,
      fit: fit ?? BoxFit.contain,
      errorWidget: _fallbackIcon(),
    );
  }

  Widget _fallbackIcon() {
    return Icon(Icons.pets_rounded, color: AppColors.primary, size: iconSize);
  }
}

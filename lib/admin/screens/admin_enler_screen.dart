import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/data/enler_repository.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/compress_upload_image.dart';
import 'package:geliyor_app/utils/product_image.dart';
import 'package:geliyor_app/utils/storage_metadata.dart';
import 'package:geliyor_app/widgets/enler_framed_image.dart';

class AdminEnlerScreen extends StatefulWidget {
  const AdminEnlerScreen({super.key});

  @override
  State<AdminEnlerScreen> createState() => _AdminEnlerScreenState();
}

class _AdminEnlerScreenState extends State<AdminEnlerScreen> {
  var _cards = EnlerRepository.defaults;
  String? _busy;

  @override
  void initState() {
    super.initState();
    EnlerRepository.instance.startListening();
    _cards = EnlerRepository.instance.cards;
    EnlerRepository.instance.addListener(_onRepo);
  }

  void _onRepo() {
    if (!mounted || _busy != null) return;
    setState(() => _cards = EnlerRepository.instance.cards);
  }

  @override
  void dispose() {
    EnlerRepository.instance.removeListener(_onRepo);
    super.dispose();
  }

  Future<void> _upload(EnlerCard card) async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return;
    setState(() => _busy = 'image:${card.id}');
    try {
      final bytes = await file.readAsBytes();
      final prepared = prepareUploadImage(
        bytes,
        file.name,
        style: UploadImageStyle.enler,
      );
      final ref = FirebaseStorage.instance.ref(
        'enler/${card.id}_${DateTime.now().microsecondsSinceEpoch}_${prepared.fileName}',
      );
      await ref.putData(
        prepared.bytes,
        storageImageMetadata(prepared.contentType),
      );
      final url = await ref.getDownloadURL();
      final next = [
        for (final item in _cards)
          if (item.id == card.id) item.copyWith(imageUrl: url) else item,
      ];
      setState(() => _cards = next);
      await EnlerRepository.instance.save(next);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Görsel ${EnlerRepository.uploadWidth} × ${EnlerRepository.uploadHeight} px olarak kaydedildi (${prepared.kiloBytes} KB).',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Görsel yüklenemedi: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _uploadIcon(EnlerCard card) async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return;
    setState(() => _busy = 'icon:${card.id}');
    try {
      final bytes = await file.readAsBytes();
      final prepared = prepareUploadImage(
        bytes,
        file.name,
        style: UploadImageStyle.icon,
      );
      final ref = FirebaseStorage.instance.ref(
        'enler/icon_${card.id}_${DateTime.now().microsecondsSinceEpoch}_${prepared.fileName}',
      );
      await ref.putData(
        prepared.bytes,
        storageImageMetadata(prepared.contentType),
      );
      final url = await ref.getDownloadURL();
      final next = [
        for (final item in _cards)
          if (item.id == card.id) item.copyWith(iconUrl: url) else item,
      ];
      setState(() => _cards = next);
      await EnlerRepository.instance.save(next);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${card.singleLine} ikonu kaydedildi (${prepared.kiloBytes} KB).',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İkon yüklenemedi: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _deleteIcon(EnlerCard card) async {
    if (card.iconUrl.trim().isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('İkonu sil'),
        content: Text(
          '"${card.singleLine}" için yüklenen ikon silinsin mi? Yerine varsayılan görsel gelir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = 'icon:${card.id}');
    try {
      final next = [
        for (final item in _cards)
          if (item.id == card.id) item.copyWith(iconUrl: '') else item,
      ];
      setState(() => _cards = next);
      await EnlerRepository.instance.save(next);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${card.singleLine} ikonu silindi.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İkon silinemedi: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Enler',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Kutu 132 × 120 px (boy × en). Yalnızca görsel yüklenir. '
          'Dosya yüklenirken 360 × 396 px ölçüsüne indirilir, en fazla 80 KB.',
          style: TextStyle(
            color: AppColors.subText,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [for (final card in _cards) _cardEditor(card)],
        ),
        const SizedBox(height: 28),
        const Text(
          'Ürünler sayfası ikonları',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'En\'lere tıklanınca ürünler sayfasında görünen yuvarlak ikonlar. '
          'Buradan yüklenir, değiştirilir ve silinir. Silinen ikonun yerine '
          'uygulamadaki varsayılan görsel gelir. Kare görsel önerilir, en fazla 512 px ve 80 KB.',
          style: TextStyle(
            color: AppColors.subText,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 24,
          runSpacing: 16,
          children: [for (final card in _cards) _iconEditor(card)],
        ),
      ],
    );
  }

  Widget _cardEditor(EnlerCard card) {
    final url = card.imageUrl.trim();
    return SizedBox(
      width: EnlerRepository.boxWidth + 8,
      child: Column(
        children: [
          SizedBox(
            width: EnlerRepository.boxWidth,
            height: EnlerRepository.boxHeight,
            child: EnlerFramedImage(
              path: url.isNotEmpty ? url : card.assetPath,
              fallbackPath: card.assetPath,
              cacheWidth: EnlerRepository.uploadWidth,
              maxDecodePx: EnlerRepository.uploadHeight,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '132 × 120 px',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            card.singleLine,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.subText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _busy == 'image:${card.id}' ? null : () => _upload(card),
            child: Text(
              _busy == 'image:${card.id}' ? 'Yükleniyor...' : 'Görsel yükle',
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconEditor(EnlerCard card) {
    final icon = card.iconUrl.trim();
    final custom = icon.isNotEmpty;
    final busy = _busy == 'icon:${card.id}';
    return SizedBox(
      width: 140,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.28),
              ),
            ),
            child: ClipOval(
              child: buildProductImage(
                custom ? icon : card.assetPath,
                fit: BoxFit.cover,
                width: 64,
                height: 64,
                cacheWidth: uiIconAssetPx,
                maxDecodePx: uiIconAssetPx,
                errorWidget: Image.asset(
                  card.assetPath,
                  fit: BoxFit.cover,
                  cacheWidth: uiIconAssetPx,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '48 px daire',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            card.singleLine,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.subText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            custom ? 'Yüklü ikon' : 'Varsayılan ikon',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.subText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: busy ? null : () => _uploadIcon(card),
            child: Text(busy ? 'Yükleniyor...' : 'İkon yükle'),
          ),
          if (custom)
            TextButton(
              onPressed: busy ? null : () => _deleteIcon(card),
              child: const Text('Sil'),
            ),
        ],
      ),
    );
  }
}

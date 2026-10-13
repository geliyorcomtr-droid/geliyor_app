import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/admin/admin_ui.dart';
import 'package:geliyor_app/data/welcome_splash_repository.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/compress_upload_image.dart';
import 'package:geliyor_app/utils/product_image.dart';
import 'package:geliyor_app/utils/storage_metadata.dart';

class AdminWelcomeSplashScreen extends StatefulWidget {
  const AdminWelcomeSplashScreen({super.key});

  @override
  State<AdminWelcomeSplashScreen> createState() =>
      _AdminWelcomeSplashScreenState();
}

class _AdminWelcomeSplashScreenState extends State<AdminWelcomeSplashScreen> {
  var _uploading = false;

  Future<void> _upload() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      final prepared = prepareUploadImage(
        bytes,
        file.name,
        style: UploadImageStyle.screen,
      );
      final ref = FirebaseStorage.instance.ref(
        'welcome_splash/'
        '${DateTime.now().microsecondsSinceEpoch}_${prepared.fileName}',
      );
      await ref.putData(
        prepared.bytes,
        storageImageMetadata(prepared.contentType),
      );
      final url = await ref.getDownloadURL();
      await WelcomeSplashRepository.instance.saveImageUrl(url);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yüklendi (${prepared.kiloBytes} KB).')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Görsel yüklenemedi: $error')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _delete(String imageUrl) async {
    if (imageUrl.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Karşılama görselini sil'),
        content: const Text(
          'Yüklenen görsel kaldırılsın mı? Uygulama varsayılan açılış ekranına döner.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await WelcomeSplashRepository.instance.clearImage();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: WelcomeSplashRepository.instance.watchImageUrl(),
      builder: (context, snapshot) {
        final imageUrl = snapshot.data ?? '';
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const AdminPageHeader(
              title: 'Karşılama görseli',
              subtitle:
                  'Uygulama açılış ekranı. Tuval 393×852; görsel 3x '
                  '(${UploadImageQuota.screenMaxWidth}×'
                  '${UploadImageQuota.screenMaxHeight} px), en fazla '
                  '${UploadImageQuota.screenMaxBytes ~/ 1024} KB. '
                  'Daha büyük dosya otomatik küçültülür.',
            ),
            Align(
              alignment: Alignment.topLeft,
              child: _previewPhone(imageUrl),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _uploading ? null : _upload,
                  icon: const Icon(Icons.upload_rounded, size: 18),
                  label: Text(
                    _uploading
                        ? 'Yükleniyor...'
                        : (imageUrl.isEmpty ? 'Yükle' : 'Değiştir'),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _uploading || imageUrl.isEmpty
                      ? null
                      : () => _delete(imageUrl),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Sil'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _previewPhone(String imageUrl) {
    const scale = 0.5;
    const width = WelcomeSplashRepository.canvasWidth * scale;
    const height = WelcomeSplashRepository.canvasHeight * scale;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Görsel yok.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.subText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            buildProductImage(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorWidget: const Center(
                child: Icon(Icons.broken_image_outlined),
              ),
            ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  '${WelcomeSplashRepository.canvasWidth} × ${WelcomeSplashRepository.canvasHeight} px',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

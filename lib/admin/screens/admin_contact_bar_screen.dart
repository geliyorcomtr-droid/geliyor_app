import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/data/contact_bar_repository.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/compress_upload_image.dart';
import 'package:geliyor_app/utils/storage_metadata.dart';
import 'package:geliyor_app/widgets/framed_bar_image.dart';

class AdminContactBarScreen extends StatefulWidget {
  const AdminContactBarScreen({super.key});

  @override
  State<AdminContactBarScreen> createState() => _AdminContactBarScreenState();
}

class _AdminContactBarScreenState extends State<AdminContactBarScreen> {
  final _phone = TextEditingController(text: ContactBarRepository.defaultPhone);
  final _whatsappPhone = TextEditingController(
    text: ContactBarRepository.defaultPhone,
  );
  var _imageUrl = '';
  var _whatsappImageUrl = '';
  var _uploadingPhone = false;
  var _uploadingWhatsapp = false;
  var _savingPhone = false;
  var _savingWhatsapp = false;

  @override
  void initState() {
    super.initState();
    ContactBarRepository.instance.startListening();
    _sync();
    ContactBarRepository.instance.addListener(_onRepo);
  }

  void _sync() {
    final repo = ContactBarRepository.instance;
    _imageUrl = repo.imageUrl;
    _whatsappImageUrl = repo.whatsappImageUrl;
    if (!_savingPhone && _phone.text.trim() != repo.phone) {
      _phone.text = repo.phone;
    }
    if (!_savingWhatsapp && _whatsappPhone.text.trim() != repo.whatsappPhone) {
      _whatsappPhone.text = repo.whatsappPhone;
    }
  }

  void _onRepo() {
    if (!mounted || _uploadingPhone || _uploadingWhatsapp) return;
    setState(_sync);
  }

  @override
  void dispose() {
    ContactBarRepository.instance.removeListener(_onRepo);
    _phone.dispose();
    _whatsappPhone.dispose();
    super.dispose();
  }

  Future<void> _upload() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return;
    setState(() => _uploadingPhone = true);
    try {
      final bytes = await file.readAsBytes();
      final prepared = prepareUploadImage(
        bytes,
        file.name,
        style: UploadImageStyle.contactBar,
      );
      final ref = FirebaseStorage.instance.ref(
        'contact_bar/${DateTime.now().microsecondsSinceEpoch}_${prepared.fileName}',
      );
      await ref.putData(
        prepared.bytes,
        storageImageMetadata(prepared.contentType),
      );
      final url = await ref.getDownloadURL();
      await ContactBarRepository.instance.save(
        imageUrl: url,
        phone: _phone.text,
      );
      if (!mounted) return;
      setState(() => _imageUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Görsel ${ContactBarRepository.uploadWidth} × ${ContactBarRepository.uploadHeight} px olarak kaydedildi (${prepared.kiloBytes} KB).',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Görsel yüklenemedi: $error')),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhone = false);
    }
  }

  Future<void> _savePhone() async {
    setState(() => _savingPhone = true);
    try {
      await ContactBarRepository.instance.save(
        imageUrl: _imageUrl,
        phone: _phone.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aranacak numara kaydedildi.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Numara kaydedilemedi: $error')),
      );
    } finally {
      if (mounted) setState(() => _savingPhone = false);
    }
  }

  Future<void> _uploadWhatsapp() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return;
    setState(() => _uploadingWhatsapp = true);
    try {
      final bytes = await file.readAsBytes();
      final prepared = prepareUploadImage(
        bytes,
        file.name,
        style: UploadImageStyle.contactBar,
      );
      final ref = FirebaseStorage.instance.ref(
        'contact_bar/whatsapp_${DateTime.now().microsecondsSinceEpoch}_${prepared.fileName}',
      );
      await ref.putData(
        prepared.bytes,
        storageImageMetadata(prepared.contentType),
      );
      final url = await ref.getDownloadURL();
      await ContactBarRepository.instance.saveWhatsapp(
        imageUrl: url,
        phone: _whatsappPhone.text,
      );
      if (!mounted) return;
      setState(() => _whatsappImageUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'WhatsApp görseli kaydedildi (${prepared.kiloBytes} KB).',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Görsel yüklenemedi: $error')),
      );
    } finally {
      if (mounted) setState(() => _uploadingWhatsapp = false);
    }
  }

  Future<void> _saveWhatsappPhone() async {
    setState(() => _savingWhatsapp = true);
    try {
      await ContactBarRepository.instance.saveWhatsapp(
        imageUrl: _whatsappImageUrl,
        phone: _whatsappPhone.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp numarası kaydedildi.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Numara kaydedilemedi: $error')),
      );
    } finally {
      if (mounted) setState(() => _savingWhatsapp = false);
    }
  }

  Widget _preview({
    required String path,
    required String fallback,
    required Color border,
    required bool tint,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageH = constraints.maxWidth *
            ContactBarRepository.artHeight /
            ContactBarRepository.artWidth;
        return SizedBox(
          height: imageH + 8,
          width: double.infinity,
          child: FramedBarImage(
            path: path,
            fallbackPath: fallback,
            borderColor: border,
            tintFromImage: tint,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final phonePath = _imageUrl.isNotEmpty
        ? _imageUrl
        : ContactBarRepository.assetPath;
    final whatsappPath = _whatsappImageUrl.isNotEmpty
        ? _whatsappImageUrl
        : ContactBarRepository.whatsappAssetPath;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'İletişim',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Ana sayfada iki kutu yan yana durur. Görsel ve numara birbirinden bağımsızdır. '
          'Yüklenen dosya ${ContactBarRepository.uploadWidth} × ${ContactBarRepository.uploadHeight} px ölçüsüne indirilir.',
          style: const TextStyle(
            color: AppColors.subText,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _editor(
                title: 'İletişim',
                preview: _preview(
                  path: phonePath,
                  fallback: ContactBarRepository.assetPath,
                  border: AppColors.primary,
                  tint: false,
                ),
                uploading: _uploadingPhone,
                onUpload: _upload,
                phone: _phone,
                saving: _savingPhone,
                onSave: _savePhone,
                saveLabel: 'Numarayı kaydet',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _editor(
                title: 'WhatsApp',
                preview: _preview(
                  path: whatsappPath,
                  fallback: ContactBarRepository.whatsappAssetPath,
                  border: const Color(0xFF25D366),
                  tint: false,
                ),
                uploading: _uploadingWhatsapp,
                onUpload: _uploadWhatsapp,
                phone: _whatsappPhone,
                saving: _savingWhatsapp,
                onSave: _saveWhatsappPhone,
                saveLabel: 'Numarayı kaydet',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _editor({
    required String title,
    required Widget preview,
    required bool uploading,
    required VoidCallback onUpload,
    required TextEditingController phone,
    required bool saving,
    required VoidCallback onSave,
    required String saveLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        preview,
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: uploading ? null : onUpload,
          child: Text(uploading ? 'Yükleniyor...' : 'Görsel yükle'),
        ),
        const SizedBox(height: 16),
        const Text(
          'Numara',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: '05402990000',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: saving ? null : onSave,
          child: Text(saving ? 'Kaydediliyor...' : saveLabel),
        ),
      ],
    );
  }
}

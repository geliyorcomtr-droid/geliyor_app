import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/data/adoption_repository.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/turkey_locations.dart';
import 'package:geliyor_app/state/auth_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/utils/compress_upload_image.dart';
import 'package:geliyor_app/utils/login_gate.dart';
import 'package:geliyor_app/utils/product_image.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';
import 'package:image_picker/image_picker.dart';

class AdoptionSubmitScreen extends StatefulWidget {
  const AdoptionSubmitScreen({super.key, this.editing});

  final AdoptionListing? editing;

  @override
  State<AdoptionSubmitScreen> createState() => _AdoptionSubmitScreenState();
}

class _AdoptionSubmitScreenState extends State<AdoptionSubmitScreen> {
  static const _maxPhotos = 6;
  static const _titleLimit = 60;
  static const _descriptionLimit = 500;

  final _formAnchor = GlobalKey();
  final _name = TextEditingController();
  final _breed = TextEditingController();
  final _age = TextEditingController();
  final _weight = TextEditingController();
  final _description = TextEditingController();
  final _phone = TextEditingController();
  String _category = AdoptionCategories.adopt;
  String _species = '';
  String _gender = '';
  String _city = '';
  String _contactPreference = 'phone';
  final _photos = <Uint8List>[];
  final _videos = <Uint8List>[];
  final _existingImages = <String>[];
  final _existingVideos = <String>[];
  AdoptionListing? _editing;
  bool _saving = false;

  int get _photoCount => _existingImages.length + _photos.length;

  @override
  void initState() {
    super.initState();
    _phone.text = AuthStore.instance.phone;
    _name.addListener(_onTextTick);
    _description.addListener(_onTextTick);
    if (widget.editing != null) _loadListing(widget.editing!);
  }

  void _onTextTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _name.removeListener(_onTextTick);
    _description.removeListener(_onTextTick);
    _name.dispose();
    _breed.dispose();
    _age.dispose();
    _weight.dispose();
    _description.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _loadListing(AdoptionListing listing) {
    _editing = listing;
    _name.text = listing.name;
    _breed.text = listing.breed;
    _age.text = listing.age;
    _weight.text = listing.weight;
    _city = listing.city;
    _description.text = listing.description;
    _phone.text = listing.phone.isNotEmpty
        ? listing.phone
        : AuthStore.instance.phone;
    _category = listing.category;
    _species = listing.species;
    _gender = listing.gender;
    _contactPreference = listing.contactPreference.isEmpty
        ? 'phone'
        : listing.contactPreference;
    _photos.clear();
    _videos.clear();
    _existingImages
      ..clear()
      ..addAll(listing.imageUrls);
    _existingVideos
      ..clear()
      ..addAll(listing.videoUrls);
  }

  void _clearForm({bool keepPhone = true}) {
    _editing = null;
    _name.clear();
    _breed.clear();
    _age.clear();
    _weight.clear();
    _city = '';
    _description.clear();
    if (!keepPhone) _phone.clear();
    _photos.clear();
    _videos.clear();
    _existingImages.clear();
    _existingVideos.clear();
    _category = AdoptionCategories.adopt;
    _species = '';
    _gender = '';
    _contactPreference = 'phone';
  }

  Future<void> _scrollToForm() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    final ctx = _formAnchor.currentContext;
    if (ctx == null || !ctx.mounted) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 280),
      alignment: 0.05,
    );
  }

  Future<void> _openMediaSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                _mediaChoice(
                  icon: Icons.photo_camera_outlined,
                  label: 'Fotoğraf çek',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _addPhoto(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 8),
                _mediaChoice(
                  icon: Icons.photo_library_outlined,
                  label: 'Galeriden fotoğraf',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _addPhoto(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 8),
                _mediaChoice(
                  icon: Icons.videocam_outlined,
                  label: 'Kısa video çek (15 sn)',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _addVideo(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 8),
                _mediaChoice(
                  icon: Icons.video_library_outlined,
                  label: 'Galeriden kısa video',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _addVideo(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _mediaChoice({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return AppPressableButton(
      onTap: onTap,
      width: double.infinity,
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      backgroundColor: AppColors.background,
      pressedBackgroundColor: AppColors.selected,
      borderColor: AppColors.border,
      pressedBorderColor: AppColors.primaryLight,
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addPhoto(ImageSource source) async {
    if (_photoCount >= _maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En fazla 6 fotoğraf ekleyebilirsiniz.')),
      );
      return;
    }
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || !mounted) return;
      setState(() => _photos.add(bytes));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fotoğraf eklenemedi.')),
      );
    }
  }

  Future<void> _addVideo(ImageSource source) async {
    if (_existingVideos.length + _videos.length >= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En fazla 1 kısa video ekleyebilirsiniz.')),
      );
      return;
    }
    try {
      final file = await ImagePicker().pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 15),
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || !mounted) return;
      if (bytes.lengthInBytes > 20 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video 20 MB’dan küçük olmalıdır.')),
        );
        return;
      }
      setState(() => _videos.add(bytes));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video eklenemedi.')),
      );
    }
  }

  Future<void> _submit() async {
    final ok = await LoginGate.require(
      context: context,
      message: 'İlan vermek için giriş yapmanız gerekir.',
    );
    if (!ok || !mounted) return;
    setState(() => _saving = true);
    try {
      final uid = AuthStore.instance.uid ?? '';
      final imageUrls = [..._existingImages];
      final videoUrls = [..._existingVideos];
      for (final bytes in _photos) {
        final prepared = prepareUploadImage(bytes, 'listing.jpg');
        final ref = FirebaseStorage.instance.ref(
          'adoption_listings/$uid/${DateTime.now().microsecondsSinceEpoch}_${prepared.fileName}',
        );
        await ref.putData(
          prepared.bytes,
          SettableMetadata(contentType: prepared.contentType),
        );
        imageUrls.add(await ref.getDownloadURL());
      }
      for (final bytes in _videos) {
        final ref = FirebaseStorage.instance.ref(
          'adoption_listings/$uid/${DateTime.now().microsecondsSinceEpoch}_listing.mp4',
        );
        await ref.putData(
          bytes,
          SettableMetadata(contentType: 'video/mp4'),
        );
        videoUrls.add(await ref.getDownloadURL());
      }
      final listing = AdoptionListing(
        id: _editing?.id ?? '',
        userId: uid,
        category: _category,
        name: _name.text,
        species: _species,
        breed: _breed.text,
        gender: _gender,
        age: _age.text,
        weight: _weight.text,
        city: _city,
        description: _description.text,
        imageUrls: imageUrls,
        videoUrls: videoUrls,
        phone: _phone.text,
        contactName: AuthStore.instance.fullName,
        contactPreference: _contactPreference,
        vaccinated: _editing?.vaccinated ?? false,
        neutered: _editing?.neutered ?? false,
        hasHealthIssue: _editing?.hasHealthIssue ?? false,
        indoorOnly: _editing?.indoorOnly ?? false,
      );
      if (_editing == null) {
        await AdoptionRepository.instance.create(listing);
      } else {
        await AdoptionRepository.instance.update(listing);
      }
      final wasEditing = listing.id.isNotEmpty;
      if (!mounted) return;
      _clearForm();
      _phone.text = AuthStore.instance.phone;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasEditing
                ? 'İlan güncellendi. Admin onayından sonra yayınlanır.'
                : 'İlan gönderildi. Admin onayından sonra yayınlanır.',
          ),
        ),
      );
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gönderilemedi: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteListing(AdoptionListing listing) async {
    final uid = AuthStore.instance.uid ?? '';
    if (uid.isEmpty || listing.userId != uid) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu ilanı yalnızca ilanı veren silebilir.')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.border),
          ),
          title: const Text(
            'İlanı sil',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            listing.name.trim().isEmpty
                ? 'Bu ilan silinsin mi?'
                : '“${listing.name}” ilanı silinsin mi?',
            style: const TextStyle(
              color: AppColors.subText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Vazgeç',
                style: TextStyle(
                  color: AppColors.subText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Sil',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    try {
      await AdoptionRepository.instance.delete(listing);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('İlan silindi.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Silinemedi: $error')));
    }
  }

  Future<void> _pickCity() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        var query = '';
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              final cities = TurkeyLocations.provinces
                  .where((city) => TurkeyLocations.matchesQuery(city, query))
                  .toList();
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Şehir seç',
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      onChanged: (value) => setSheetState(() => query = value),
                      decoration: InputDecoration(
                        hintText: 'İl ara',
                        filled: true,
                        fillColor: AppColors.background,
                        prefixIcon: const Icon(Icons.search_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 320,
                      child: ListView.builder(
                        itemCount: cities.length,
                        itemBuilder: (context, index) {
                          final city = cities[index];
                          final active = city == _city;
                          return ListTile(
                            dense: true,
                            title: Text(
                              city,
                              style: TextStyle(
                                fontWeight: active
                                    ? FontWeight.w900
                                    : FontWeight.w600,
                                color: active
                                    ? AppColors.primary
                                    : AppColors.text,
                              ),
                            ),
                            trailing: active
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: AppColors.primary,
                                  )
                                : null,
                            onTap: () => Navigator.of(sheetContext).pop(city),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
    if (selected == null || !mounted) return;
    setState(() => _city = selected);
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthStore.instance.uid ?? '';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame.standard(
        backgroundColor: AppColors.background,
        pawPrintColor: AppColors.warning,
        activeTab: AppNavTab.profile,
        header: AppPageHeader(
          title: _editing == null ? 'İlan Ekle' : 'İlanı düzenle',
        ),
        content: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppPageFrame.contentHorizontalPadding,
            0,
            AppPageFrame.contentHorizontalPadding,
            12,
          ),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: const SizedBox(
                width: double.infinity,
                height: 118,
                child: Image(
                  image: AssetImage('assets/images/ilan_ekle_banner.jpg'),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<AdoptionListing>>(
              stream: AdoptionRepository.instance.watchMine(uid),
              builder: (context, snapshot) {
                final mine = snapshot.data ?? const <AdoptionListing>[];
                if (mine.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('İlanlarım', style: AppTextStyles.sectionHeader),
                    const SizedBox(height: 8),
                    for (final item in mine.take(6)) _mineCard(item),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
            KeyedSubtree(key: _formAnchor, child: const SizedBox.shrink()),
            if (_editing != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.selected,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '“${_editing!.name}” düzenleniyor.',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _clearForm()),
                      child: const Text(
                        'Vazgeç',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            _sectionTitle(1, 'İlan Türü'),
            const SizedBox(height: 8),
            SizedBox(
              height: 118,
              child: Row(
                children: [
                  Expanded(
                    child: _typeCard(
                      id: AdoptionCategories.adopt,
                      icon: Icons.home_rounded,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _typeCard(
                      id: AdoptionCategories.lost,
                      icon: Icons.search_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _typeCard(
                      id: AdoptionCategories.found,
                      icon: Icons.pets_rounded,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionTitle(2, 'Dostunun Bilgileri'),
            const SizedBox(height: 8),
            _miniLabel('Tür'),
            Row(
              children: [
                Expanded(
                  child: _choiceChip(
                    icon: Icons.pets_rounded,
                    label: 'Kedi',
                    selected: _species == 'Kedi',
                    onTap: () => setState(
                      () => _species = _species == 'Kedi' ? '' : 'Kedi',
                    ),
                    expanded: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _choiceChip(
                    icon: Icons.pets_rounded,
                    label: 'Köpek',
                    selected: _species == 'Köpek',
                    onTap: () => setState(
                      () => _species = _species == 'Köpek' ? '' : 'Köpek',
                    ),
                    expanded: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _miniLabel('Cins (varsa)'),
            _boxField(_breed, hint: 'Örn. Tekir, Golden Retriever'),
            const SizedBox(height: 10),
            _miniLabel('Cinsiyet'),
            Row(
              children: [
                Expanded(
                  child: _choiceChip(
                    icon: Icons.female_rounded,
                    label: 'Dişi',
                    selected: _gender == 'Dişi',
                    onTap: () => setState(
                      () => _gender = _gender == 'Dişi' ? '' : 'Dişi',
                    ),
                    expanded: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _choiceChip(
                    icon: Icons.male_rounded,
                    label: 'Erkek',
                    selected: _gender == 'Erkek',
                    onTap: () => setState(
                      () => _gender = _gender == 'Erkek' ? '' : 'Erkek',
                    ),
                    expanded: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _choiceChip(
                    icon: Icons.pets_rounded,
                    label: 'Farketmez',
                    selected: _gender == 'Farketmez',
                    onTap: () => setState(
                      () =>
                          _gender = _gender == 'Farketmez' ? '' : 'Farketmez',
                    ),
                    expanded: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _miniLabel('Yaş'),
                      _boxField(_age, hint: 'Örn. 3 ay'),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _miniLabel('Kilo (yaklaşık)'),
                      _boxField(_weight, hint: 'Örn. 2 kg'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _sectionTitle(3, 'Fotoğraflar')),
                Text(
                  'En fazla $_maxPhotos fotoğraf',
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _existingImages.length; i++)
                  _mediaThumb(
                    child: buildProductImage(
                      _existingImages[i],
                      fit: BoxFit.cover,
                      width: 78,
                      height: 78,
                    ),
                    onRemove: () =>
                        setState(() => _existingImages.removeAt(i)),
                  ),
                for (var i = 0; i < _photos.length; i++)
                  _mediaThumb(
                    child: Image.memory(
                      _photos[i],
                      width: 78,
                      height: 78,
                      fit: BoxFit.cover,
                    ),
                    onRemove: () => setState(() => _photos.removeAt(i)),
                  ),
                for (var i = 0; i < _existingVideos.length; i++)
                  _mediaThumb(
                    child: const ColoredBox(
                      color: AppColors.selected,
                      child: Center(
                        child: Icon(
                          Icons.videocam_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    onRemove: () =>
                        setState(() => _existingVideos.removeAt(i)),
                  ),
                for (var i = 0; i < _videos.length; i++)
                  _mediaThumb(
                    child: const ColoredBox(
                      color: AppColors.selected,
                      child: Center(
                        child: Icon(
                          Icons.videocam_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    onRemove: () => setState(() => _videos.removeAt(i)),
                  ),
                _addMediaTile(),
                _photoHintCard(),
              ],
            ),
            const SizedBox(height: 16),
            _sectionTitle(4, 'İlan Detayı'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(child: Text('Başlık', style: _fieldLabelStyle)),
                Text(
                  '${_name.text.length}/$_titleLimit',
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _boxField(
              _name,
              hint: 'Örn. Sevgi dolu minik bir yuva arıyor',
              maxLength: _titleLimit,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  child: Text('Açıklama', style: _fieldLabelStyle),
                ),
                Text(
                  '${_description.text.length}/$_descriptionLimit',
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _boxField(
              _description,
              hint:
                  'Dostunuzun karakteri, sağlık durumu, alışkanlıkları ve sahiplendirme nedeniniz hakkında bilgi verin...',
              maxLines: 4,
              maxLength: _descriptionLimit,
            ),
            const SizedBox(height: 16),
            _sectionTitle(5, 'İletişim Bilgileri'),
            const SizedBox(height: 8),
            _miniLabel('Şehir'),
            AppPressableButton(
              onTap: _pickCity,
              width: double.infinity,
              height: 36.0,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              backgroundColor: AppColors.surface,
              pressedBackgroundColor: AppColors.selected,
              borderColor: AppColors.border,
              pressedBorderColor: AppColors.primaryLight,
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _city.isEmpty ? 'Şehir seçin' : _city,
                      style: TextStyle(
                        color: _city.isEmpty
                            ? AppColors.subText
                            : AppColors.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.subText,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _miniLabel('İletişim tercihi'),
            Row(
              children: [
                Expanded(
                  child: _choiceChip(
                    icon: Icons.phone_rounded,
                    label: 'Telefon',
                    selected: _contactPreference == 'phone',
                    onTap: () => setState(() => _contactPreference = 'phone'),
                    expanded: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _choiceChip(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Mesaj',
                    selected: _contactPreference == 'message',
                    onTap: () =>
                        setState(() => _contactPreference = 'message'),
                    expanded: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _boxField(_phone, hint: 'Telefon numarası'),
            const SizedBox(height: 16),
            AppPressableButton.primary(
              onTap: _saving ? () {} : _submit,
              enabled: !_saving,
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _saving
                        ? 'Kaydediliyor…'
                        : (_editing == null
                              ? 'İlanı Yayınla'
                              : 'İlanı güncelle'),
                  ),
                ],
              ),
            ),
          ],
        ),
        navbar: const AppBottomNavbar(
          activeTab: AppNavTab.profile,
          homeColor: AppColors.warning,
        ),
      ),
    );
  }

  Widget _mineCard(AdoptionListing item) {
    return GestureDetector(
      onTap: () {
        setState(() => _loadListing(item));
        _scrollToForm();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _editing?.id == item.id
              ? AppColors.selected
              : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _editing?.id == item.id
                ? AppColors.primary
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 48,
                height: 48,
                child: item.coverImage.isEmpty
                    ? ColoredBox(
                        color: AppColors.selected,
                        child: Icon(
                          item.videoUrls.isNotEmpty
                              ? Icons.videocam_rounded
                              : Icons.pets_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      )
                    : buildProductImage(
                        item.coverImage,
                        fit: BoxFit.cover,
                        width: 48,
                        height: 48,
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name.isEmpty ? 'İlan' : item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${item.categoryLabel} · ${AdoptionStatuses.label(item.status)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: item.status == AdoptionStatuses.approved
                          ? AppColors.success
                          : item.status == AdoptionStatuses.rejected
                          ? AppColors.error
                          : AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
            AppPressableButton.soft(
              onTap: () {
                setState(() => _loadListing(item));
                _scrollToForm();
              },
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: const Text('Düzenle', style: TextStyle(fontSize: 12)),
            ),
            IconButton(
              onPressed: () => _deleteListing(item),
              tooltip: 'İlanı sil',
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(int number, String title) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              color: AppColors.surface,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: AppTextStyles.sectionHeader)),
      ],
    );
  }

  Widget _typeCard({
    required String id,
    required IconData icon,
    required Color color,
  }) {
    final selected = _category == id;
    return GestureDetector(
      onTap: () => setState(() => _category = id),
      child: Container(
        height: 118,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.22),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Icon(icon, color: color, size: 48),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AdoptionCategories.label(id),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              Text(
                AdoptionCategories.subtitle(id),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.subText,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  selected ? Icons.check_rounded : Icons.circle_outlined,
                  size: 12,
                  color: AppColors.surface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _choiceChip({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool expanded = false,
  }) {
    final chip = AppPressableButton(
      onTap: onTap,
      height: 36.0,
      width: expanded ? double.infinity : null,
      padding: EdgeInsets.symmetric(horizontal: expanded ? 6 : 12),
      backgroundColor: selected ? AppColors.selected : AppColors.surface,
      pressedBackgroundColor: AppColors.primary,
      borderColor: selected ? AppColors.primary : AppColors.border,
      pressedBorderColor: AppColors.primary,
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 15,
            color: selected ? AppColors.primary : AppColors.subText,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: selected ? AppColors.primary : AppColors.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return chip;
  }

  Widget _addMediaTile() {
    return GestureDetector(
      onTap: _openMediaSheet,
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          color: AppColors.selected,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
            SizedBox(height: 4),
            Text(
              'Ekle',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoHintCard() {
    return Container(
      width: 118,
      height: 78,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.selected,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: Text(
          'Daha fazla fotoğraf, sahiplendirme şansını artırır.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
      ),
    );
  }

  Widget _mediaThumb({
    required Widget child,
    required VoidCallback onRemove,
  }) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(width: 78, height: 78, child: child),
        ),
        Positioned(
          right: 2,
          top: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: const CircleAvatar(
              radius: 10,
              backgroundColor: AppColors.error,
              child: Icon(
                Icons.close_rounded,
                size: 12,
                color: AppColors.surface,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: _fieldLabelStyle),
    );
  }

  Widget _boxField(
    TextEditingController controller, {
    required String hint,
    int maxLines = 1,
    int? maxLength,
  }) {
    final singleLine = maxLines == 1;
    return SizedBox(
      height: singleLine ? 36.0 : null,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        buildCounter:
            (
              context, {
              required currentLength,
              required isFocused,
              maxLength,
            }) => const SizedBox.shrink(),
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.1,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.subText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
          filled: true,
          fillColor: AppColors.surface,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: singleLine ? 8 : 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(singleLine ? 999 : 18),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(singleLine ? 999 : 18),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(singleLine ? 999 : 18),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

const _fieldLabelStyle = TextStyle(
  color: AppColors.subText,
  fontSize: 12,
  fontWeight: FontWeight.w800,
);

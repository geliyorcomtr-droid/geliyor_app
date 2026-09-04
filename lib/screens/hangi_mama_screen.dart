import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/product_repository.dart';
import 'package:geliyor_app/state/auth_store.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/screens/product_detail_screen.dart';
import 'package:geliyor_app/state/cart_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/login_gate.dart';
import 'package:geliyor_app/utils/market_product_helpers.dart';
import 'package:geliyor_app/utils/product_tag_filter.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';
import 'package:geliyor_app/widgets/market_product_card.dart';
import 'package:image_picker/image_picker.dart';

enum _PetType { cat, dog }

enum _SupplyStatus { received, processing, supplied, failed }

class HangiMamaScreen extends StatefulWidget {
  const HangiMamaScreen({super.key});

  @override
  State<HangiMamaScreen> createState() => _HangiMamaScreenState();
}

class _HangiMamaScreenState extends State<HangiMamaScreen> {
  _PetType _petType = _PetType.cat;
  final Set<String> _selectedNeedIds = {'sindirim'};

  bool _supplyOpen = false;
  final _requestNameController = TextEditingController();
  final _requestNoteController = TextEditingController();
  Uint8List? _requestImageBytes;
  _SupplyStatus? _requestStatus;
  bool _savingRequest = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _supplySub;

  static const _needs = <_MamaNeed>[
    _MamaNeed(
      id: 'sindirim',
      title: 'Sindirim\nProblemleri',
      iconPath: 'assets/images/app_ikonlar/sindirim.png',
    ),
    _MamaNeed(
      id: 'bobrek',
      title: 'Böbrek\nDesteği',
      iconPath: 'assets/images/app_ikonlar/bobrek.png',
    ),
    _MamaNeed(
      id: 'tuy',
      title: 'Tüy & Deri\nSağlığı',
      iconPath: 'assets/images/app_ikonlar/tuy_deri.png',
    ),
    _MamaNeed(
      id: 'kilo',
      title: 'Kilo\nKontrolü',
      iconPath: 'assets/images/app_ikonlar/kilo_kontrol.png',
    ),
    _MamaNeed(
      id: 'bagisiklik',
      title: 'Bağışıklık\nDesteği',
      iconPath: 'assets/images/app_ikonlar/bagisiklik.png',
    ),
    _MamaNeed(
      id: 'mide',
      title: 'Mide\nSağlığı',
      iconPath: 'assets/images/app_ikonlar/dogal_icerik.png',
    ),
    _MamaNeed(
      id: 'kalp',
      title: 'Kalp\nDesteği',
      iconPath: 'assets/images/app_ikonlar/kalp.png',
    ),
    _MamaNeed(
      id: 'dis',
      title: 'Diş\nSağlığı',
      iconPath: 'assets/images/app_ikonlar/dis.png',
    ),
    _MamaNeed(
      id: 'kisir',
      title: 'Kısırlaştırılmış\nDostlar',
      iconPath: 'assets/images/app_ikonlar/kisir_kedi.png',
    ),
    _MamaNeed(
      id: 'tahilsiz',
      title: 'Tahılsız\nMama',
      iconPath: 'assets/images/app_ikonlar/tahilsiz.png',
    ),
    _MamaNeed(
      id: 'idrar',
      title: 'İdrar Yolu\nSağlığı',
      iconPath: 'assets/images/app_ikonlar/idrar.png',
    ),
    _MamaNeed(
      id: 'eklem',
      title: 'Eklem\nDesteği',
      iconPath: 'assets/images/app_ikonlar/eklem.png',
    ),
  ];

  bool get _isCat => _petType == _PetType.cat;

  String get _listTitle {
    if (_selectedNeedIds.isEmpty) {
      return 'Önerilen Mamalar';
    }
    final first = _needs.firstWhere((n) => n.id == _selectedNeedIds.first);
    final base = first.title.replaceAll('\n', ' ');
    if (_selectedNeedIds.length == 1) {
      return '$base için Önerilen Mamalar';
    }
    return '$base +${_selectedNeedIds.length - 1} için Önerilen Mamalar';
  }

  List<_MamaProduct> _toMamaProducts(List<MarketProductData> items) {
    return [
      for (final item in items)
        _MamaProduct(
          id: item.id,
          brand: item.brand,
          name: item.title,
          description: item.subtitle,
          tags: [item.dietTag],
          weight: item.weights.isNotEmpty ? item.weights.first : '',
          price: item.prices.isNotEmpty ? item.prices.first : 0,
          imagePath: item.imagePath,
          source: item,
        ),
    ];
  }

  List<_MamaProduct> _productsForSelection(List<MarketProductData> catalog) {
    final petLabel = _petType == _PetType.cat ? 'Kedi' : 'Köpek';
    final matched = ProductTagFilter.apply(
      catalog: catalog,
      tags: _selectedNeedIds,
      petLabel: petLabel,
      matchAll: true,
    );
    return _toMamaProducts(matched);
  }

  void _toggleNeed(String id) {
    setState(() {
      if (_selectedNeedIds.contains(id)) {
        _selectedNeedIds.remove(id);
      } else {
        _selectedNeedIds.add(id);
      }
    });
  }

  void _openSupplySheet() {
    setState(() => _supplyOpen = true);
  }

  void _closeSupplySheet() {
    setState(() => _supplyOpen = false);
  }

  Future<void> _saveSupplyRequest() async {
    if (_savingRequest) return;
    final name = _requestNameController.text.trim();
    final note = _requestNoteController.text.trim();
    if (name.isEmpty && _requestImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ürün adı veya görsel eklemen gerekiyor.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final loggedIn = await LoginGate.require(
      context: context,
      message: 'Mama talebi göndermek için giriş yapmanız gerekir.',
    );
    if (!loggedIn || !mounted) return;

    setState(() => _savingRequest = true);
    try {
      var imageUrl = '';
      final bytes = _requestImageBytes;
      final uid = AuthStore.instance.uid ?? '';
      if (bytes != null && uid.isNotEmpty) {
        final ref = FirebaseStorage.instance.ref(
          'supply_requests/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        imageUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection(FirestoreCollections.supportTickets)
          .add({
            SupportTicketFields.kind: SupportTicketKinds.supply,
            SupportTicketFields.subject: 'Mama tedarik talebi',
            SupportTicketFields.productName: name,
            SupportTicketFields.message: note.isEmpty
                ? (name.isEmpty ? 'Görsel ile mama talebi' : name)
                : note,
            SupportTicketFields.imageUrl: imageUrl,
            SupportTicketFields.name: AuthStore.instance.fullName.trim(),
            SupportTicketFields.email: AuthStore.instance.email.trim(),
            SupportTicketFields.phone: AuthStore.instance.phone.trim(),
            SupportTicketFields.userId: uid,
            SupportTicketFields.status: SupportTicketStatuses.open,
            SupportTicketFields.reply: '',
            SupportTicketFields.createdAt: FieldValue.serverTimestamp(),
            SupportTicketFields.updatedAt: FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      setState(() {
        _requestStatus = _SupplyStatus.received;
        _supplyOpen = false;
        _savingRequest = false;
        _requestImageBytes = null;
      });
      _requestNameController.clear();
      _requestNoteController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Talebin iletildi. Takip bilgisini kartta görebilirsin.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _savingRequest = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Talep gönderilemedi. Bağlantını kontrol et.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openImageSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            12 + MediaQuery.paddingOf(sheetContext).bottom,
          ),
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
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Görsel ekle',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Fotoğraf çek veya galeriden seç.',
                  style: TextStyle(
                    color: AppColors.subText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildImageSourceButton(
                icon: Icons.photo_camera_outlined,
                label: 'Fotoğraf çek',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickRequestImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              _buildImageSourceButton(
                icon: Icons.photo_library_outlined,
                label: 'Galeriden seç',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickRequestImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSourceButton({
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
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.subText,
            size: 20,
          ),
        ],
      ),
    );
  }

  Future<void> _pickRequestImage(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted || bytes.isEmpty) return;
      setState(() => _requestImageBytes = bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? 'Kamera açılamadı. İzinleri kontrol edin.'
                : 'Galeri açılamadı.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    AuthStore.instance.addListener(_onAuthChanged);
    _bindSupplyTicket();
  }

  @override
  void dispose() {
    AuthStore.instance.removeListener(_onAuthChanged);
    _supplySub?.cancel();
    _requestNameController.dispose();
    _requestNoteController.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    _bindSupplyTicket();
  }

  void _bindSupplyTicket() {
    _supplySub?.cancel();
    final uid = AuthStore.instance.uid;
    if (uid == null || uid.isEmpty) return;
    _supplySub = FirebaseFirestore.instance
        .collection(FirestoreCollections.supportTickets)
        .where(SupportTicketFields.userId, isEqualTo: uid)
        .snapshots()
        .listen((snap) {
      final tickets = snap.docs.where((doc) {
        final kind = (doc.data()[SupportTicketFields.kind] as String?) ?? '';
        return kind == SupportTicketKinds.supply;
      }).toList();
      tickets.sort((a, b) {
        final left = a.data()[SupportTicketFields.createdAt];
        final right = b.data()[SupportTicketFields.createdAt];
        final leftTime = left is Timestamp
            ? left.toDate()
            : DateTime.fromMillisecondsSinceEpoch(0);
        final rightTime = right is Timestamp
            ? right.toDate()
            : DateTime.fromMillisecondsSinceEpoch(0);
        return rightTime.compareTo(leftTime);
      });
      if (tickets.isEmpty || !mounted) return;
      final status =
          (tickets.first.data()[SupportTicketFields.status] as String?) ??
          SupportTicketStatuses.open;
      setState(() {
        _requestStatus = switch (status) {
          SupportTicketStatuses.replied => _SupplyStatus.processing,
          SupportTicketStatuses.closed => _SupplyStatus.supplied,
          _ => _SupplyStatus.received,
        };
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame.standard(
        backgroundColor: AppColors.background,
        header: _buildHeader(context),
        content: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPetTypeSelector(),
                  const SizedBox(height: 10),
                  _buildRecommendCard(),
                  const SizedBox(height: 14),
                  _buildNeedsHeader(),
                  const SizedBox(height: 8),
                  _buildNeedsGrid(),
                  const SizedBox(height: 14),
                  _buildProductsHeader(),
                  const SizedBox(height: 8),
                  StreamBuilder<List<MarketProductData>>(
                    stream: ProductRepository.instance.watchMarketProducts(),
                    builder: (context, snapshot) {
                      final catalog =
                          snapshot.data ?? const <MarketProductData>[];
                      return _buildProductsGrid(
                        _productsForSelection(catalog),
                      );
                    },
                  ),
                ],
              ),
            ),
            if (_supplyOpen) _buildSupplyOverlay(),
          ],
        ),
        navbar: const AppBottomNavbar(),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const AppBackButton(),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Hangi Mama?',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.pageHeader,
                ),
                Text(
                  'Dostuna en uygun mamayı bul',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.subText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const AppNotificationButton(badgeColor: AppColors.error),
        ],
      ),
    );
  }

  Widget _buildPetTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _petTypeChip(
            type: _PetType.cat,
            label: 'Kedi',
            iconPath: 'assets/images/app_ikonlar/normal_kedi.png',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _petTypeChip(
            type: _PetType.dog,
            label: 'Köpek',
            iconPath: 'assets/images/app_ikonlar/kopek.png',
          ),
        ),
      ],
    );
  }

  Widget _petTypeChip({
    required _PetType type,
    required String label,
    required String iconPath,
  }) {
    final selected = _petType == type;
    return GestureDetector(
      onTap: () => setState(() => _petType = type),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconPath,
              width: 22,
              height: 22,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.pets_rounded,
                size: 18,
                color: selected ? AppColors.primary : AppColors.subText,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.subText,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendCard() {
    final petImage =
        _isCat ? 'assets/images/milo_kedi.png' : 'assets/images/luna_kopek.png';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: SizedBox(
              height: 148,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.campaign_rounded,
                                color: AppColors.surface,
                                size: 15,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Flexible(
                              child: Text(
                                'Mama Yok mu?',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.inventory_2_outlined,
                              color: AppColors.primary,
                              size: 16,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Aradığın veya kullandığın mama stoklarımızda yoksa bize bildir, tedarik edelim.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.subText,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFeatureChip(
                                Icons.inventory_2_outlined,
                                'Geniş Tedarik\nAğı',
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _buildFeatureChip(
                                Icons.verified_user_outlined,
                                '%100 Orijinal\nÜrün',
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _buildFeatureChip(
                                Icons.bolt_rounded,
                                'Hızlı\nTedarik',
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        AppPressableButton.primary(
                          onTap: _openSupplySheet,
                          width: double.infinity,
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: const Row(
                            children: [
                              Icon(Icons.inventory_2_rounded, size: 15),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Tedarik Talebi Oluştur',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 4,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Center(
                          child: Container(
                            width: 118,
                            height: 118,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.12),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Transform.translate(
                            offset: const Offset(0, -6),
                            child: Image.asset(
                              petImage,
                              fit: BoxFit.contain,
                              alignment: Alignment.topCenter,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                Icons.pets_rounded,
                                color: AppColors.primary,
                                size: 64,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.pets_rounded,
                                  size: 10,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'Patine En İyisi\nGelsin!',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildHowItWorksBar(),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 12, color: AppColors.primary),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHowItWorksBar() {
    // 0: none, 1: talep oluştu, 2: tedarik, 3: ulaştırıldı
    final activeStep = switch (_requestStatus) {
      null => 0,
      _SupplyStatus.received => 1,
      _SupplyStatus.failed => 1,
      _SupplyStatus.processing => 2,
      _SupplyStatus.supplied => 3,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.campaign_outlined,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          const Text(
            'Nasıl Çalışır?',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildHowStep(
                    number: 1,
                    label: 'Talebini Oluştur',
                    done: activeStep >= 1,
                  ),
                ),
                _buildHowDash(active: activeStep >= 1),
                Expanded(
                  child: _buildHowStep(
                    number: 2,
                    label: 'Biz Tedarik Edelim',
                    done: activeStep >= 2,
                  ),
                ),
                _buildHowDash(active: activeStep >= 2),
                Expanded(
                  child: _buildHowStep(
                    number: 3,
                    label: 'Sana Ulaştıralım',
                    done: activeStep >= 3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowDash({required bool active}) {
    return SizedBox(
      width: 14,
      height: 2,
      child: CustomPaint(
        painter: _DashedLinePainter(
          color: active ? AppColors.primary : AppColors.border,
        ),
      ),
    );
  }

  Widget _buildHowStep({
    required int number,
    required String label,
    required bool done,
  }) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: done
                ? AppColors.success
                : AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: done
              ? const Icon(
                  Icons.check_rounded,
                  size: 12,
                  color: AppColors.surface,
                )
              : Text(
                  '$number',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: done ? AppColors.success : AppColors.text,
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupplyOverlay() {
    return Positioned.fill(
      child: Stack(
        children: [
          GestureDetector(
            onTap: _closeSupplySheet,
            child: Container(color: Colors.black.withValues(alpha: 0.35)),
          ),
          Align(
            alignment: const Alignment(0, -0.35),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mama Talebi Oluştur',
                                  style: TextStyle(
                                    color: AppColors.text,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  'Bulamadığın ürünün adını veya görselini bize ilet.',
                                  style: TextStyle(
                                    color: AppColors.subText,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _closeSupplySheet,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.subText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Ürün adı',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: _requestNameController,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: 'Örn: Royal Canin Indoor 2kg',
                            hintStyle: TextStyle(
                              color: AppColors.subText,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Ürün görseli',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _openImageSourceSheet,
                        child: Container(
                          width: double.infinity,
                          height: 84,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.border,
                              width: 1.2,
                            ),
                          ),
                          child: _requestImageBytes == null
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      color: AppColors.primary,
                                      size: 26,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Fotoğraf çek veya galeriden seç',
                                      style: TextStyle(
                                        color: AppColors.subText,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : Stack(
                                  children: [
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(18),
                                        child: Image.memory(
                                          _requestImageBytes!,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(
                                            () => _requestImageBytes = null,
                                          );
                                        },
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: const BoxDecoration(
                                            color: AppColors.surface,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            size: 14,
                                            color: AppColors.text,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Açıklama',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 72,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: _requestNoteController,
                          maxLines: 3,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText:
                                'Marka, gramaj veya eklemek istediğin not...',
                            hintStyle: TextStyle(
                              color: AppColors.subText,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppPressableButton.primary(
                        onTap: _saveSupplyRequest,
                        enabled: !_savingRequest,
                        width: double.infinity,
                        height: 42,
                        child: Text(
                          _savingRequest ? 'Gönderiliyor...' : 'Kaydet',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeedsHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'İhtiyacını Seç',
              style: AppTextStyles.sectionHeader,
            ),
            SizedBox(width: 4),
            Icon(Icons.eco_rounded, color: AppColors.success, size: 16),
          ],
        ),
        SizedBox(height: 2),
        Text(
          'Birden fazla özellik seçebilirsin',
          style: TextStyle(
            color: AppColors.subText,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildNeedsGrid() {
    const columns = 6;
    const gap = 6.0;
    final rows = <Widget>[];

    for (int start = 0; start < _needs.length; start += columns) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: gap));
      rows.add(
        Row(
          children: [
            for (int i = 0; i < columns; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              Expanded(
                child: start + i < _needs.length
                    ? _buildNeedCard(_needs[start + i])
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildNeedCard(_MamaNeed need) {
    final selected = _selectedNeedIds.contains(need.id);
    return GestureDetector(
      onTap: () => _toggleNeed(need.id),
      child: Container(
        height: 86,
        padding: const EdgeInsets.fromLTRB(3, 4, 3, 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primaryLight : AppColors.border,
            width: selected ? 0.8 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
                    child: Image.asset(
                      need.iconPath,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.health_and_safety_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                Text(
                  need.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? AppColors.primary : AppColors.text,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ],
            ),
            if (selected)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.surface,
                    size: 9,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsHeader() {
    return Text(
      _listTitle,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.sectionHeader,
    );
  }

  Widget _buildProductsGrid(List<_MamaProduct> products) {
    if (products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'Bu ihtiyaca uygun ürün bulunamadı.',
            style: TextStyle(
              color: AppColors.subText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    const columns = 3;
    const gap = MarketCompactProductCard.cardGap;
    final rows = <Widget>[];

    for (int start = 0; start < products.length; start += columns) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: gap));
      rows.add(
        SizedBox(
          height: MarketCompactProductCard.cardHeight,
          child: Row(
            children: [
              for (int i = 0; i < columns; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                Expanded(
                  child: start + i < products.length
                      ? _buildProductCard(products[start + i])
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildProductCard(_MamaProduct product) {
    final marketProduct = product.source ??
        buildSimpleMarketProduct(
          id: product.id,
          imagePath: product.imagePath,
          title: product.name,
          subtitle: product.brand,
          price: product.price,
          oldPrice: product.price * 1.15,
          weight: product.weight,
          brand: product.brand,
          dietTag: product.tags.isNotEmpty ? product.tags.first : 'Standart',
        );
    final price =
        marketProduct.prices.isNotEmpty ? marketProduct.prices.first : 0.0;
    final oldPrice = marketProduct.oldPrices.isNotEmpty
        ? marketProduct.oldPrices.first
        : price;

    return MarketCompactProductCard(
      product: marketProduct,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: marketProduct),
        ),
      ),
      onAddToCart: () {
        CartStore.instance.addItem(
          id: product.id,
          imagePath: product.imagePath,
          title: product.name,
          unitPrice: price,
          oldPrice: oldPrice,
          weight: product.weight,
          brand: product.brand,
        );
      },
    );
  }
}

class _MamaNeed {
  const _MamaNeed({
    required this.id,
    required this.title,
    required this.iconPath,
  });

  final String id;
  final String title;
  final String iconPath;
}

class _MamaProduct {
  const _MamaProduct({
    required this.id,
    required this.brand,
    required this.name,
    required this.description,
    required this.tags,
    required this.weight,
    required this.price,
    required this.imagePath,
    this.source,
  });

  final String id;
  final String brand;
  final String name;
  final String description;
  final List<String> tags;
  final String weight;
  final double price;
  final String imagePath;
  final MarketProductData? source;
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const dashWidth = 2.5;
    const dashSpace = 2.0;
    var startX = 0.0;
    final y = size.height / 2;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, y),
        Offset((startX + dashWidth).clamp(0, size.width), y),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

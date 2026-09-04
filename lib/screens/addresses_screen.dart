import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geliyor_app/data/turkey_locations.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/state/address_store.dart';
import 'package:geliyor_app/state/auth_store.dart';
import 'package:geliyor_app/utils/login_gate.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';

enum _AddressMenuAction { makeDefault, edit, delete }

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({
    super.key,
    this.selectForDelivery = false,
  });

  /// Sipariş onayından gelince kart tıklanınca adres seçilir ve geri dönülür.
  final bool selectForDelivery;

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  bool _showForm = false;
  String? _editingId;
  String? _formError;

  final _titleController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _taxOfficeController = TextEditingController();
  bool _formIsDefault = false;
  bool _formIsDelivery = true;
  bool _formIsInvoice = true;
  IconData _formIcon = Icons.home_rounded;
  AddressAccountType _formAccountType = AddressAccountType.individual;
  String? _formCity;
  String? _formDistrict;

  static const _iconOptions = <(IconData, String)>[
    (Icons.home_rounded, 'Ev'),
    (Icons.work_outline_rounded, 'İş'),
    (Icons.favorite_border_rounded, 'Diğer'),
  ];

  List<AddressData> get _addresses => AddressStore.instance.addresses;

  @override
  void initState() {
    super.initState();
    AddressStore.instance.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    AddressStore.instance.removeListener(_onStoreChanged);
    _titleController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _nationalIdController.dispose();
    _taxOfficeController.dispose();
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  bool get _isEditing => _editingId != null;

  void _openAddForm() {
    setState(() {
      _showForm = true;
      _editingId = null;
      _formError = null;
      _titleController.clear();
      _contactController.clear();
      _addressController.clear();
      _nationalIdController.clear();
      _taxOfficeController.clear();
      _formIsDefault = _addresses.isEmpty;
      _formIsDelivery = true;
      _formIsInvoice = true;
      _formIcon = Icons.home_rounded;
      _formAccountType = AddressAccountType.individual;
      _formCity = null;
      _formDistrict = null;
    });
  }

  void _openEditForm(AddressData address) {
    setState(() {
      _showForm = true;
      _editingId = address.id;
      _formError = null;
      _titleController.text = address.title;
      _contactController.text = address.contactName;
      _addressController.text = address.address;
      _nationalIdController.text = address.taxId.isNotEmpty
          ? address.taxId
          : address.nationalId;
      _taxOfficeController.text = address.taxOffice;
      _formIsDefault = address.isDefault;
      _formIsDelivery = address.isDelivery;
      _formIsInvoice = address.isInvoice;
      _formIcon = address.icon;
      _formAccountType = address.accountType;
      final inferred = TurkeyLocations.infer(
        address: address.address,
        city: address.city,
        district: address.district,
      );
      _formCity = inferred.city.isEmpty ? null : inferred.city;
      _formDistrict = inferred.district.isEmpty ? null : inferred.district;
    });
  }

  void _closeForm() {
    FocusScope.of(context).unfocus();
    setState(() {
      _showForm = false;
      _editingId = null;
      _formError = null;
    });
  }

  void _onBack() {
    if (_showForm) {
      _closeForm();
      return;
    }
    Navigator.of(context).maybePop();
  }

  void _pickAddress(AddressData address) {
    AddressStore.instance.setDefault(address.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _setDefault(String id) async {
    final ok = await LoginGate.require(
      context: context,
      message: 'Adres kaydetmek için giriş yapmanız gerekir.',
    );
    if (!ok || !mounted) return;
    AddressStore.instance.setDefault(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Varsayılan adres güncellendi.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteAddress(String id) async {
    AddressStore.instance.remove(id);
    await AddressStore.instance.persistNow();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Adres silindi.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveForm() async {
    FocusScope.of(context).unfocus();

    final title = _titleController.text.trim();
    final contact = _contactController.text.trim();
    final address = _addressController.text.trim();
    final idDigits = _nationalIdController.text.replaceAll(RegExp(r'\D'), '');
    final taxOffice = _taxOfficeController.text.trim();
    final wasEditing = _isEditing;
    final isCorporate = _formAccountType == AddressAccountType.corporate;

    final city = _formCity?.trim() ?? '';
    final district = _formDistrict?.trim() ?? '';

    if (title.isEmpty || contact.isEmpty || address.isEmpty) {
      setState(() {
        _formError = 'Lütfen tüm alanları doldurun.';
      });
      return;
    }
    if (city.isEmpty || district.isEmpty) {
      setState(() {
        _formError = 'Lütfen il ve ilçe seçin.';
      });
      return;
    }
    if (!_formIsDelivery && !_formIsInvoice) {
      setState(() {
        _formError = 'Teslimat veya fatura adresi seçin.';
      });
      return;
    }

    var nationalId = '';
    var taxId = '';
    if (isCorporate) {
      if (idDigits.length == 10) {
        taxId = idDigits;
      } else if (idDigits.length == 11) {
        nationalId = idDigits;
      } else {
        setState(() {
          _formError =
              'Kurumsal adres için 10 haneli vergi no veya 11 haneli T.C. kimlik no girin.';
        });
        return;
      }
      if (taxOffice.isEmpty) {
        setState(() {
          _formError = 'Kurumsal adres için vergi dairesi girin.';
        });
        return;
      }
    } else if (idDigits.isNotEmpty) {
      if (idDigits.length != 11) {
        setState(() {
          _formError = 'T.C. kimlik no 11 haneli olmalıdır.';
        });
        return;
      }
      nationalId = idDigits;
    }

    final ok = await LoginGate.require(
      context: context,
      message: 'Adres kaydetmek için giriş yapmanız gerekir.',
    );
    if (!ok || !mounted) return;

    final data = AddressData(
      id: wasEditing
          ? _editingId!
          : 'addr_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      contactName: contact,
      phone: AuthStore.instance.phone.trim(),
      address: address,
      city: city,
      district: district,
      icon: _formIcon,
      isDefault: _formIsDefault,
      accountType: _formAccountType,
      nationalId: nationalId,
      taxId: taxId,
      taxOffice: isCorporate ? taxOffice : '',
      isDelivery: _formIsDelivery,
      isInvoice: _formIsInvoice,
    );

    if (wasEditing) {
      AddressStore.instance.update(_editingId!, data);
    } else {
      AddressStore.instance.add(data);
    }
    await AddressStore.instance.persistNow();
    if (!mounted) return;

    setState(() {
      _formError = null;
      _showForm = false;
      _editingId = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasEditing ? 'Adres güncellendi.' : 'Yeni adres eklendi.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onAddressMenu(AddressData address, _AddressMenuAction action) {
    switch (action) {
      case _AddressMenuAction.makeDefault:
        _setDefault(address.id);
      case _AddressMenuAction.edit:
        _openEditForm(address);
      case _AddressMenuAction.delete:
        _deleteAddress(address.id);
    }
  }

  Widget _buildMoreButton(AddressData address) {
    return PopupMenuButton<_AddressMenuAction>(
      tooltip: 'Adres işlemleri',
      padding: EdgeInsets.zero,
      offset: const Offset(0, 8),
      color: AppColors.surface,
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      onSelected: (action) => _onAddressMenu(address, action),
      itemBuilder: (context) => [
        if (!address.isDefault)
          _menuItem(
            _AddressMenuAction.makeDefault,
            Icons.star_outline_rounded,
            'Varsayılan yap',
            AppColors.primary,
          ),
        _menuItem(
          _AddressMenuAction.edit,
          Icons.edit_outlined,
          'Düzenle',
          AppColors.primary,
        ),
        _menuItem(
          _AddressMenuAction.delete,
          Icons.delete_outline_rounded,
          'Sil',
          AppColors.error,
        ),
      ],
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.selected,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primaryLight),
        ),
        child: const Icon(
          Icons.more_vert_rounded,
          color: AppColors.primary,
          size: 22,
        ),
      ),
    );
  }

  PopupMenuItem<_AddressMenuAction> _menuItem(
    _AddressMenuAction value,
    IconData icon,
    String label,
    Color color,
  ) {
    return PopupMenuItem<_AddressMenuAction>(
      value: value,
      enabled: true,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_showForm,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _showForm) _closeForm();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: AppPageFrame.standard(
          backgroundColor: AppColors.background,
          activeTab: AppNavTab.profile,
          header: _buildHeader(),
          content: _showForm
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppPageFrame.contentHorizontalPadding,
                    0,
                    AppPageFrame.contentHorizontalPadding,
                    8,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          child: _buildFormFields(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildFormActions(),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppPageFrame.contentHorizontalPadding,
                    0,
                    AppPageFrame.contentHorizontalPadding,
                    8,
                  ),
                  child: _buildList(),
                ),
          navbar: const AppBottomNavbar(activeTab: AppNavTab.profile),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          AppBackButton(onPressed: _onBack),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _showForm
                      ? (_isEditing ? 'Adres Düzenle' : 'Yeni Adres')
                      : (widget.selectForDelivery
                          ? 'Adres Seç'
                          : 'Adreslerim'),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.pageHeader,
                ),
                Text(
                  _showForm
                      ? 'Adres bilgilerini girin ve kaydedin.'
                      : (widget.selectForDelivery
                          ? 'Teslimat adresine dokunun, siparişe dönülür.'
                          : 'Kayıtlı adreslerinizi görüntüleyin ve yönetin.'),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.subText.withValues(alpha: 0.95),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
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

  Widget _buildList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(),
        const SizedBox(height: 10),
        if (_addresses.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'Henüz kayıtlı adres yok. Yeni adres ekleyebilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.subText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          for (int i = 0; i < _addresses.length; i++) ...[
            _buildAddressCard(_addresses[i]),
            if (i != _addresses.length - 1) const SizedBox(height: 8),
          ],
        const SizedBox(height: 10),
        _buildInfoBox(),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Adres Tipi',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (int i = 0; i < _iconOptions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _buildIconOption(
                        _iconOptions[i].$1,
                        _iconOptions[i].$2,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Hesap Türü',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildSelectChip(
                      selected:
                          _formAccountType == AddressAccountType.individual,
                      icon: Icons.person_outline_rounded,
                      label: 'Bireysel',
                      onTap: () => setState(
                        () => _formAccountType = AddressAccountType.individual,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSelectChip(
                      selected:
                          _formAccountType == AddressAccountType.corporate,
                      icon: Icons.apartment_rounded,
                      label: 'Kurumsal',
                      onTap: () => setState(
                        () => _formAccountType = AddressAccountType.corporate,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Adres Kullanımı',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildSelectChip(
                      selected: _formIsDelivery,
                      icon: Icons.local_shipping_outlined,
                      label: 'Teslimat',
                      onTap: () =>
                          setState(() => _formIsDelivery = !_formIsDelivery),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSelectChip(
                      selected: _formIsInvoice,
                      icon: Icons.receipt_long_outlined,
                      label: 'Fatura',
                      onTap: () =>
                          setState(() => _formIsInvoice = !_formIsInvoice),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Teslimat ve fatura için aynı adresi birlikte seçebilirsiniz.',
                style: TextStyle(
                  color: AppColors.subText,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildField(
                label: 'Adres Başlığı',
                controller: _titleController,
                hint: 'Örn. Evim',
              ),
              const SizedBox(height: 10),
              _buildField(
                label: 'İletişim Adı',
                controller: _contactController,
                hint: 'Örn. Can Dostu',
              ),
              const SizedBox(height: 10),
              _buildField(
                label: 'Adres',
                controller: _addressController,
                hint: 'Mahalle, cadde, sokak, no',
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              _buildLocationField(
                label: 'İl',
                value: _formCity,
                placeholder: 'İl seçin',
                onTap: () => _openLocationPicker(
                  title: 'İl seçin',
                  options: TurkeyLocations.provinces,
                  selected: _formCity,
                  onSelect: (value) {
                    setState(() {
                      _formCity = value;
                      _formDistrict = null;
                      _formError = null;
                    });
                  },
                ),
              ),
              const SizedBox(height: 10),
              _buildLocationField(
                label: 'İlçe',
                value: _formDistrict,
                placeholder: _formCity == null
                    ? 'Önce il seçin'
                    : 'İlçe seçin',
                enabled: _formCity != null,
                onTap: () {
                  final city = _formCity;
                  if (city == null) return;
                  _openLocationPicker(
                    title: 'İlçe seçin',
                    options: TurkeyLocations.districtsOf(city),
                    selected: _formDistrict,
                    onSelect: (value) {
                      setState(() {
                        _formDistrict = value;
                        _formError = null;
                      });
                    },
                  );
                },
              ),
              if (_formAccountType == AddressAccountType.individual) ...[
                const SizedBox(height: 10),
                _buildField(
                  label: 'T.C. Kimlik No (opsiyonel)',
                  controller: _nationalIdController,
                  hint: '11 haneli kimlik numarası',
                  keyboardType: TextInputType.number,
                  maxLength: 11,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ] else ...[
                const SizedBox(height: 10),
                _buildField(
                  label: 'Vergi / T.C. Kimlik No',
                  controller: _nationalIdController,
                  hint: '10 hane vergi no, 11 hane T.C.',
                  keyboardType: TextInputType.number,
                  maxLength: 11,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 6),
                Text(
                  _corporateIdHint,
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                _buildField(
                  label: 'Vergi Dairesi',
                  controller: _taxOfficeController,
                  hint: 'Örn. Kadıköy Vergi Dairesi',
                ),
              ],
              const SizedBox(height: 10),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _formIsDefault = !_formIsDefault),
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          _formIsDefault
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Varsayılan adres olarak kaydet',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_formError != null) ...[
                const SizedBox(height: 10),
                Text(
                  _formError!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormActions() {
    return Row(
      children: [
        Expanded(
          child: AppPressableButton(
            onTap: _closeForm,
            height: 42,
            padding: EdgeInsets.zero,
            backgroundColor: AppColors.surface,
            pressedBackgroundColor: AppColors.selected,
            borderColor: AppColors.border,
            pressedBorderColor: AppColors.primaryLight,
            child: const Text(
              'İptal',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: AppPressableButton.primary(
            onTap: _saveForm,
            height: 42,
            padding: EdgeInsets.zero,
            child: Text(
              _isEditing ? 'Kaydet' : 'Adres Ekle',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconOption(IconData icon, String label) {
    return _buildSelectChip(
      selected: _formIcon == icon,
      icon: icon,
      label: label,
      onTap: () => setState(() => _formIcon = icon),
    );
  }

  Widget _buildSelectChip({
    required bool selected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 42,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primaryLight : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.primary : AppColors.subText,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? AppColors.primary : AppColors.text,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _corporateIdHint {
    final length =
        _nationalIdController.text.replaceAll(RegExp(r'\D'), '').length;
    if (length == 10) return 'Vergi kimlik no olarak kaydedilecek.';
    if (length == 11) return 'T.C. kimlik no olarak kaydedilecek.';
    if (length == 0) {
      return '10 hane vergi no, 11 hane T.C. kimlik no olarak kaydedilir.';
    }
    return '10 veya 11 hane girin.';
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: maxLines > 1 ? 10 : 0,
          ),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(maxLines > 1 ? 18 : 999),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: AppColors.subText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              isDense: true,
              counterText: '',
              contentPadding: maxLines > 1
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField({
    required String label,
    required String? value,
    required String placeholder,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            height: 42,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: enabled ? AppColors.background : AppColors.selected,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? placeholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: value == null
                          ? AppColors.subText
                          : AppColors.text,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: enabled ? AppColors.primary : AppColors.subText,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openLocationPicker({
    required String title,
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onSelect,
  }) async {
    final query = TextEditingController();
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (sheetContext) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom +
                  MediaQuery.paddingOf(sheetContext).bottom,
            ),
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                final needle = query.text.trim();
                final filtered = needle.isEmpty
                    ? options
                    : options
                        .where(
                          (item) => TurkeyLocations.matchesQuery(item, needle),
                        )
                        .toList();
                return SizedBox(
                    height: 420,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
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
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 42,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: TextField(
                              controller: query,
                              onChanged: (_) => setSheetState(() {}),
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Ara',
                                hintStyle: TextStyle(
                                  color: AppColors.subText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: filtered.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Sonuç bulunamadı.',
                                      style: TextStyle(
                                        color: AppColors.subText,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, _) => const Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: AppColors.border,
                                    ),
                                    itemBuilder: (context, index) {
                                      final option = filtered[index];
                                      final isSelected = selected == option;
                                      return ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          option,
                                          style: TextStyle(
                                            color: AppColors.text,
                                            fontSize: 13,
                                            fontWeight: isSelected
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                          ),
                                        ),
                                        trailing: isSelected
                                            ? const Icon(
                                                Icons.check_rounded,
                                                color: AppColors.primary,
                                                size: 18,
                                              )
                                            : null,
                                        onTap: () {
                                          onSelect(option);
                                          Navigator.of(sheetContext).pop();
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                );
              },
            ),
          );
        },
      );
    } finally {
      query.dispose();
    }
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.selectForDelivery
                ? 'Teslimat adresi seçin'
                : 'Kayıtlı Adreslerim',
            style: AppTextStyles.sectionHeader,
          ),
        ),
        AppPressableButton.primary(
          onTap: _openAddForm,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          borderRadius: 18,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 16),
              SizedBox(width: 4),
              Text('Yeni Adres Ekle', style: TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressCard(AddressData address) {
    final card = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: address.isDefault ? AppColors.primary : AppColors.border,
          width: address.isDefault ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: widget.selectForDelivery
                  ? InkWell(
                      onTap: () => _pickAddress(address),
                      borderRadius: BorderRadius.circular(18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAddressIconBox(address),
                          const SizedBox(width: 10),
                          Expanded(child: _buildAddressCardBody(address)),
                        ],
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAddressIconBox(address),
                        const SizedBox(width: 10),
                        Expanded(child: _buildAddressCardBody(address)),
                      ],
                    ),
            ),
            _buildMoreButton(address),
          ],
        ),
      ),
    );
    return card;
  }

  Widget _buildAddressCardBody(AddressData address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                address.title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (address.isDefault)
              Container(
                margin: const EdgeInsets.only(right: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Varsayılan',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            _buildTinyBadge(
              address.isCorporate ? 'Kurumsal' : 'Bireysel',
            ),
            if (address.isDelivery) _buildTinyBadge('Teslimat'),
            if (address.isInvoice) _buildTinyBadge('Fatura'),
          ],
        ),
        const SizedBox(height: 4),
        _buildInfoLine(
          Icons.person_outline_rounded,
          address.contactName,
        ),
        const SizedBox(height: 3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                Icons.location_on_outlined,
                size: 13,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                address.cityDistrictLabel.isEmpty
                    ? address.address
                    : '${address.address}\n${address.cityDistrictLabel}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.subText,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        if (address.isCorporate && address.taxOffice.trim().isNotEmpty) ...[
          const SizedBox(height: 3),
          _buildInfoLine(
            Icons.account_balance_outlined,
            address.taxOffice,
          ),
        ],
      ],
    );
  }

  Widget _buildTinyBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.selected,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildAddressIconBox(AddressData address) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.selected,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(address.icon, color: AppColors.primary, size: 20),
    );
  }

  Widget _buildInfoLine(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.subText),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.subText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.selected,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bilgi',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Siparişlerinizi hızlı ve güvenli bir şekilde teslim edebilmemiz için adres bilgilerinizi güncel tutmayı unutmayın.',
                  style: TextStyle(
                    color: AppColors.subText,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

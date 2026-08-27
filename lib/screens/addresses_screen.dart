import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/state/address_store.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  bool _showForm = false;
  String? _editingId;
  String? _formError;

  final _titleController = TextEditingController();
  final _contactController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _formIsDefault = false;
  IconData _formIcon = Icons.home_rounded;

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
    _phoneController.dispose();
    _addressController.dispose();
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
      _phoneController.clear();
      _addressController.clear();
      _formIsDefault = _addresses.isEmpty;
      _formIcon = Icons.home_rounded;
    });
  }

  void _openEditForm(AddressData address) {
    setState(() {
      _showForm = true;
      _editingId = address.id;
      _formError = null;
      _titleController.text = address.title;
      _contactController.text = address.contactName;
      _phoneController.text = address.phone;
      _addressController.text = address.address;
      _formIsDefault = address.isDefault;
      _formIcon = address.icon;
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

  void _setDefault(String id) {
    AddressStore.instance.setDefault(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Varsayılan adres güncellendi.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteAddress(String id) {
    AddressStore.instance.remove(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Adres silindi.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saveForm() {
    FocusScope.of(context).unfocus();

    final title = _titleController.text.trim();
    final contact = _contactController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final wasEditing = _isEditing;

    if (title.isEmpty || contact.isEmpty || phone.isEmpty || address.isEmpty) {
      setState(() {
        _formError = 'Lütfen tüm alanları doldurun.';
      });
      return;
    }

    final data = AddressData(
      id: wasEditing
          ? _editingId!
          : 'addr_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      contactName: contact,
      phone: phone,
      address: address,
      icon: _formIcon,
      isDefault: _formIsDefault,
    );

    if (wasEditing) {
      AddressStore.instance.update(_editingId!, data);
    } else {
      AddressStore.instance.add(data);
    }

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

  void _showAddressMenu(AddressData address) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (sheetContext) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppPageFrame.width),
            child: Material(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
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
                    const SizedBox(height: 10),
                    if (!address.isDefault)
                      _buildMenuAction(
                        icon: Icons.star_outline_rounded,
                        label: 'Varsayılan yap',
                        color: AppColors.primary,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _setDefault(address.id);
                        },
                      ),
                    _buildMenuAction(
                      icon: Icons.edit_outlined,
                      label: 'Düzenle',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _openEditForm(address);
                      },
                    ),
                    _buildMenuAction(
                      icon: Icons.delete_outline_rounded,
                      label: 'Sil',
                      color: AppColors.error,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _deleteAddress(address.id);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
        ),
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
                      : 'Adreslerim',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.pageHeader,
                ),
                Text(
                  _showForm
                      ? 'Adres bilgilerini girin ve kaydedin.'
                      : 'Kayıtlı adreslerinizi görüntüleyin ve yönetin.',
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
                label: 'Telefon',
                controller: _phoneController,
                hint: '+90 5xx xxx xx xx',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              _buildField(
                label: 'Adres',
                controller: _addressController,
                hint: 'Mahalle, cadde, no, ilçe / şehir',
                maxLines: 3,
              ),
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
    final selected = _formIcon == icon;
    return GestureDetector(
      onTap: () => setState(() => _formIcon = icon),
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
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.text,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
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
              contentPadding: maxLines > 1
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text('Kayıtlı Adreslerim', style: AppTextStyles.sectionHeader),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showAddressMenu(address),
        borderRadius: BorderRadius.circular(24),
        child: Ink(
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
                _buildAddressIconBox(address),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
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
                              margin: const EdgeInsets.only(right: 4),
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
                          GestureDetector(
                            onTap: () => _showAddressMenu(address),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.more_vert_rounded,
                                color: AppColors.subText.withValues(alpha: 0.8),
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _buildInfoLine(
                        Icons.person_outline_rounded,
                        address.contactName,
                      ),
                      const SizedBox(height: 3),
                      _buildInfoLine(Icons.phone_outlined, address.phone),
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
                              address.address,
                              maxLines: 2,
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
                    ],
                  ),
                ),
              ],
            ),
          ),
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

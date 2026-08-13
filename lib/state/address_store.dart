import 'package:flutter/material.dart';

class AddressData {
  const AddressData({
    required this.id,
    required this.title,
    required this.contactName,
    required this.phone,
    required this.address,
    this.icon = Icons.home_rounded,
    this.isDefault = false,
  });

  final String id;
  final String title;
  final String contactName;
  final String phone;
  final String address;
  final IconData icon;
  final bool isDefault;

  AddressData copyWith({
    String? title,
    String? contactName,
    String? phone,
    String? address,
    IconData? icon,
    bool? isDefault,
  }) {
    return AddressData(
      id: id,
      title: title ?? this.title,
      contactName: contactName ?? this.contactName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

/// Uygulama genelinde paylaşılan adres listesi.
/// Adreslerim yazar; Siparişi Onayla varsayılan adresi okur.
class AddressStore extends ChangeNotifier {
  AddressStore._();

  static final AddressStore instance = AddressStore._();

  final List<AddressData> _addresses = [
    const AddressData(
      id: 'home',
      title: 'Evim',
      contactName: 'Can Dostu',
      phone: '+90 555 123 45 67',
      address: 'Ataşehir Mah. 34750 Ataşehir / İstanbul, Daire: 12, Kat: 4',
      icon: Icons.home_rounded,
      isDefault: true,
    ),
    const AddressData(
      id: 'work',
      title: 'İş Yerim',
      contactName: 'Can Dostu',
      phone: '+90 555 123 45 67',
      address: 'Levent Mah. Büyükdere Cad. No: 185, Şişli / İstanbul',
      icon: Icons.work_outline_rounded,
    ),
    const AddressData(
      id: 'mom',
      title: 'Annemin Evi',
      contactName: 'Can Dostu',
      phone: '+90 555 123 45 67',
      address: 'Kozyatağı Mah. 34742 Kadıköy / İstanbul, Daire: 8',
      icon: Icons.favorite_border_rounded,
    ),
  ];

  List<AddressData> get addresses => List.unmodifiable(_addresses);

  AddressData? get defaultAddress {
    for (final item in _addresses) {
      if (item.isDefault) return item;
    }
    return _addresses.isEmpty ? null : _addresses.first;
  }

  void setDefault(String id) {
    for (var i = 0; i < _addresses.length; i++) {
      _addresses[i] = _addresses[i].copyWith(isDefault: _addresses[i].id == id);
    }
    notifyListeners();
  }

  void add(AddressData address) {
    final makeDefault = address.isDefault || _addresses.isEmpty;
    if (makeDefault) {
      for (var i = 0; i < _addresses.length; i++) {
        _addresses[i] = _addresses[i].copyWith(isDefault: false);
      }
    }
    _addresses.add(address.copyWith(isDefault: makeDefault));
    notifyListeners();
  }

  void update(String id, AddressData address) {
    final index = _addresses.indexWhere((a) => a.id == id);
    if (index < 0) return;

    final makeDefault = address.isDefault;
    if (makeDefault) {
      for (var i = 0; i < _addresses.length; i++) {
        _addresses[i] = _addresses[i].copyWith(isDefault: false);
      }
    }

    final existing = _addresses[index];
    _addresses[index] = existing.copyWith(
      title: address.title,
      contactName: address.contactName,
      phone: address.phone,
      address: address.address,
      icon: address.icon,
      isDefault: makeDefault || existing.isDefault,
    );
    notifyListeners();
  }

  void remove(String id) {
    _addresses.removeWhere((item) => item.id == id);
    if (_addresses.isNotEmpty && !_addresses.any((a) => a.isDefault)) {
      _addresses[0] = _addresses[0].copyWith(isDefault: true);
    }
    notifyListeners();
  }
}

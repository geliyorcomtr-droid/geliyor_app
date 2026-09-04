import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/turkey_locations.dart';
import 'package:geliyor_app/data/user_doc_persist.dart';

enum AddressAccountType { individual, corporate }

class AddressData {
  const AddressData({
    required this.id,
    required this.title,
    required this.contactName,
    required this.phone,
    required this.address,
    this.city = '',
    this.district = '',
    this.icon = Icons.home_rounded,
    this.isDefault = false,
    this.accountType = AddressAccountType.individual,
    this.nationalId = '',
    this.taxId = '',
    this.taxOffice = '',
    this.isDelivery = true,
    this.isInvoice = true,
  });

  final String id;
  final String title;
  final String contactName;
  final String phone;
  final String address;
  final String city;
  final String district;
  final IconData icon;
  final bool isDefault;
  final AddressAccountType accountType;
  final String nationalId;
  final String taxId;
  final String taxOffice;
  final bool isDelivery;
  final bool isInvoice;

  bool get isCorporate => accountType == AddressAccountType.corporate;

  String get cityDistrictLabel {
    if (city.trim().isNotEmpty && district.trim().isNotEmpty) {
      return '${district.trim()} / ${city.trim()}';
    }
    if (city.trim().isNotEmpty) return city.trim();
    return '';
  }

  AddressData copyWith({
    String? title,
    String? contactName,
    String? phone,
    String? address,
    String? city,
    String? district,
    IconData? icon,
    bool? isDefault,
    AddressAccountType? accountType,
    String? nationalId,
    String? taxId,
    String? taxOffice,
    bool? isDelivery,
    bool? isInvoice,
  }) {
    return AddressData(
      id: id,
      title: title ?? this.title,
      contactName: contactName ?? this.contactName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      district: district ?? this.district,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
      accountType: accountType ?? this.accountType,
      nationalId: nationalId ?? this.nationalId,
      taxId: taxId ?? this.taxId,
      taxOffice: taxOffice ?? this.taxOffice,
      isDelivery: isDelivery ?? this.isDelivery,
      isInvoice: isInvoice ?? this.isInvoice,
    );
  }

  String get iconKey {
    if (icon == Icons.work_outline_rounded) return 'work';
    if (icon == Icons.favorite_border_rounded) return 'favorite';
    return 'home';
  }

  static IconData iconFromKey(String? key) {
    return switch (key) {
      'work' => Icons.work_outline_rounded,
      'favorite' => Icons.favorite_border_rounded,
      _ => Icons.home_rounded,
    };
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'contactName': contactName,
        'phone': phone,
        'address': address,
        'city': city,
        'district': district,
        'icon': iconKey,
        'isDefault': isDefault,
        'accountType': accountType == AddressAccountType.corporate
            ? 'corporate'
            : 'individual',
        'nationalId': nationalId,
        'taxId': taxId,
        'taxOffice': taxOffice,
        'isDelivery': isDelivery,
        'isInvoice': isInvoice,
      };

  factory AddressData.fromMap(Map<String, dynamic> data) {
    final typeRaw = (data['accountType'] as String?)?.trim() ?? 'individual';
    final address = (data['address'] as String?) ?? '';
    final inferred = TurkeyLocations.infer(
      address: address,
      city: (data['city'] as String?) ?? '',
      district: (data['district'] as String?) ?? '',
    );
    return AddressData(
      id: (data['id'] as String?) ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: (data['title'] as String?) ?? '',
      contactName: (data['contactName'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      address: address,
      city: inferred.city,
      district: inferred.district,
      icon: iconFromKey(data['icon'] as String?),
      isDefault: data['isDefault'] == true,
      accountType: typeRaw == 'corporate'
          ? AddressAccountType.corporate
          : AddressAccountType.individual,
      nationalId: (data['nationalId'] as String?) ?? '',
      taxId: (data['taxId'] as String?) ?? '',
      taxOffice: (data['taxOffice'] as String?) ?? '',
      isDelivery: data['isDelivery'] != false,
      isInvoice: data['isInvoice'] != false,
    );
  }
}

/// Uygulama genelinde paylaşılan adres listesi.
/// Adreslerim yazar; Siparişi Onayla varsayılan adresi okur.
class AddressStore extends ChangeNotifier {
  AddressStore._();

  static final AddressStore instance = AddressStore._();

  List<AddressData> _addresses = List<AddressData>.from(_guestAddresses);
  bool _suppressPersist = false;

  static const _guestAddresses = [
    AddressData(
      id: 'home',
      title: 'Evim',
      contactName: 'Can Dostu',
      phone: '+90 555 123 45 67',
      address: 'Ataşehir Mah. 34750 Ataşehir / İstanbul, Daire: 12, Kat: 4',
      city: 'İstanbul',
      district: 'Ataşehir',
      icon: Icons.home_rounded,
      isDefault: true,
    ),
    AddressData(
      id: 'work',
      title: 'İş Yerim',
      contactName: 'Can Dostu',
      phone: '+90 555 123 45 67',
      address: 'Levent Mah. Büyükdere Cad. No: 185, Şişli / İstanbul',
      city: 'İstanbul',
      district: 'Şişli',
      icon: Icons.work_outline_rounded,
    ),
    AddressData(
      id: 'mom',
      title: 'Annemin Evi',
      contactName: 'Can Dostu',
      phone: '+90 555 123 45 67',
      address: 'Kozyatağı Mah. 34742 Kadıköy / İstanbul, Daire: 8',
      city: 'İstanbul',
      district: 'Kadıköy',
      icon: Icons.favorite_border_rounded,
    ),
  ];

  List<AddressData> get addresses => List.unmodifiable(_addresses);

  AddressData? get defaultAddress {
    for (final item in _addresses) {
      if (item.isDefault && item.address.trim().isNotEmpty) return item;
    }
    return _firstMatching((item) => item.isDelivery);
  }

  AddressData? get defaultInvoiceAddress =>
      _firstMatching((item) => item.isInvoice) ?? defaultAddress;

  AddressData? _firstMatching(bool Function(AddressData item) test) {
    AddressData? fallback;
    for (final item in _addresses) {
      if (!test(item) || item.address.trim().isEmpty) continue;
      fallback ??= item;
      if (item.isDefault) return item;
    }
    return fallback;
  }

  /// Örnek misafir adresleri veya boş kayıt teslimat için geçerli sayılmaz.
  bool get hasDeliveryAddress {
    if (hasOnlyGuestAddresses) return false;
    final address = defaultAddress;
    if (address == null) return false;
    return address.address.trim().isNotEmpty;
  }

  bool get hasOnlyGuestAddresses {
    if (_addresses.length != _guestAddresses.length) return false;
    for (var i = 0; i < _addresses.length; i++) {
      if (_addresses[i].id != _guestAddresses[i].id) return false;
      if (_addresses[i].address != _guestAddresses[i].address) return false;
    }
    return true;
  }

  void showGuestAddresses() {
    _suppressPersist = true;
    _addresses = List<AddressData>.from(_guestAddresses);
    _suppressPersist = false;
    notifyListeners();
  }

  void applyRemote(List<Map<String, dynamic>> rows) {
    _suppressPersist = true;
    _addresses = rows
        .map(AddressData.fromMap)
        .where((item) => item.address.trim().isNotEmpty || item.title.trim().isNotEmpty)
        .toList();
    _suppressPersist = false;
    notifyListeners();
  }

  void setDefault(String id) {
    for (var i = 0; i < _addresses.length; i++) {
      _addresses[i] = _addresses[i].copyWith(isDefault: _addresses[i].id == id);
    }
    notifyListeners();
    _persist();
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
    _persist();
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
      city: address.city,
      district: address.district,
      icon: address.icon,
      isDefault: makeDefault || existing.isDefault,
      accountType: address.accountType,
      nationalId: address.nationalId,
      taxId: address.taxId,
      taxOffice: address.taxOffice,
      isDelivery: address.isDelivery,
      isInvoice: address.isInvoice,
    );
    notifyListeners();
    _persist();
  }

  void remove(String id) {
    _addresses.removeWhere((item) => item.id == id);
    if (_addresses.isNotEmpty && !_addresses.any((a) => a.isDefault)) {
      _addresses[0] = _addresses[0].copyWith(isDefault: true);
    }
    notifyListeners();
    _persist();
  }

  void _persist() {
    if (_suppressPersist) return;
    if (hasOnlyGuestAddresses) return;
    unawaited(_write());
  }

  Future<void> persistNow() async {
    if (hasOnlyGuestAddresses) return;
    await _write();
  }

  Future<void> _write() async {
    await UserDocPersist.merge({
      UserFields.addresses: _addresses.map((item) => item.toMap()).toList(),
    });
  }
}

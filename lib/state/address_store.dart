import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/turkey_locations.dart';
import 'package:geliyor_app/data/user_doc_persist.dart';
import 'package:geliyor_app/state/auth_store.dart';
import 'package:geliyor_app/utils/customer_location.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AddressAccountType { individual, corporate }

enum AddressKind { address, location }

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
    this.kind = AddressKind.address,
    this.latitude,
    this.longitude,
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
  final AddressKind kind;
  final double? latitude;
  final double? longitude;

  bool get isCorporate => accountType == AddressAccountType.corporate;

  bool get isLocation {
    if (id.startsWith('loc_')) return true;
    final line = address.trim();
    if (line.startsWith('Konum ·')) return true;
    if (kind != AddressKind.location) return false;
    final hasPlace = city.trim().isNotEmpty || district.trim().isNotEmpty;
    if (line.isNotEmpty && (hasPlace || line.length > 30)) return false;
    return true;
  }

  bool get hasLocation =>
      CustomerLocation.isValid(latitude, longitude);

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
    AddressKind? kind,
    double? latitude,
    double? longitude,
    bool clearLocation = false,
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
      kind: kind ?? this.kind,
      latitude: clearLocation ? null : latitude ?? this.latitude,
      longitude: clearLocation ? null : longitude ?? this.longitude,
    );
  }

  String get iconKey {
    if (isLocation || icon == Icons.my_location_rounded) return 'location';
    if (icon == Icons.work_outline_rounded) return 'work';
    if (icon == Icons.favorite_border_rounded) return 'favorite';
    return 'home';
  }

  static IconData iconFromKey(String? key) {
    return switch (key) {
      'work' => Icons.work_outline_rounded,
      'favorite' => Icons.favorite_border_rounded,
      'location' => Icons.my_location_rounded,
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
        'kind': isLocation ? 'location' : 'address',
        if (hasLocation) 'latitude': latitude,
        if (hasLocation) 'longitude': longitude,
      };

  factory AddressData.fromMap(Map<String, dynamic> data) {
    String text(dynamic value) => value == null ? '' : value.toString().trim();
    final typeRaw = text(data['accountType']);
    final address = text(data['address']);
    final inferred = TurkeyLocations.infer(
      address: address,
      city: text(data['city']),
      district: text(data['district']),
    );
    final id = text(data['id']);
    final iconName = data['icon'] is String ? data['icon'] as String : '';
    final looksLikeLocation = text(data['kind']) == 'location' ||
        id.startsWith('loc_') ||
        iconName == 'location' ||
        address.startsWith('Konum ·');
    var latitude = CustomerLocation.read(data['latitude']);
    var longitude = CustomerLocation.read(data['longitude']);
    if (!CustomerLocation.isValid(latitude, longitude) &&
        address.startsWith('Konum ·')) {
      final raw = address.substring('Konum ·'.length).trim();
      final parts = raw.split(',');
      if (parts.length >= 2) {
        latitude = double.tryParse(parts[0].trim());
        longitude = double.tryParse(parts[1].trim());
      }
    }
    return AddressData(
      id: id.isEmpty ? 'addr_${DateTime.now().microsecondsSinceEpoch}' : id,
      title: text(data['title']),
      contactName: text(data['contactName']),
      phone: text(data['phone']),
      address: address,
      city: inferred.city,
      district: inferred.district,
      icon: iconFromKey(iconName.isEmpty ? null : iconName),
      isDefault: data['isDefault'] == true,
      accountType: typeRaw == 'corporate'
          ? AddressAccountType.corporate
          : AddressAccountType.individual,
      nationalId: text(data['nationalId']),
      taxId: text(data['taxId']),
      taxOffice: text(data['taxOffice']),
      isDelivery: data['isDelivery'] != false,
      isInvoice: data['isInvoice'] != false,
      kind: looksLikeLocation
          ? AddressKind.location
          : AddressKind.address,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

/// Uygulama genelinde paylaşılan adres listesi.
/// Adreslerim yazar; Siparişi Onayla varsayılan adresi okur.
class AddressStore extends ChangeNotifier {
  AddressStore._();

  static final AddressStore instance = AddressStore._();

  List<AddressData> _addresses = List<AddressData>.from(_guestAddresses);
  AddressData? _queuedPin;
  bool _hydrated = false;
  bool _serverSynced = false;
  final Set<String> _deletedIds = {};
  bool _suppressPersist = false;
  int _editGeneration = 0;
  int _ackedGeneration = 0;

  bool get isHydrated => _hydrated;

  bool get _hasPendingEdit => _editGeneration != _ackedGeneration;

  void _touch() {
    _editGeneration++;
  }

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

  /// Örnek misafir adresleri teslimat listesinde görünmez.
  List<AddressData> get addresses {
    final queued = _queuedPin;
    if (hasOnlyGuestAddresses) {
      if (queued == null) return const [];
      return List.unmodifiable([queued]);
    }
    if (queued == null || _addresses.any((item) => item.id == queued.id)) {
      return List.unmodifiable(_collapsePins(_addresses));
    }
    return List.unmodifiable(_collapsePins([..._addresses, queued]));
  }

  AddressData? get defaultAddress {
    if (hasOnlyGuestAddresses) return null;
    for (final item in _addresses) {
      if (item.isLocation) continue;
      if (item.isDefault && item.address.trim().isNotEmpty) return item;
    }
    return _firstMatching((item) => item.isDelivery);
  }

  /// Yazılı adresten bağımsız kaydedilen konum kutuları.
  List<AddressData> get locationPins => addresses
      .where((item) => item.isLocation && item.hasLocation)
      .toList(growable: false);

  AddressData? get savedLocation {
    for (final item in locationPins.reversed) {
      return item;
    }
    for (final item in addresses) {
      if (item.hasLocation) return item;
    }
    return null;
  }

  AddressData? get defaultInvoiceAddress =>
      _firstMatching((item) => item.isInvoice) ?? defaultAddress;

  AddressData? _firstMatching(bool Function(AddressData item) test) {
    AddressData? fallback;
    for (final item in _addresses) {
      if (item.isLocation) continue;
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
    _editGeneration = 0;
    _ackedGeneration = 0;
    _hydrated = false;
    _serverSynced = false;
    _deletedIds.clear();
    _queuedPin = null;
    _suppressPersist = true;
    _addresses = List<AddressData>.from(_guestAddresses);
    _suppressPersist = false;
    notifyListeners();
  }

  void applyRemote(List<Map<String, dynamic>> rows) {
    final incoming = rows
        .map(AddressData.fromMap)
        .where(
          (item) =>
              item.address.trim().isNotEmpty || item.title.trim().isNotEmpty,
        )
        .where((item) => !_deletedIds.contains(item.id))
        .toList();
    final queued = _queuedPin;
    _queuedPin = null;
    _hydrated = true;
    _serverSynced = true;

    if (_hasPendingEdit || queued != null) {
      final localStreets = hasOnlyGuestAddresses
          ? <AddressData>[]
          : _addresses.where((item) => !item.isLocation).toList();
      final streets = [...localStreets];
      for (final item in incoming.where((item) => !item.isLocation)) {
        if (!streets.any((local) => local.id == item.id)) streets.add(item);
      }
      final pins = incoming.where((item) => item.isLocation).toList();
      final localPins = hasOnlyGuestAddresses
          ? const <AddressData>[]
          : _addresses.where((item) => item.isLocation);
      for (final pin in [...localPins, ?queued]) {
        final index = pins.indexWhere((item) => item.id == pin.id);
        if (index >= 0) {
          pins[index] = pin;
        } else {
          pins.add(pin);
        }
      }
      final merged = _collapsePins([...streets, ...pins]);
      final dropped = merged.length < streets.length + pins.length;
      _suppressPersist = true;
      _addresses = merged;
      _suppressPersist = false;
      notifyListeners();
      if (!hasOnlyGuestAddresses) {
        unawaited(_saveCache(_addresses.map((item) => item.toMap()).toList()));
      }
      if (queued != null || localPins.isNotEmpty || dropped) _persist();
      return;
    }

    var keptLocal = false;
    if (!hasOnlyGuestAddresses) {
      for (final local in _addresses) {
        if (_deletedIds.contains(local.id)) continue;
        if (incoming.any((item) => item.id == local.id)) continue;
        incoming.add(local);
        keptLocal = true;
      }
    }
    final keepSaved =
        incoming.isEmpty && _addresses.isNotEmpty && !hasOnlyGuestAddresses;
    if (keepSaved || keptLocal) {
      unawaited(_write());
      if (keepSaved) return;
    }
    final collapsed = _collapsePins(incoming);
    final dropped = collapsed.length < incoming.length;
    _suppressPersist = true;
    _addresses = collapsed;
    _suppressPersist = false;
    notifyListeners();
    if (!hasOnlyGuestAddresses) {
      unawaited(_saveCache(_addresses.map((item) => item.toMap()).toList()));
    }
    if (dropped) unawaited(_write());
  }

  void setDefault(String id) {
    _touch();
    for (var i = 0; i < _addresses.length; i++) {
      _addresses[i] = _addresses[i].copyWith(isDefault: _addresses[i].id == id);
    }
    notifyListeners();
    _persist();
  }

  void add(AddressData address) {
    _touch();
    if (hasOnlyGuestAddresses) {
      _addresses = [];
    }
    if (address.isLocation) {
      _addresses.add(
        address.copyWith(
          isDefault: false,
          isDelivery: false,
          isInvoice: false,
          kind: AddressKind.location,
        ),
      );
      notifyListeners();
      _persist();
      return;
    }
    final hasStreet = _addresses.any((item) => !item.isLocation);
    final makeDefault = address.isDefault || !hasStreet;
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
    _touch();

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

  void setLocation(
    String id, {
    required double latitude,
    required double longitude,
  }) {
    final index = _addresses.indexWhere((item) => item.id == id);
    if (index < 0) return;
    if (!CustomerLocation.isValid(latitude, longitude)) return;
    _touch();
    _addresses[index] = _addresses[index].copyWith(
      latitude: latitude,
      longitude: longitude,
    );
    notifyListeners();
    _persist();
  }

  void clearLocation(String id) {
    final index = _addresses.indexWhere((item) => item.id == id);
    if (index < 0) return;
    _touch();
    _addresses[index] = _addresses[index].copyWith(clearLocation: true);
    notifyListeners();
    _persist();
  }

  void saveLocationPin({
    String? id,
    required String title,
    required double latitude,
    required double longitude,
  }) {
    if (!CustomerLocation.isValid(latitude, longitude)) return;
    final label = title.trim().isEmpty ? 'Konumum' : title.trim();
    final pin = AddressData(
      id: (id == null || id.isEmpty)
          ? 'loc_${DateTime.now().millisecondsSinceEpoch}'
          : id,
      title: label,
      contactName: '',
      phone: '',
      address: 'Konum · ${CustomerLocation.format(latitude, longitude)}',
      icon: Icons.my_location_rounded,
      isDefault: false,
      isDelivery: false,
      isInvoice: false,
      kind: AddressKind.location,
      latitude: latitude,
      longitude: longitude,
    );
    if (hasOnlyGuestAddresses) {
      _addresses = [];
    }
    _touch();
    final index = _addresses.indexWhere((item) => item.id == pin.id);
    if (index >= 0) {
      _addresses[index] = pin;
    } else {
      _addresses.add(pin);
    }
    notifyListeners();
    _persist();
  }

  void remove(String id) {
    if (_queuedPin?.id == id) _queuedPin = null;
    _deletedIds.add(id);
    _touch();
    _addresses.removeWhere((item) => item.id == id);
    final streets = _addresses.where((item) => !item.isLocation);
    if (streets.isNotEmpty && !streets.any((item) => item.isDefault)) {
      final firstId = streets.first.id;
      for (var i = 0; i < _addresses.length; i++) {
        if (_addresses[i].id == firstId) {
          _addresses[i] = _addresses[i].copyWith(isDefault: true);
        }
      }
    }
    notifyListeners();
    _persist();
  }

  void _persist() {
    if (_suppressPersist) return;
    if (hasOnlyGuestAddresses && _queuedPin == null) return;
    unawaited(_write());
  }

  /// Kaydı bitene kadar bekler. `false` ise sunucuya yazılamadı.
  Future<bool> persistNow() => _write();

  void _absorbQueue() {
    final queued = _queuedPin;
    if (queued == null) return;
    _queuedPin = null;
    if (hasOnlyGuestAddresses) _addresses = [];
    final index = _addresses.indexWhere((item) => item.id == queued.id);
    if (index >= 0) {
      _addresses[index] = queued;
    } else {
      _addresses.add(queued);
    }
  }

  Future<bool> _write() async {
    _absorbQueue();
    if (hasOnlyGuestAddresses) return true;
    final uid = AuthStore.instance.uid;
    if (uid == null || uid.isEmpty) return false;

    final generation = _editGeneration;
    final collapsed = _collapsePins(_addresses);
    if (collapsed.length != _addresses.length) {
      _addresses = collapsed;
    }
    var payload = _addresses.map((item) => item.toMap()).toList();
    if (!_serverSynced) {
      try {
        final snap = await UserDocPersist.fetchUserDoc(uid);
        final remote = UserDocPersist.asMapList(
          snap?.data()?[UserFields.addresses],
        );
        if (remote.isNotEmpty) {
          payload = _unionAddressMaps(remote, payload)
              .where((item) => !_deletedIds.contains(item['id']?.toString()))
              .toList();
          _suppressPersist = true;
          _addresses = [
            for (final item in payload) AddressData.fromMap(item),
          ];
          _suppressPersist = false;
        }
      } catch (_) {}
    }

    try {
      await _saveCache(payload);
    } catch (_) {}

    final ok = await UserDocPersist.merge({
      UserFields.addresses: payload,
    });
    if (ok && generation == _editGeneration) {
      _serverSynced = true;
      _hydrated = true;
      _ackedGeneration = generation;
    }
    notifyListeners();
    return ok;
  }

  Future<void> restoreLocal(String uid) async {
    if (_hasPendingEdit || uid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey(uid));
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final items = <AddressData>[];
      for (final item in decoded) {
        if (item is Map) {
          items.add(AddressData.fromMap(Map<String, dynamic>.from(item)));
        }
      }
      if (items.isEmpty || _hasPendingEdit) return;
      _suppressPersist = true;
      _addresses = items;
      _hydrated = true;
      _suppressPersist = false;
      notifyListeners();
    } catch (_) {}
  }

  List<Map<String, dynamic>> _unionAddressMaps(
    List<Map<String, dynamic>> remote,
    List<Map<String, dynamic>> local,
  ) {
    final byId = <String, Map<String, dynamic>>{};
    for (final item in remote) {
      final id = item['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      byId[id] = item;
    }
    for (final item in local) {
      final id = item['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      byId[id] = item;
    }
    return byId.values.toList();
  }

  List<AddressData> _collapsePins(List<AddressData> items) {
    final streets = <AddressData>[];
    final pins = <AddressData>[];
    for (final item in items) {
      if (item.isLocation) {
        pins.add(item);
      } else {
        streets.add(item);
      }
    }
    pins.sort((a, b) {
      final scoreA = (a.hasLocation ? 2 : 0) + (_isDefaultTitle(a) ? 0 : 1);
      final scoreB = (b.hasLocation ? 2 : 0) + (_isDefaultTitle(b) ? 0 : 1);
      final byScore = scoreB.compareTo(scoreA);
      if (byScore != 0) return byScore;
      return _pinStamp(b.id).compareTo(_pinStamp(a.id));
    });
    final kept = <AddressData>[];
    for (final pin in pins) {
      final duplicate = kept.any((other) => _samePin(other, pin));
      if (!duplicate) kept.add(pin);
    }
    return [...streets, ...kept];
  }

  int _pinStamp(String id) {
    if (!id.startsWith('loc_')) return 0;
    return int.tryParse(id.substring(4)) ?? 0;
  }

  bool _isDefaultTitle(AddressData pin) {
    final title = pin.title.trim().toLowerCase();
    return title.isEmpty || title == 'konumum' || title == 'konum';
  }

  bool _samePin(AddressData a, AddressData b) {
    final left = a.title.trim().toLowerCase();
    final right = b.title.trim().toLowerCase();
    if (left.isNotEmpty && left == right) return true;
    if (a.hasLocation && b.hasLocation) {
      return (a.latitude! - b.latitude!).abs() < 0.02 &&
          (a.longitude! - b.longitude!).abs() < 0.02;
    }
    return _isDefaultTitle(a) || _isDefaultTitle(b);
  }

  String _cacheKey(String uid) => 'geliyor.addresses.$uid';

  Future<void> _saveCache(List<Map<String, dynamic>> payload) async {
    final uid = AuthStore.instance.uid;
    if (uid == null || uid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey(uid), jsonEncode(payload));
  }
}

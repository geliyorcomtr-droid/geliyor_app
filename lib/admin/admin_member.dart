import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/turkey_locations.dart';
import 'package:geliyor_app/utils/customer_location.dart';

class MemberAddress {
  const MemberAddress({
    required this.address,
    this.city = '',
    this.district = '',
    this.isDefault = false,
    this.latitude,
    this.longitude,
  });

  final String address;
  final String city;
  final String district;
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  bool get hasLocation => CustomerLocation.isValid(latitude, longitude);

  String get fullLabel {
    final inferred = TurkeyLocations.infer(
      address: address,
      city: city,
      district: district,
    );
    final cityName = inferred.city.trim().isNotEmpty
        ? inferred.city.trim()
        : city.trim();
    final districtName = inferred.district.trim().isNotEmpty
        ? inferred.district.trim()
        : district.trim();
    final place = [
      districtName,
      cityName,
    ].where((part) => part.isNotEmpty).join(' / ');
    final street = address.trim();
    if (street.isEmpty) return place;
    if (place.isEmpty) return street;
    if (street.endsWith(place)) return street;
    return '$street\n$place';
  }

  factory MemberAddress.fromMap(Map<String, dynamic> data) {
    return MemberAddress(
      address: AdminMember._asString(data['address']),
      city: AdminMember._asString(data['city']),
      district: AdminMember._asString(data['district']),
      isDefault: data['isDefault'] == true,
      latitude: CustomerLocation.read(data['latitude']),
      longitude: CustomerLocation.read(data['longitude']),
    );
  }
}

class AdminMember {
  const AdminMember({
    required this.id,
    required this.displayName,
    required this.phoneNumber,
    this.email = '',
    this.membershipType = 'bireysel',
    this.memberGroup = '',
    this.specialDiscount = 0,
    this.riskyCustomer = false,
    this.active = true,
    this.isGuest = false,
    this.userRole = 'customer',
    this.addresses = const [],
    this.createdAt,
  });

  final String id;
  final String displayName;
  final String phoneNumber;
  final String email;
  final String membershipType;
  final String memberGroup;
  final int specialDiscount;
  final bool riskyCustomer;
  final bool active;
  final bool isGuest;
  final String userRole;
  final List<MemberAddress> addresses;
  final DateTime? createdAt;

  bool get isCorporate {
    final type = membershipType.toLowerCase();
    return type.contains('kurum') || type.contains('bayi');
  }

  String get membershipTypeLabel {
    if (isCorporate) return 'Kurumsal';
    return 'Bireysel';
  }

  String get initials {
    final parts = _asString(displayName)
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'Ü';
    String letter(String value) => value.substring(0, 1).toUpperCase();
    if (parts.length == 1) return letter(parts.first);
    return '${letter(parts.first)}${letter(parts.last)}';
  }

  bool get isAdminRole => _asString(userRole).toLowerCase() == 'admin';

  String get roleLabel {
    if (isAdminRole) return 'Admin';
    if (isGuest) return 'Misafir';
    return 'Üye';
  }

  String get createdAtShort {
    final date = createdAt;
    if (date == null) return '—';
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}.${two(date.month)}.${date.year}';
  }

  String get addressBlock {
    final lines = <String>[];
    for (final item in addresses) {
      final label = item.fullLabel.trim();
      if (label.isEmpty || lines.contains(label)) continue;
      lines.add(label);
    }
    return lines.join('\n');
  }

  static String _asString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    return value.toString().trim();
  }

  static bool _asBool(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.trim().toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return fallback;
  }

  factory AdminMember.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final created = data[UserFields.createdTime];
    final membershipType = _asString(data[UserFields.membershipType]);
    final userRole = _asString(
      data[UserFields.userRole] ?? data[UserFields.role],
    );
    return AdminMember(
      id: doc.id,
      displayName: _asString(data[UserFields.displayName]),
      phoneNumber: _asString(data[UserFields.phoneNumber]),
      email: _asString(data[UserFields.email]),
      membershipType: membershipType.isEmpty ? 'bireysel' : membershipType.toLowerCase(),
      memberGroup: _asString(data[UserFields.memberGroup]),
      specialDiscount: (data[UserFields.specialDiscount] as num?)?.toInt() ?? 0,
      riskyCustomer: _asBool(data[UserFields.riskyCustomer], fallback: false),
      active: _asBool(data[UserFields.active], fallback: true),
      isGuest: _asBool(data[UserFields.isGuest], fallback: false),
      userRole: userRole.isEmpty ? 'customer' : userRole,
      addresses: _addressesFrom(data[UserFields.addresses]),
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }

  Map<String, dynamic> toMap({bool includeCreated = false}) {
    return {
      UserFields.uid: id,
      UserFields.displayName: displayName.trim(),
      UserFields.phoneNumber: phoneNumber.trim(),
      UserFields.email: email.trim(),
      UserFields.membershipType: membershipType.trim().isEmpty
          ? 'bireysel'
          : membershipType.trim().toLowerCase(),
      UserFields.memberGroup: memberGroup.trim(),
      UserFields.specialDiscount: specialDiscount,
      UserFields.riskyCustomer: riskyCustomer,
      UserFields.active: active,
      UserFields.isGuest: isGuest,
      UserFields.userRole: userRole.trim().isEmpty ? 'customer' : userRole,
      UserFields.updatedAt: FieldValue.serverTimestamp(),
      if (includeCreated) UserFields.createdTime: FieldValue.serverTimestamp(),
    };
  }

  AdminMember copyWith({
    String? displayName,
    String? phoneNumber,
    String? email,
    String? membershipType,
    String? memberGroup,
    int? specialDiscount,
    bool? riskyCustomer,
    bool? active,
    bool? isGuest,
    String? userRole,
    List<MemberAddress>? addresses,
  }) {
    return AdminMember(
      id: id,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      membershipType: membershipType ?? this.membershipType,
      memberGroup: memberGroup ?? this.memberGroup,
      specialDiscount: specialDiscount ?? this.specialDiscount,
      riskyCustomer: riskyCustomer ?? this.riskyCustomer,
      active: active ?? this.active,
      isGuest: isGuest ?? this.isGuest,
      userRole: userRole ?? this.userRole,
      addresses: addresses ?? this.addresses,
      createdAt: createdAt,
    );
  }

  static List<MemberAddress> _addressesFrom(dynamic raw) {
    if (raw is! List) return const [];
    final items = <MemberAddress>[];
    for (final item in raw) {
      if (item is! Map) continue;
      items.add(MemberAddress.fromMap(Map<String, dynamic>.from(item)));
    }
    items.sort((a, b) {
      if (a.isDefault == b.isDefault) return 0;
      return a.isDefault ? -1 : 1;
    });
    return items;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geliyor_app/data/firestore_collections.dart';

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
      createdAt: createdAt,
    );
  }
}

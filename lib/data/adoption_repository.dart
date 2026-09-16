import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geliyor_app/data/firestore_collections.dart';

class AdoptionListing {
  const AdoptionListing({
    required this.id,
    required this.userId,
    required this.category,
    required this.name,
    this.species = 'Kedi',
    this.breed = '',
    this.gender = '',
    this.age = '',
    this.weight = '',
    this.city = '',
    this.description = '',
    this.imageUrls = const [],
    this.videoUrls = const [],
    this.phone = '',
    this.contactName = '',
    this.contactPreference = 'phone',
    this.vaccinated = false,
    this.neutered = false,
    this.hasHealthIssue = false,
    this.indoorOnly = false,
    this.status = AdoptionStatuses.pending,
    this.rejectReason = '',
    this.createdAt,
  });

  final String id;
  final String userId;
  final String category;
  final String name;
  final String species;
  final String breed;
  final String gender;
  final String age;
  final String weight;
  final String city;
  final String description;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final String phone;
  final String contactName;
  final String contactPreference;
  final bool vaccinated;
  final bool neutered;
  final bool hasHealthIssue;
  final bool indoorOnly;
  final String status;
  final String rejectReason;
  final DateTime? createdAt;

  String get coverImage =>
      imageUrls.isEmpty ? '' : imageUrls.first.trim();

  int get mediaCount => imageUrls.length + videoUrls.length;

  String get categoryLabel => AdoptionCategories.label(category);

  String get badgeLabel => AdoptionCategories.badge(category);

  String get speciesLine {
    final parts = <String>[
      if (species.trim().isNotEmpty) species.trim(),
      if (breed.trim().isNotEmpty) breed.trim(),
    ];
    return parts.join(' · ');
  }

  factory AdoptionListing.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final created = data[AdoptionListingFields.createdAt];
    final images = data[AdoptionListingFields.imageUrls];
    final videos = data[AdoptionListingFields.videoUrls];
    return AdoptionListing(
      id: doc.id,
      userId: (data[AdoptionListingFields.userId] as String?) ?? '',
      category:
          (data[AdoptionListingFields.category] as String?) ??
          AdoptionCategories.adopt,
      name: (data[AdoptionListingFields.name] as String?) ?? '',
      species: (data[AdoptionListingFields.species] as String?) ?? 'Kedi',
      breed: (data[AdoptionListingFields.breed] as String?) ?? '',
      gender: (data[AdoptionListingFields.gender] as String?) ?? '',
      age: (data[AdoptionListingFields.age] as String?) ?? '',
      weight: (data[AdoptionListingFields.weight] as String?) ?? '',
      city: (data[AdoptionListingFields.city] as String?) ?? '',
      description: (data[AdoptionListingFields.description] as String?) ?? '',
      imageUrls: images is List
          ? images
                .map((item) => '$item'.trim())
                .where((item) => item.isNotEmpty)
                .toList()
          : const [],
      videoUrls: videos is List
          ? videos
                .map((item) => '$item'.trim())
                .where((item) => item.isNotEmpty)
                .toList()
          : const [],
      phone: (data[AdoptionListingFields.phone] as String?) ?? '',
      contactName: (data[AdoptionListingFields.contactName] as String?) ?? '',
      contactPreference:
          (data[AdoptionListingFields.contactPreference] as String?) ?? 'phone',
      vaccinated: data[AdoptionListingFields.vaccinated] == true,
      neutered: data[AdoptionListingFields.neutered] == true,
      hasHealthIssue: data[AdoptionListingFields.hasHealthIssue] == true,
      indoorOnly: data[AdoptionListingFields.indoorOnly] == true,
      status:
          (data[AdoptionListingFields.status] as String?) ??
          AdoptionStatuses.pending,
      rejectReason: (data[AdoptionListingFields.rejectReason] as String?) ?? '',
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }

  Map<String, dynamic> toCreateMap() => {
    AdoptionListingFields.userId: userId,
    AdoptionListingFields.category: category,
    AdoptionListingFields.name: name.trim(),
    AdoptionListingFields.species: species.trim(),
    AdoptionListingFields.breed: breed.trim(),
    AdoptionListingFields.gender: gender.trim(),
    AdoptionListingFields.age: age.trim(),
    AdoptionListingFields.weight: weight.trim(),
    AdoptionListingFields.city: city.trim(),
    AdoptionListingFields.description: description.trim(),
    AdoptionListingFields.imageUrls: imageUrls,
    AdoptionListingFields.videoUrls: videoUrls,
    AdoptionListingFields.phone: phone.trim(),
    AdoptionListingFields.contactName: contactName.trim(),
    AdoptionListingFields.contactPreference: contactPreference,
    AdoptionListingFields.vaccinated: vaccinated,
    AdoptionListingFields.neutered: neutered,
    AdoptionListingFields.hasHealthIssue: hasHealthIssue,
    AdoptionListingFields.indoorOnly: indoorOnly,
    AdoptionListingFields.status: AdoptionStatuses.pending,
    AdoptionListingFields.rejectReason: '',
    AdoptionListingFields.createdAt: FieldValue.serverTimestamp(),
    AdoptionListingFields.updatedAt: FieldValue.serverTimestamp(),
  };
}

class AdoptionRepository {
  AdoptionRepository._();
  static final AdoptionRepository instance = AdoptionRepository._();

  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore
      .instance
      .collection(FirestoreCollections.adoptionListings);

  Stream<List<AdoptionListing>> watchApproved() {
    return _col
        .where(
          AdoptionListingFields.status,
          isEqualTo: AdoptionStatuses.approved,
        )
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(AdoptionListing.fromDoc).toList()
            ..sort((a, b) {
              final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final right =
                  b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return right.compareTo(left);
            });
          return list;
        });
  }

  Stream<List<AdoptionListing>> watchMine(String userId) {
    if (userId.isEmpty) return Stream.value(const []);
    return _col
        .where(AdoptionListingFields.userId, isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(AdoptionListing.fromDoc).toList()
            ..sort((a, b) {
              final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final right =
                  b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return right.compareTo(left);
            });
          return list;
        });
  }

  Stream<List<AdoptionListing>> watchAll() {
    return _col.snapshots().map((snap) {
      final list = snap.docs.map(AdoptionListing.fromDoc).toList()
        ..sort((a, b) {
          final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return right.compareTo(left);
        });
      return list;
    });
  }

  Future<void> create(AdoptionListing listing) {
    return _col.add(listing.toCreateMap());
  }

  Future<void> update(AdoptionListing listing) {
    return _col.doc(listing.id).set({
      AdoptionListingFields.category: listing.category,
      AdoptionListingFields.name: listing.name.trim(),
      AdoptionListingFields.species: listing.species.trim(),
      AdoptionListingFields.breed: listing.breed.trim(),
      AdoptionListingFields.gender: listing.gender.trim(),
      AdoptionListingFields.age: listing.age.trim(),
      AdoptionListingFields.weight: listing.weight.trim(),
      AdoptionListingFields.city: listing.city.trim(),
      AdoptionListingFields.description: listing.description.trim(),
      AdoptionListingFields.imageUrls: listing.imageUrls,
      AdoptionListingFields.videoUrls: listing.videoUrls,
      AdoptionListingFields.phone: listing.phone.trim(),
      AdoptionListingFields.contactName: listing.contactName.trim(),
      AdoptionListingFields.contactPreference: listing.contactPreference,
      AdoptionListingFields.vaccinated: listing.vaccinated,
      AdoptionListingFields.neutered: listing.neutered,
      AdoptionListingFields.hasHealthIssue: listing.hasHealthIssue,
      AdoptionListingFields.indoorOnly: listing.indoorOnly,
      AdoptionListingFields.status: AdoptionStatuses.pending,
      AdoptionListingFields.rejectReason: '',
      AdoptionListingFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> delete(AdoptionListing listing) async {
    await _col.doc(listing.id).delete();
    for (final url in [...listing.imageUrls, ...listing.videoUrls]) {
      final trimmed = url.trim();
      if (trimmed.isEmpty) continue;
      try {
        await FirebaseStorage.instance.refFromURL(trimmed).delete();
      } catch (_) {}
    }
  }

  Future<void> setStatus({
    required String id,
    required String status,
    String rejectReason = '',
  }) {
    return _col.doc(id).set({
      AdoptionListingFields.status: status,
      AdoptionListingFields.rejectReason: rejectReason,
      AdoptionListingFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

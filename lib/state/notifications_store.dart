import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/theme/app_colors.dart';

enum AppNotificationCategory { campaign, reminder, system, order }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.unread,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final AppNotificationCategory category;
  final bool unread;
  final DateTime? createdAt;

  factory AppNotification.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final created = data[NotificationFields.createdAt];
    return AppNotification(
      id: doc.id,
      title: (data[NotificationFields.title] as String?)?.trim() ?? '',
      body: (data[NotificationFields.body] as String?)?.trim() ?? '',
      category: _parseCategory(data[NotificationFields.category] as String?),
      unread: data[NotificationFields.unread] != false,
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }

  static AppNotificationCategory _parseCategory(String? raw) {
    switch (raw) {
      case 'campaign':
        return AppNotificationCategory.campaign;
      case 'reminder':
        return AppNotificationCategory.reminder;
      case 'order':
        return AppNotificationCategory.order;
      default:
        return AppNotificationCategory.system;
    }
  }

  IconData get icon {
    switch (category) {
      case AppNotificationCategory.campaign:
        return Icons.local_offer_rounded;
      case AppNotificationCategory.reminder:
        return Icons.notifications_active_rounded;
      case AppNotificationCategory.order:
        return Icons.local_shipping_rounded;
      case AppNotificationCategory.system:
        return Icons.notifications_rounded;
    }
  }

  Color get iconBg {
    switch (category) {
      case AppNotificationCategory.campaign:
        return AppColors.success;
      case AppNotificationCategory.reminder:
        return AppColors.primary;
      case AppNotificationCategory.order:
        return AppColors.warning;
      case AppNotificationCategory.system:
        return AppColors.primaryLight;
    }
  }
}

class NotificationsStore extends ChangeNotifier {
  NotificationsStore._();

  static final NotificationsStore instance = NotificationsStore._();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  List<AppNotification> items = const [];
  String? _uid;

  int get unreadCount => items.where((item) => item.unread).length;

  void bind(String? uid) {
    if (_uid == uid && _sub != null) return;
    _uid = uid;
    unawaited(_sub?.cancel());
    _sub = null;
    items = const [];
    notifyListeners();
    if (uid == null) return;
    _sub = FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .doc(uid)
        .collection('notifications')
        .orderBy(NotificationFields.createdAt, descending: true)
        .limit(80)
        .snapshots()
        .listen((snap) {
          items = [
            for (final doc in snap.docs) AppNotification.fromDoc(doc),
          ];
          notifyListeners();
        }, onError: (_) {});
  }

  Future<void> markRead(String id) async {
    final uid = _uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .doc(uid)
        .collection('notifications')
        .doc(id)
        .set({NotificationFields.unread: false}, SetOptions(merge: true));
  }

  Future<void> markAllRead() async {
    final uid = _uid;
    if (uid == null) return;
    final unread = items.where((item) => item.unread);
    final batch = FirebaseFirestore.instance.batch();
    for (final item in unread) {
      batch.set(
        FirebaseFirestore.instance
            .collection(FirestoreCollections.users)
            .doc(uid)
            .collection('notifications')
            .doc(item.id),
        {NotificationFields.unread: false},
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }
}

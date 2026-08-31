import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/firebase_options.dart';
import 'package:geliyor_app/state/notifications_store.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushService {
  PushService._();

  static final PushService instance = PushService._();

  StreamSubscription<String>? _tokenSub;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
    FirebaseAuth.instance.authStateChanges().listen((user) {
      unawaited(syncForUser(user?.uid));
    });
  }

  Future<void> syncForUser(String? uid) async {
    NotificationsStore.instance.bind(uid);
    if (kIsWeb) return;
    await _tokenSub?.cancel();
    _tokenSub = null;
    if (uid == null) return;

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    final token = await messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _saveToken(uid, token);
    }
    _tokenSub = messaging.onTokenRefresh.listen((value) {
      unawaited(_saveToken(uid, value));
    });
  }

  Future<void> _saveToken(String uid, String token) async {
    final tokenId = token.replaceAll('/', '_');
    await FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .doc(uid)
        .collection('fcm_tokens')
        .doc(tokenId)
        .set({
          FcmTokenFields.token: token,
          FcmTokenFields.platform: defaultTargetPlatform.name,
          FcmTokenFields.updatedAt: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }
}

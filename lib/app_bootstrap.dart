import 'dart:async';

class AppBootstrap {
  AppBootstrap._();

  static final Completer<void> _firebase = Completer<void>();

  static Future<void> get whenFirebaseReady => _firebase.future;

  static void markFirebaseReady() {
    if (!_firebase.isCompleted) {
      _firebase.complete();
    }
  }
}

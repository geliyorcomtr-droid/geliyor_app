import 'package:firebase_storage/firebase_storage.dart';

const storageCacheControl = 'public, max-age=31536000, immutable';

SettableMetadata storageImageMetadata(String contentType) {
  return SettableMetadata(
    contentType: contentType,
    cacheControl: storageCacheControl,
  );
}

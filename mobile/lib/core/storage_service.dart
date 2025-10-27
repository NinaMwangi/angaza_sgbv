import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static final _storage = FirebaseStorage.instance;

  /// Upload a file and return its download URL.
  static Future<String?> uploadFile({
    required String userId,
    required String incidentId,
    required String localPath,
    String folder = 'audio',
  }) async {
    final file = File(localPath);
    if (!file.existsSync()) return null;

    final ref = _storage.ref('$folder/$userId/$incidentId.m4a');
    final meta = SettableMetadata(contentType: 'audio/m4a');
    await ref.putFile(file, meta);
    return await ref.getDownloadURL();
  }

  /// Optionally delete a remote file.
  static Future<void> deleteFile(String path) async {
    try {
      await _storage.ref(path).delete();
    } catch (_) {}
  }
}

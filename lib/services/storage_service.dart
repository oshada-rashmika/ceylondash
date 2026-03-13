import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Max file size: 5 MB.
  static const int maxFileSizeBytes = 5 * 1024 * 1024;

  /// Returns `true` if the file size is strictly less than [maxFileSizeBytes].
  static bool isFileSizeValid(File file) {
    return file.lengthSync() < maxFileSizeBytes;
  }

  /// Uploads the [imageFile] under `profile_pictures/{uid}` and returns the
  /// download URL. Overwrites any previous picture for the same user.
  Future<String> uploadProfilePicture(String uid, File imageFile) async {
    final ref = _storage.ref().child('profile_pictures/$uid');
    await ref.putFile(imageFile, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
  }

  /// Deletes the profile picture for [uid] from Cloud Storage.
  Future<void> deleteProfilePicture(String uid) async {
    try {
      final ref = _storage.ref().child('profile_pictures/$uid');
      await ref.delete();
    } on FirebaseException catch (e) {
      // Ignore "object-not-found" — nothing to delete.
      if (e.code != 'object-not-found') rethrow;
    }
  }
}

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class CloudinaryService {
  static final _storage = FirebaseStorage.instance;
  static const _uuid = Uuid();

  static Future<String> uploadFile(File file, {String folder = 'flux'}) async {
    final ext = file.path.split('.').last;
    final name = '${_uuid.v4()}.$ext';
    final ref = _storage.ref().child('$folder/$name');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  static Future<String> uploadImage(File file) =>
      uploadFile(file, folder: 'flux/images');

  static Future<String> uploadAudio(File file) =>
      uploadFile(file, folder: 'flux/audio');

  static Future<String> uploadDocument(File file) =>
      uploadFile(file, folder: 'flux/documents');
}
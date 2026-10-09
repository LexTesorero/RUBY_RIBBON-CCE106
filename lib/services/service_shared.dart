import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';

typedef Docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>;

/// Newest first, using each document's `created_at`.
Docs newestFirst(Docs docs) {
  final list = [...docs];
  list.sort((a, b) {
    final at = a.data()['created_at'] as Timestamp?;
    final bt = b.data()['created_at'] as Timestamp?;
    if (at == null || bt == null) return 0;
    return bt.compareTo(at);
  });
  return list;
}

/// ---- PLACEHOLDERS: fill these in from your Cloudinary dashboard ----
/// The preset must be an UNSIGNED upload preset. Never put the API secret in the app.
class CloudinaryConfig {
  static const String cloudName = 'dvflkxleu';
  static const String uploadPreset = 'ruby_ribbon_unsigned';
}

class PickedImage {
  final Uint8List bytes; // instant local preview
  final String url; // Cloudinary URL to store in Firestore
  PickedImage({required this.bytes, required this.url});
}

class CloudinaryService {
  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    CloudinaryConfig.cloudName,
    CloudinaryConfig.uploadPreset,
    cache: false,
  );
  final ImagePicker _picker = ImagePicker();

  /// Opens the gallery/camera, uploads the chosen photo to Cloudinary, and
  /// returns the bytes (for preview) plus the hosted URL. Null if cancelled.
  Future<PickedImage?> pickAndUpload({
    ImageSource source = ImageSource.gallery,
    String folder = 'ruby_ribbon',
  }) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1600);
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    final name = picked.name.isNotEmpty ? picked.name : 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final res = await _cloudinary.uploadFile(
      CloudinaryFile.fromBytesData(
        bytes,
        identifier: name,
        folder: folder,
        resourceType: CloudinaryResourceType.Image,
      ),
    );
    return PickedImage(bytes: bytes, url: res.secureUrl);
  }
}
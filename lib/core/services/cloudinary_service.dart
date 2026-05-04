import 'dart:convert';
import 'dart:typed_data';

import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Centralized Cloudinary service for NurseUp.
///
/// Uploads use the *unsigned* upload preset (`CLOUDINARY_UPLOAD_PRESET`),
/// so no API secret is required on the device. Deletes require the
/// admin API and are NOT safe from client devices — they are intentionally
/// left unimplemented unless the API key/secret are present (dev-only).
class CloudinaryService {
  CloudinaryService._();

  static final CloudinaryService instance = CloudinaryService._();

  Cloudinary? _cloudinary;
  String? _cloudName;
  String? _uploadPreset;
  String? _apiKey;
  String? _apiSecret;

  /// Call once on app startup, AFTER `dotenv.load()`.
  void initialize() {
    _cloudName = dotenv.maybeGet('CLOUDINARY_CLOUD_NAME');
    _uploadPreset = dotenv.maybeGet('CLOUDINARY_UPLOAD_PRESET');
    _apiKey = dotenv.maybeGet('CLOUDINARY_API_KEY');
    _apiSecret = dotenv.maybeGet('CLOUDINARY_API_SECRET');

    if (_cloudName == null || _cloudName!.isEmpty) {
      throw StateError(
          'CLOUDINARY_CLOUD_NAME missing from .env — Cloudinary not initialized.');
    }
    _cloudinary = Cloudinary.fromCloudName(cloudName: _cloudName!);
  }

  /// Cloudinary instance for building delivery URLs / transformations.
  Cloudinary get cloudinary {
    final c = _cloudinary;
    if (c == null) {
      throw StateError(
          'CloudinaryService not initialized. Call initialize() in main().');
    }
    return c;
  }

  String get cloudName => _cloudName ?? '';

  /// Upload a profile picture (image bytes) to `nurseup/profiles/`.
  /// Returns the Cloudinary upload result (secure_url + public_id).
  Future<CloudinaryUploadResult> uploadProfileImage({
    required Uint8List bytes,
    required String fileName,
    String? userId,
  }) {
    final publicId = userId != null && userId.isNotEmpty ? userId : null;
    return _uploadBytes(
      bytes: bytes,
      fileName: fileName,
      folder: 'nurseup/profiles',
      resourceType: 'image',
      publicId: publicId,
    );
  }

  /// Upload a PDF (or other document) to `nurseup/documents/`.
  Future<CloudinaryUploadResult> uploadPdf({
    required Uint8List bytes,
    required String fileName,
  }) {
    return _uploadBytes(
      bytes: bytes,
      fileName: fileName,
      folder: 'nurseup/documents',
      // Cloudinary treats PDFs as either `image` or `raw`. Using `raw` keeps
      // the original bytes intact and avoids unintended PDF→image conversion.
      resourceType: 'raw',
    );
  }

  /// Upload a 3D model (.glb / .obj / .gltf) to `nurseup/models/`.
  Future<CloudinaryUploadResult> uploadModel({
    required Uint8List bytes,
    required String fileName,
  }) {
    return _uploadBytes(
      bytes: bytes,
      fileName: fileName,
      folder: 'nurseup/models',
      resourceType: 'raw',
    );
  }

  /// Build a delivery URL for a previously-uploaded asset.
  ///
  /// Example: `assetUrl('nurseup/profiles/abc123', resourceType: 'image')`.
  String assetUrl(
    String publicId, {
    String resourceType = 'image',
    String type = 'upload',
  }) {
    return 'https://res.cloudinary.com/$cloudName/$resourceType/$type/$publicId';
  }

  /// Delete an asset by public ID.
  ///
  /// **Important:** the destroy endpoint requires API key + signed request.
  /// Calling this from a production mobile build is discouraged because it
  /// requires the API secret on-device. We support it for dev/admin use only;
  /// returns `false` if the secret is not configured.
  Future<bool> deleteAsset({
    required String publicId,
    String resourceType = 'image',
  }) async {
    final apiKey = _apiKey;
    final apiSecret = _apiSecret;
    if (apiKey == null ||
        apiKey.isEmpty ||
        apiKey == 'your_api_key_here' ||
        apiSecret == null ||
        apiSecret.isEmpty ||
        apiSecret == 'your_api_secret_here') {
      // Not configured — caller should treat as soft-failure.
      return false;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final toSign = 'public_id=$publicId&timestamp=$timestamp$apiSecret';
    final signature = _sha1Hex(toSign);

    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/destroy');
    try {
      final response = await http.post(uri, body: {
        'public_id': publicId,
        'api_key': apiKey,
        'timestamp': '$timestamp',
        'signature': signature,
      });
      if (response.statusCode != 200) {
        throw CloudinaryException(_friendlyError(response.body));
      }
      final body = json.decode(response.body) as Map<String, dynamic>;
      return body['result'] == 'ok';
    } catch (error) {
      throw CloudinaryException(_friendlyError(error));
    }
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<CloudinaryUploadResult> _uploadBytes({
    required Uint8List bytes,
    required String fileName,
    required String folder,
    required String resourceType,
    String? publicId,
  }) async {
    final cloudName = _cloudName;
    final preset = _uploadPreset;
    if (cloudName == null || cloudName.isEmpty) {
      throw CloudinaryException(
          'Cloudinary cloud name is missing. Check your .env file.');
    }
    if (preset == null || preset.isEmpty) {
      throw CloudinaryException(
          'CLOUDINARY_UPLOAD_PRESET is missing. Create an unsigned upload preset.');
    }

    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload');
    try {
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = preset
        ..fields['folder'] = folder
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ));
      if (publicId != null && publicId.isNotEmpty) {
        request.fields['public_id'] = publicId;
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CloudinaryException(_friendlyError(response.body));
      }

      final body = json.decode(response.body) as Map<String, dynamic>;
      final secureUrl = body['secure_url'] as String?;
      final pid = body['public_id'] as String?;
      if (secureUrl == null || pid == null) {
        throw CloudinaryException(
            'Cloudinary did not return a URL for the uploaded asset.');
      }
      return CloudinaryUploadResult(
        secureUrl: secureUrl,
        publicId: pid,
        resourceType: resourceType,
        bytes: (body['bytes'] as num?)?.toInt() ?? bytes.length,
        format: body['format'] as String?,
      );
    } on CloudinaryException {
      rethrow;
    } catch (error) {
      throw CloudinaryException(_friendlyError(error));
    }
  }

  String _friendlyError(dynamic error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('socket') ||
        msg.contains('network') ||
        msg.contains('failed host lookup')) {
      return 'Network error. Please check your internet connection.';
    }
    if (msg.contains('upload preset') || msg.contains('preset not found')) {
      return 'Upload preset is invalid or not configured. '
          'Create an unsigned preset named in CLOUDINARY_UPLOAD_PRESET.';
    }
    if (msg.contains('unauthorized') || msg.contains('401')) {
      return 'Cloudinary rejected the request. Verify your cloud name and preset.';
    }
    if (msg.contains('413') || msg.contains('too large')) {
      return 'File is too large for Cloudinary.';
    }
    return 'Cloudinary upload failed. Please try again.';
  }

  String _sha1Hex(String input) {
    // Lightweight inline SHA-1 to avoid pulling in `crypto` just for delete.
    // Source: https://en.wikipedia.org/wiki/SHA-1#Pseudocode
    final bytes = utf8.encode(input);
    final ml = bytes.length * 8;
    final padded = <int>[...bytes, 0x80];
    while (padded.length % 64 != 56) {
      padded.add(0);
    }
    for (var i = 7; i >= 0; i--) {
      padded.add((ml >> (i * 8)) & 0xff);
    }
    var h0 = 0x67452301;
    var h1 = 0xEFCDAB89;
    var h2 = 0x98BADCFE;
    var h3 = 0x10325476;
    var h4 = 0xC3D2E1F0;
    for (var chunk = 0; chunk < padded.length; chunk += 64) {
      final w = List<int>.filled(80, 0);
      for (var i = 0; i < 16; i++) {
        w[i] = (padded[chunk + i * 4] << 24) |
            (padded[chunk + i * 4 + 1] << 16) |
            (padded[chunk + i * 4 + 2] << 8) |
            (padded[chunk + i * 4 + 3]);
      }
      for (var i = 16; i < 80; i++) {
        final v = w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16];
        w[i] = ((v << 1) | (v >>> 31)) & 0xFFFFFFFF;
      }
      var a = h0, b = h1, c = h2, d = h3, e = h4;
      for (var i = 0; i < 80; i++) {
        int f, k;
        if (i < 20) {
          f = (b & c) | ((~b) & d);
          k = 0x5A827999;
        } else if (i < 40) {
          f = b ^ c ^ d;
          k = 0x6ED9EBA1;
        } else if (i < 60) {
          f = (b & c) | (b & d) | (c & d);
          k = 0x8F1BBCDC;
        } else {
          f = b ^ c ^ d;
          k = 0xCA62C1D6;
        }
        final temp = ((((a << 5) | (a >>> 27)) & 0xFFFFFFFF) +
                f +
                e +
                k +
                w[i]) &
            0xFFFFFFFF;
        e = d;
        d = c;
        c = ((b << 30) | (b >>> 2)) & 0xFFFFFFFF;
        b = a;
        a = temp;
      }
      h0 = (h0 + a) & 0xFFFFFFFF;
      h1 = (h1 + b) & 0xFFFFFFFF;
      h2 = (h2 + c) & 0xFFFFFFFF;
      h3 = (h3 + d) & 0xFFFFFFFF;
      h4 = (h4 + e) & 0xFFFFFFFF;
    }
    String hex(int v) => v.toRadixString(16).padLeft(8, '0');
    return '${hex(h0)}${hex(h1)}${hex(h2)}${hex(h3)}${hex(h4)}';
  }
}

class CloudinaryUploadResult {
  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
    required this.resourceType,
    required this.bytes,
    this.format,
  });

  final String secureUrl;
  final String publicId;
  final String resourceType;
  final int bytes;
  final String? format;
}

class CloudinaryException implements Exception {
  CloudinaryException(this.message);
  final String message;
  @override
  String toString() => message;
}

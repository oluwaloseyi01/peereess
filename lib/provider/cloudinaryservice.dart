import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String _cloudName = 'dqzdc5iea'; // ← paste here
  static const String _uploadPreset = 'peereess'; // ← paste here

  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  // ===================== UPLOAD FROM FILE (mobile) =====================
  static Future<String> uploadImage(File imageFile) async {
    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

    request.fields['upload_preset'] = _uploadPreset;
    request.fields['folder'] = 'products';

    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final data = jsonDecode(body);

    if (response.statusCode == 200) {
      return data['secure_url'] as String;
    } else {
      throw Exception('Upload failed: ${data['error']['message']}');
    }
  }

  // ===================== UPLOAD FROM BYTES (web / FilePicker) =====================
  /// Used by productupload_provider — FilePicker returns Uint8List on web
  static Future<String> uploadImageFromBytes(
    Uint8List bytes, {
    String filename = 'product.jpg',
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

    request.fields['upload_preset'] = _uploadPreset;
    request.fields['folder'] = 'products';

    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final data = jsonDecode(body);

    if (response.statusCode == 200) {
      return data['secure_url'] as String;
    } else {
      throw Exception('Upload failed: ${data['error']['message']}');
    }
  }

  // ===================== UPLOAD MULTIPLE BYTES =====================
  /// Uploads a list of Uint8List images and returns all URLs
  static Future<List<String>> uploadImageBytes(List<Uint8List> images) async {
    final List<String> urls = [];

    for (int i = 0; i < images.length; i++) {
      final url = await uploadImageFromBytes(
        images[i],
        filename: 'product_$i.jpg',
      );
      urls.add(url);
    }

    return urls;
  }

  // ===================== UPLOAD MULTIPLE FILES =====================
  static Future<List<String>> uploadImages(List<File> imageFiles) async {
    final List<String> urls = [];
    for (final file in imageFiles) {
      final url = await uploadImage(file);
      urls.add(url);
    }
    return urls;
  }
}

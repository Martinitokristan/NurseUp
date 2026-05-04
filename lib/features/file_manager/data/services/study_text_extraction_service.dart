import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class StudyTextExtractionException implements Exception {
  const StudyTextExtractionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class StudyTextExtractionResult {
  const StudyTextExtractionResult({required this.text, required this.method});

  final String text;
  final String method;
}

class StudyTextExtractionService {
  const StudyTextExtractionService();

  static const int minimumReadableCharacters = 80;

  Future<StudyTextExtractionResult> extract({
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
    String? path,
  }) async {
    final extension = p.extension(fileName).replaceFirst('.', '').toLowerCase();
    final resolvedMime = (mimeType ?? '').toLowerCase();

    if (_isImage(extension, resolvedMime)) {
      return _extractImage(bytes: bytes, fileName: fileName, path: path);
    }
    if (extension == 'pdf' || resolvedMime == 'application/pdf') {
      return _extractPdf(bytes);
    }
    if (extension == 'txt' || resolvedMime.startsWith('text/')) {
      return _validate(_decodeText(bytes), 'plain_text');
    }
    if (extension == 'doc' || extension == 'docx') {
      throw const StudyTextExtractionException('Word documents are not supported on this device yet. Please export the document as PDF or TXT, then upload it again.');
    }

    throw const StudyTextExtractionException('Please upload PDF, TXT, JPG, PNG, or WEBP.');
  }

  Future<StudyTextExtractionResult> _extractImage({required Uint8List bytes, required String fileName, String? path}) async {
    String imagePath = path ?? '';
    File? tempFile;

    if (imagePath.isEmpty) {
      final tempDir = await getTemporaryDirectory();
      final extension = p.extension(fileName).isNotEmpty ? p.extension(fileName) : '.jpg';
      tempFile = File('${tempDir.path}/nurseup_ocr_${DateTime.now().millisecondsSinceEpoch}$extension');
      await tempFile.writeAsBytes(bytes, flush: true);
      imagePath = tempFile.path;
    }

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await recognizer.processImage(inputImage);
      return _validate(recognizedText.text, 'ocr');
    } finally {
      await recognizer.close();
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  StudyTextExtractionResult _extractPdf(Uint8List bytes) {
    try {
      final document = PdfDocument(inputBytes: bytes);
      final text = PdfTextExtractor(document).extractText();
      document.dispose();
      return _validate(text, 'pdf_text');
    } catch (_) {
      throw const StudyTextExtractionException("I couldn't read text from this PDF. If it is scanned, please upload a clearer image or a PDF with selectable text.");
    }
  }

  StudyTextExtractionResult _validate(String rawText, String method) {
    final cleaned = clean(rawText);
    if (cleaned.length < minimumReadableCharacters || cleaned.split(RegExp(r'\s+')).length < 12) {
      throw const StudyTextExtractionException("We couldn't read enough text from this file. Please try a clearer photo or another document.");
    }
    return StudyTextExtractionResult(text: cleaned, method: method);
  }

  String _decodeText(Uint8List bytes) {
    try {
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return latin1.decode(bytes, allowInvalid: true);
    }
  }

  static String clean(String value) {
    return value
        .replaceAll(RegExp(r'https?://\S+'), ' ')
        .replaceAll(RegExp(r'\b[a-zA-Z0-9_-]{18,}\b'), ' ')
        .replaceAll(RegExp(r'[/\\][\w\-. /\\]+'), ' ')
        .replaceAll(RegExp(r'[^\x09\x0A\x0D\x20-\x7EÀ-ÿ]+'), ' ')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  bool _isImage(String extension, String mimeType) {
    return mimeType.startsWith('image/') || const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension);
  }
}

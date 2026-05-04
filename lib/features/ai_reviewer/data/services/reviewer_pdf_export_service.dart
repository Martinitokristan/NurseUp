import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ReviewerPdfData {
  const ReviewerPdfData({
    required this.title,
    required this.summary,
    required this.generatedAt,
    required this.sections,
    required this.practiceQuestions,
    required this.rawContent,
  });

  final String title;
  final String summary;
  final DateTime generatedAt;
  final List<ReviewerPdfSection> sections;
  final List<ReviewerPracticeQuestion> practiceQuestions;
  final String rawContent;

  factory ReviewerPdfData.fromFirestore(Map<String, dynamic> data) {
    final fullContent = data['fullContent'] as String? ?? '';
    final parsed = _tryParseJson(fullContent);
    final title = parsed['title'] as String? ?? data['title'] as String? ?? 'Generated Reviewer';
    final summary = parsed['summary'] as String? ?? data['summary'] as String? ?? fullContent;
    final createdAt = data['createdAt'];
    final generatedAt = createdAt != null && createdAt.toString().contains('Timestamp') ? createdAt.toDate() as DateTime : DateTime.now();
    final keyConcepts = _stringList(parsed['keyConcepts']);
    final importantTerms = _termList(parsed['importantTerms']);
    final stepByStep = _stringList(parsed['stepByStep']);
    final examples = _stringList(parsed['examples']);
    final commonMistakes = _stringList(parsed['commonMistakes']);
    final practiceQuestions = _questionList(parsed['practiceQuestions']);
    final legacyKeyPoints = _stringList(parsed['keyPoints']);
    final legacyConsiderations = _stringList(parsed['nursingConsiderations']);
    final sections = <ReviewerPdfSection>[
      if (keyConcepts.isNotEmpty) ReviewerPdfSection(heading: 'Key Concepts and Explanations', bullets: keyConcepts),
      if (importantTerms.isNotEmpty) ReviewerPdfSection(heading: 'Important Terms and Definitions', bullets: importantTerms),
      if (stepByStep.isNotEmpty) ReviewerPdfSection(heading: 'Step-by-Step Explanation', bullets: stepByStep),
      if (examples.isNotEmpty) ReviewerPdfSection(heading: 'Examples', bullets: examples),
      if (commonMistakes.isNotEmpty) ReviewerPdfSection(heading: 'Common Mistakes and Reminders', bullets: commonMistakes),
      if (legacyKeyPoints.isNotEmpty) ReviewerPdfSection(heading: 'Key Points', bullets: legacyKeyPoints),
      if (legacyConsiderations.isNotEmpty) ReviewerPdfSection(heading: 'Nursing Considerations', bullets: legacyConsiderations),
      if (keyConcepts.isEmpty && legacyKeyPoints.isEmpty && legacyConsiderations.isEmpty) ReviewerPdfSection(heading: 'Reviewer Notes', bullets: _fallbackBullets(fullContent)),
    ];

    return ReviewerPdfData(
      title: title,
      summary: summary,
      generatedAt: generatedAt,
      sections: sections,
      practiceQuestions: practiceQuestions,
      rawContent: fullContent,
    );
  }

  static Map<String, dynamic> _tryParseJson(String value) {
    try {
      final decoded = jsonDecode(value);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static List<String> _stringList(Object? value) {
    if (value is List) return value.map((item) => item.toString()).where((item) => item.trim().isNotEmpty).toList();
    return const [];
  }

  static List<String> _termList(Object? value) {
    if (value is List) {
      return value.map((item) {
        if (item is Map) return '${item['term'] ?? 'Term'}: ${item['definition'] ?? ''}'.trim();
        return item.toString();
      }).where((item) => item.trim().isNotEmpty).toList();
    }
    return const [];
  }

  static List<ReviewerPracticeQuestion> _questionList(Object? value) {
    if (value is List) {
      return value.map((item) {
        if (item is Map) {
          return ReviewerPracticeQuestion(question: item['question']?.toString() ?? '', answer: item['answer']?.toString() ?? '');
        }
        return ReviewerPracticeQuestion(question: item.toString(), answer: '');
      }).where((item) => item.question.trim().isNotEmpty).toList();
    }
    return const [];
  }

  static List<String> _fallbackBullets(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return const ['Generated nursing reviewer content.'];
    return cleaned.split(RegExp(r'\n+')).where((line) => line.trim().isNotEmpty).take(8).toList();
  }
}

class ReviewerPdfSection {
  const ReviewerPdfSection({required this.heading, required this.bullets});

  final String heading;
  final List<String> bullets;
}

class ReviewerPracticeQuestion {
  const ReviewerPracticeQuestion({required this.question, required this.answer});

  final String question;
  final String answer;
}

class ReviewerPdfExportService {
  const ReviewerPdfExportService();

  Future<File> saveToDownloads(ReviewerPdfData reviewer) async {
    final bytes = _buildPdf(reviewer);
    final directory = await _downloadsDirectory();
    final fileName = _safeFileName('${reviewer.title}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf');
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> share(ReviewerPdfData reviewer) async {
    final file = await saveToDownloads(reviewer);
    await Share.shareXFiles([XFile(file.path)], text: '${reviewer.title} - NurseUp reviewer');
  }

  Future<void> open(File file) async {
    await OpenFile.open(file.path);
  }

  Uint8List _buildPdf(ReviewerPdfData reviewer) {
    final document = PdfDocument();
    document.pageSettings.margins.all = 28;
    final page = document.pages.add();
    final graphics = page.graphics;
    final width = page.getClientSize().width;
    final blue = PdfColor(33, 150, 243);
    final black = PdfColor(20, 20, 20);
    final yellow = PdfColor(255, 244, 189);
    final titleFont = PdfStandardFont(PdfFontFamily.helvetica, 22, style: PdfFontStyle.bold);
    final h2Font = PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold);
    final bodyFont = PdfStandardFont(PdfFontFamily.helvetica, 11);
    final italicFont = PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.italic);
    var y = 0.0;

    graphics.drawString('NurseUp', titleFont, brush: PdfSolidBrush(blue), bounds: Rect.fromLTWH(0, y, width, 28));
    y += 28;
    graphics.drawString('AI-Generated Reviewer', h2Font, brush: PdfSolidBrush(black), bounds: Rect.fromLTWH(0, y, width, 22));
    y += 32;
    graphics.drawLine(PdfPen(blue, width: 1.5), Offset(0, y), Offset(width, y));
    y += 16;

    y = _drawText(page, 'Title: ${reviewer.title}', bodyFont, black, y, width);
    y = _drawText(page, 'Generated: ${DateFormat('MMMM d, yyyy').format(reviewer.generatedAt)}', bodyFont, black, y, width);
    y += 10;

    y = _drawHeading(page, 'SUMMARY', h2Font, blue, y, width);
    y = _drawText(page, reviewer.summary, bodyFont, black, y, width);
    y += 10;

    for (var i = 0; i < reviewer.sections.length; i++) {
      final section = reviewer.sections[i];
      y = _drawHeading(page, 'SECTION ${i + 1}: ${section.heading}', h2Font, blue, y, width);
      for (final bullet in section.bullets) {
        y = _drawText(page, '• $bullet', bodyFont, black, y, width);
      }
      y += 10;
    }

    if (reviewer.practiceQuestions.isNotEmpty) {
      y = _drawBox(page, 'PRACTICE QUESTIONS', reviewer.practiceQuestions.map((item) => '${item.question}\nAnswer: ${item.answer}').toList(), h2Font, bodyFont, black, yellow, y, width);
    }

    graphics.drawLine(PdfPen(PdfColor(210, 210, 210)), Offset(0, page.getClientSize().height - 24), Offset(width, page.getClientSize().height - 24));
    graphics.drawString('Generated by NurseUp • nurseup.app', italicFont, brush: PdfSolidBrush(PdfColor(100, 100, 100)), bounds: Rect.fromLTWH(0, page.getClientSize().height - 18, width, 18), format: PdfStringFormat(alignment: PdfTextAlignment.center));

    final bytes = Uint8List.fromList(document.saveSync());
    document.dispose();
    return bytes;
  }

  double _drawHeading(PdfPage page, String text, PdfFont font, PdfColor color, double y, double width) {
    return _drawText(page, text, font, color, y, width) + 4;
  }

  double _drawText(PdfPage page, String text, PdfFont font, PdfColor color, double y, double width) {
    final result = PdfTextElement(text: text, font: font, brush: PdfSolidBrush(color)).draw(page: page, bounds: Rect.fromLTWH(0, y, width, 760 - y), format: PdfLayoutFormat(layoutType: PdfLayoutType.paginate));
    return (result?.bounds.bottom ?? y) + 6;
  }

  double _drawBox(PdfPage page, String title, List<String> bullets, PdfFont titleFont, PdfFont bodyFont, PdfColor color, PdfColor background, double y, double width) {
    page.graphics.drawRectangle(brush: PdfSolidBrush(background), pen: PdfPen(PdfColor(245, 200, 80)), bounds: Rect.fromLTWH(0, y, width, 24 + (bullets.length * 22)));
    var currentY = y + 10;
    currentY = _drawText(page, title, titleFont, color, currentY, width - 16);
    for (final bullet in bullets) {
      currentY = _drawText(page, '• $bullet', bodyFont, color, currentY, width - 16);
    }
    return currentY + 8;
  }

  Future<Directory> _downloadsDirectory() async {
    if (Platform.isAndroid) {
      final downloads = Directory('/storage/emulated/0/Download');
      if (await downloads.exists()) return downloads;
    }
    final downloads = await getDownloadsDirectory();
    return downloads ?? getApplicationDocumentsDirectory();
  }

  String _safeFileName(String value) {
    return value.replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_');
  }
}


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
    required this.overview,
    required this.generatedAt,
    required this.sections,
    required this.keyTerms,
    required this.mustRemember,
    required this.practiceQuestions,
    required this.flashcards,
  });

  final String title;
  final String overview;
  final DateTime generatedAt;
  final List<ReviewerPdfSection> sections;
  final List<ReviewerKeyTerm> keyTerms;
  final List<String> mustRemember;
  final List<ReviewerPracticeQuestion> practiceQuestions;
  final List<ReviewerFlashcard> flashcards;

  factory ReviewerPdfData.fromFirestore(Map<String, dynamic> data) {
    final fullContent = data['fullContent'] as String? ?? '';
    final parsed = _tryParseJson(fullContent);

    final title = data['title'] as String? ?? parsed['title'] as String? ?? 'Study Reviewer';
    final createdAt = data['createdAt'];
    final generatedAt = createdAt != null && createdAt.toString().contains('Timestamp') ? createdAt.toDate() as DateTime : DateTime.now();

    var sections = _parseSections(data['sections'] ?? parsed['sections']);
    if (sections.isEmpty) sections = _legacySections(parsed);
    if (sections.isEmpty) sections = _fallbackSections(fullContent);

    final keyTerms = _parseKeyTerms(data['keyTerms'] ?? parsed['keyTerms'] ?? parsed['importantTerms']);
    final mustRemember = _stringList(data['mustRemember'] ?? parsed['mustRemember']);
    final practiceQuestions = _parseQuestions(data['practiceQuestions'] ?? parsed['practiceQuestions']);
    final flashcards = _parseFlashcards(data['flashcards'] ?? parsed['flashcards']);

    final overview = _resolveOverview(data, parsed, sections);

    return ReviewerPdfData(
      title: title,
      overview: overview,
      generatedAt: generatedAt,
      sections: sections,
      keyTerms: keyTerms,
      mustRemember: mustRemember,
      practiceQuestions: practiceQuestions,
      flashcards: flashcards,
    );
  }

  static String _resolveOverview(
    Map<String, dynamic> data,
    Map<String, dynamic> parsed,
    List<ReviewerPdfSection> sections,
  ) {
    final value = data['overview'] as String? ??
        data['summary'] as String? ??
        parsed['overview'] as String? ??
        parsed['summary'] as String? ??
        '';

    if (value.trim().isNotEmpty && value.trim() != 'Your reviewer is ready.') {
      return value.trim();
    }

    if (sections.isNotEmpty && sections.first.bullets.isNotEmpty) {
      return sections.first.bullets.first;
    }

    return 'Reviewer content is available below.';
  }

  static List<ReviewerPdfSection> _legacySections(Map<String, dynamic> parsed) {
    final sections = <ReviewerPdfSection>[];

    final keyConcepts = _stringList(parsed['keyConcepts']);
    if (keyConcepts.isNotEmpty) {
      sections.add(ReviewerPdfSection(heading: 'Key Concepts', bullets: keyConcepts));
    }

    final importantTerms = _legacyTermList(parsed['importantTerms']);
    if (importantTerms.isNotEmpty) {
      sections.add(ReviewerPdfSection(heading: 'Important Terms', bullets: importantTerms));
    }

    final stepByStep = _stringList(parsed['stepByStep']);
    if (stepByStep.isNotEmpty) {
      sections.add(ReviewerPdfSection(heading: 'Step-by-Step Explanation', bullets: stepByStep));
    }

    final examples = _stringList(parsed['examples']);
    if (examples.isNotEmpty) {
      sections.add(ReviewerPdfSection(heading: 'Examples', bullets: examples));
    }

    final commonMistakes = _stringList(parsed['commonMistakes']);
    if (commonMistakes.isNotEmpty) {
      sections.add(ReviewerPdfSection(heading: 'Common Mistakes and Reminders', bullets: commonMistakes));
    }

    final legacyKeyPoints = _stringList(parsed['keyPoints']);
    if (legacyKeyPoints.isNotEmpty) {
      sections.add(ReviewerPdfSection(heading: 'Key Points', bullets: legacyKeyPoints));
    }

    final legacyConsiderations = _stringList(parsed['nursingConsiderations']);
    if (legacyConsiderations.isNotEmpty) {
      sections.add(ReviewerPdfSection(heading: 'Nursing Considerations', bullets: legacyConsiderations));
    }

    return sections;
  }

  static List<String> _legacyTermList(dynamic value) {
    if (value is! List) return [];
    return value.whereType<Map>().map((item) {
      final term = item['term']?.toString() ?? '';
      final definition = item['definition']?.toString() ?? '';
      return '$term: $definition'.trim();
    }).where((s) => s.isNotEmpty && s != ':').toList();
  }

  static List<ReviewerPdfSection> _fallbackSections(String fullContent) {
    final text = _plainTextFallback(fullContent);
    if (text.isEmpty) return [];

    final lines = text
        .split(RegExp(r'\n+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('{') && !line.startsWith('}'))
        .take(20)
        .toList();

    if (lines.isEmpty) return [];

    return [ReviewerPdfSection(heading: 'Reviewer Notes', bullets: lines)];
  }

  static String _plainTextFallback(String value) {
    final cleaned = _stripJsonFence(value).trim();
    if (cleaned.startsWith('{') && cleaned.endsWith('}')) {
      try {
        jsonDecode(cleaned);
        return '';
      } catch (_) {
        return cleaned;
      }
    }
    return cleaned;
  }

  static String _stripJsonFence(String value) {
    var cleaned = value.trim();

    cleaned = cleaned
        .replaceFirst(RegExp(r'^```json\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^```\s*'), '')
        .replaceFirst(RegExp(r'\s*```$'), '')
        .trim();

    final firstBrace = cleaned.indexOf('{');
    final lastBrace = cleaned.lastIndexOf('}');

    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      cleaned = cleaned.substring(firstBrace, lastBrace + 1).trim();
    }

    return cleaned;
  }

  static Map<String, dynamic> _tryParseJson(String value) {
    try {
      final decoded = jsonDecode(_stripJsonFence(value));
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static List<ReviewerPdfSection> _parseSections(dynamic value) {
    if (value is! List) return [];
    return value.whereType<Map>().map((item) {
      final heading = item['heading']?.toString() ?? '';
      final bullets = _stringList(item['bullets']);
      return ReviewerPdfSection(heading: heading, bullets: bullets);
    }).where((s) => s.heading.isNotEmpty).toList();
  }

  static List<ReviewerKeyTerm> _parseKeyTerms(dynamic value) {
    if (value is! List) return [];
    return value.whereType<Map>().map((item) {
      final term = item['term']?.toString() ?? '';
      final definition = item['definition']?.toString() ?? '';
      return ReviewerKeyTerm(term: term, definition: definition);
    }).where((t) => t.term.isNotEmpty).toList();
  }

  static List<ReviewerPracticeQuestion> _parseQuestions(dynamic value) {
    if (value is! List) return [];
    return value.whereType<Map>().map((item) {
      final question = item['question']?.toString() ?? '';
      final answer = item['answer']?.toString() ?? '';
      return ReviewerPracticeQuestion(question: question, answer: answer);
    }).where((q) => q.question.isNotEmpty).toList();
  }

  static List<ReviewerFlashcard> _parseFlashcards(dynamic value) {
    if (value is! List) return [];
    return value.whereType<Map>().map((item) {
      final front = item['front']?.toString() ?? '';
      final back = item['back']?.toString() ?? '';
      return ReviewerFlashcard(front: front, back: back);
    }).where((c) => c.front.isNotEmpty && c.back.isNotEmpty).toList();
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) return value.map((item) => item.toString()).where((item) => item.trim().isNotEmpty).toList();
    return [];
  }

  bool get hasContent =>
      sections.isNotEmpty ||
      keyTerms.isNotEmpty ||
      mustRemember.isNotEmpty ||
      practiceQuestions.isNotEmpty ||
      flashcards.isNotEmpty;
}


class ReviewerPdfSection {
  const ReviewerPdfSection({required this.heading, required this.bullets});

  final String heading;
  final List<String> bullets;
}

class ReviewerKeyTerm {
  const ReviewerKeyTerm({required this.term, required this.definition});

  final String term;
  final String definition;
}

class ReviewerPracticeQuestion {
  const ReviewerPracticeQuestion({required this.question, required this.answer});

  final String question;
  final String answer;
}

class ReviewerFlashcard {
  const ReviewerFlashcard({required this.front, required this.back});

  final String front;
  final String back;
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
    await Share.shareXFiles([XFile(file.path)], text: reviewer.title);
  }

  Future<void> open(File file) async {
    await OpenFile.open(file.path);
  }

  Uint8List _buildPdf(ReviewerPdfData reviewer) {
    if (!reviewer.hasContent) {
      throw StateError('No reviewer content available to export.');
    }

    final document = PdfDocument();
    document.pageSettings.margins.all = 36;
    final page = document.pages.add();
    final graphics = page.graphics;
    final width = page.getClientSize().width;
    final black = PdfColor(20, 20, 20);
    final gray = PdfColor(100, 100, 100);
    final lightGray = PdfColor(220, 220, 220);
    final titleFont = PdfStandardFont(PdfFontFamily.helvetica, 24, style: PdfFontStyle.bold);
    final h1Font = PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold);
    final bodyFont = PdfStandardFont(PdfFontFamily.helvetica, 11);
    final smallFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
    var y = 0.0;

    graphics.drawString(reviewer.title, titleFont, brush: PdfSolidBrush(black), bounds: Rect.fromLTWH(0, y, width, 32));
    y += 36;
    graphics.drawString(DateFormat('MMMM d, yyyy').format(reviewer.generatedAt), smallFont, brush: PdfSolidBrush(gray), bounds: Rect.fromLTWH(0, y, width, 18));
    y += 24;
    graphics.drawLine(PdfPen(lightGray), Offset(0, y), Offset(width, y));
    y += 20;

    if (reviewer.overview.isNotEmpty) {
      y = _drawText(page, reviewer.overview, bodyFont, black, y, width);
      y += 16;
    }

    for (final section in reviewer.sections) {
      y = _drawHeading(page, section.heading, h1Font, black, y, width);
      for (final bullet in section.bullets) {
        y = _drawBullet(page, bullet, bodyFont, black, y, width);
      }
      y += 12;
    }

    if (reviewer.keyTerms.isNotEmpty) {
      y = _drawHeading(page, 'Key Terms', h1Font, black, y, width);
      for (final term in reviewer.keyTerms) {
        y = _drawBullet(page, '${term.term}: ${term.definition}', bodyFont, black, y, width);
      }
      y += 12;
    }

    if (reviewer.mustRemember.isNotEmpty) {
      y = _drawHeading(page, 'Must Remember', h1Font, black, y, width);
      for (final item in reviewer.mustRemember) {
        y = _drawBullet(page, item, bodyFont, black, y, width);
      }
      y += 12;
    }

    if (reviewer.practiceQuestions.isNotEmpty) {
      y = _drawHeading(page, 'Practice Questions', h1Font, black, y, width);
      var qNum = 1;
      for (final q in reviewer.practiceQuestions) {
        y = _drawText(page, '$qNum. ${q.question}', bodyFont, black, y, width);
        y = _drawText(page, '   Answer: ${q.answer}', smallFont, gray, y, width);
        y += 8;
        qNum++;
      }
      y += 12;
    }

    if (reviewer.flashcards.isNotEmpty) {
      y = _drawHeading(page, 'Flashcards', h1Font, black, y, width);
      for (final card in reviewer.flashcards.take(20)) {
        y = _drawText(page, 'Front: ${card.front}', bodyFont, black, y, width);
        y = _drawText(page, 'Back: ${card.back}', smallFont, gray, y, width);
        y += 10;
      }
    }

    final bytes = Uint8List.fromList(document.saveSync());
    document.dispose();
    return bytes;
  }

  double _drawHeading(PdfPage page, String text, PdfFont font, PdfColor color, double y, double width) {
    return _drawText(page, text, font, color, y, width) + 6;
  }

  double _drawText(PdfPage page, String text, PdfFont font, PdfColor color, double y, double width) {
    final result = PdfTextElement(text: text, font: font, brush: PdfSolidBrush(color)).draw(page: page, bounds: Rect.fromLTWH(0, y, width, 800 - y), format: PdfLayoutFormat(layoutType: PdfLayoutType.paginate));
    return (result?.bounds.bottom ?? y) + 6;
  }

  double _drawBullet(PdfPage page, String text, PdfFont font, PdfColor color, double y, double width) {
    return _drawText(page, '• $text', font, color, y, width);
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


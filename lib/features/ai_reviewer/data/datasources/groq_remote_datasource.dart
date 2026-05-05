import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../../file_manager/data/services/study_text_extraction_service.dart';

class GroqRemoteDatasource {
  const GroqRemoteDatasource();

  static const String endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const String model = 'llama-3.3-70b-versatile';

  Future<String> generateReviewer(String extractedText, String fileName) async {
    final groqApiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    if (groqApiKey.isEmpty) throw const GroqReviewerException('invalid_key');
    final cleanText = StudyTextExtractionService.clean(extractedText);
    if (cleanText.length < StudyTextExtractionService.minimumReadableCharacters) {
      throw const GroqReviewerException('empty_content');
    }

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await http
            .post(
              Uri.parse(endpoint),
              headers: {
                'Authorization': 'Bearer $groqApiKey',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'model': model,
                'messages': [
                  {
                    'role': 'system',
                    'content':
                        'You are an expert academic reviewer writer for nursing and healthcare students. Create a clean, modern, student-friendly reviewer from the provided study material. Do not mention file IDs, filenames, upload paths, OCR issues, JSON, AI, logs, API data, or technical metadata. Do not invent facts unsupported by the source. Organize the output as practical reviewer content with short headings, concise bullet points, key terms, must-remember notes, practice questions, and flashcards. Always return valid JSON only using the exact schema requested.',
                  },
                  {
                    'role': 'user',
                    'content': _buildPrompt(cleanText),
                  },
                ],
                'max_tokens': 4096,
                'temperature': 0.25,
              }),
            )
            .timeout(const Duration(seconds: 45));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final content = data['choices'][0]['message']['content'] as String;
          return _stripJsonFence(content);
        }
        if (response.statusCode == 401 || response.statusCode == 403) throw const GroqReviewerException('invalid_key');
        if (response.statusCode == 429) {
          final retryAfter = response.headers['retry-after'];
          throw GroqReviewerException('rate_limit:${retryAfter ?? ''}');
        }
        if (response.statusCode >= 500 && attempt == 0) continue;
        throw const GroqReviewerException('service_unavailable');
      } on SocketException {
        throw const GroqReviewerException('network');
      } on GroqReviewerException {
        rethrow;
      } catch (_) {
        if (attempt == 0) continue;
        throw const GroqReviewerException('service_unavailable');
      }
    }
    throw const GroqReviewerException('service_unavailable');
  }

  String _buildPrompt(String cleanExtractedText) {
    return '''Create a clean, modern student reviewer from the source material below. Make it useful for studying with natural headings, bullet points, and concise explanations. If the source includes noise, ignore technical noise and focus only on educational content. Return valid JSON only.

Source material:
$cleanExtractedText

Important requirements:
- "sections" must contain at least 3 sections when enough source text exists (at least 300 characters).
- Each section must contain at least 3 bullet points.
- "overview" must not be generic. Do not write only "Your reviewer is ready." or similar placeholder text.
- If the source is not educational content, explain what was found in one reviewer section instead of returning empty arrays.
- Return JSON only. No markdown fences. No explanation text outside the JSON.

Return this exact JSON schema:
{
  "title": "Clear reviewer title",
  "overview": "Short plain-language overview",
  "sections": [
    {"heading": "Main topic heading", "bullets": ["Clear bullet point explanation", "Another reviewer-style bullet point"]}
  ],
  "keyTerms": [
    {"term": "Important term", "definition": "Simple definition"}
  ],
  "mustRemember": ["High-yield fact students should remember"],
  "practiceQuestions": [
    {"question": "Question text", "answer": "Answer text"}
  ],
  "flashcards": [
    {"front": "Question or term", "back": "Answer or explanation"}
  ]
}''';
  }

  String _stripJsonFence(String value) {
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
}

class GroqReviewerException implements Exception {
  const GroqReviewerException(this.code);

  final String code;

  @override
  String toString() => code;
}

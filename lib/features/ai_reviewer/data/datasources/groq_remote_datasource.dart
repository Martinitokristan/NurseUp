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
                        'You are an expert academic reviewer creator for students. Create a formal, accurate, easy-to-understand study reviewer from the provided learning material. Do not mention file IDs, filenames, upload paths, OCR issues, or technical metadata. If the source text is messy, infer the educational topic carefully but do not invent facts not supported by the text. Organize the reviewer with clear headings, bullet points, definitions, key concepts, examples, summary, and practice questions with answers. Always respond with valid JSON only.',
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
          return data['choices'][0]['message']['content'] as String;
        }
        if (response.statusCode == 401 || response.statusCode == 403) throw const GroqReviewerException('invalid_key');
        if (response.statusCode == 429) throw const GroqReviewerException('rate_limit');
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
    return '''Create a high-quality student reviewer from this extracted material. Format it professionally. Include:
1. Title
2. Short overview
3. Key concepts and explanations
4. Important terms and definitions
5. Step-by-step explanations if the topic involves processes or calculations
6. Examples when useful
7. Common mistakes or reminders
8. Summary
9. 10 practice questions with answer key

Source material:
$cleanExtractedText

Respond with valid JSON in this exact format:
{
  "title": "Descriptive title for the reviewer",
  "summary": "Short overview of the source material",
  "keyConcepts": ["concept with clear explanation"],
  "importantTerms": [{"term":"term", "definition":"definition"}],
  "stepByStep": ["step explanation when applicable"],
  "examples": ["example when useful"],
  "commonMistakes": ["common mistake or reminder"],
  "finalSummary": "Concise study summary",
  "practiceQuestions": [{"question":"question", "answer":"answer"}]
}''';
  }
}

class GroqReviewerException implements Exception {
  const GroqReviewerException(this.code);

  final String code;

  @override
  String toString() => code;
}

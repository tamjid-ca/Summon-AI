import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:summon_ai/model/chat_model.dart';

class GeminiChatService {
  GeminiChatService({String? apiKey})
      : _apiKey = apiKey ??
            dotenv.env['GEMINI_API_KEY'] ??
            dotenv.env['VITE_GEMINI_API_KEY'] ??
            '';

  final String _apiKey;

  GenerativeModel get _model {
    if (_apiKey.trim().isEmpty) {
      throw Exception('Missing GEMINI_API_KEY in .env.');
    }
    return GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
    );
  }

  Future<String> sendMessage({
    required List<ChatMessage> history,
    required String prompt,
    Uint8List? imageBytes,
    String? imageMimeType,
  }) async {
    final recentHistory =
        history.length > 20 ? history.sublist(history.length - 20) : history;
    final contents = <Content>[
      Content.text(
        'You are a helpful AI assistant inside the Summon AI class app. '
        'Answer clearly and keep explanations student-friendly.',
      ),
      ...recentHistory.map(_messageToContent),
    ];

    final parts = <Part>[];
    final trimmedPrompt = prompt.trim();
    if (trimmedPrompt.isNotEmpty) {
      parts.add(TextPart(trimmedPrompt));
    }
    if (imageBytes != null && imageMimeType != null) {
      parts.add(DataPart(imageMimeType, imageBytes));
    }
    if (parts.isEmpty) {
      parts.add(TextPart('Describe this image.'));
    }

    contents.add(Content('user', parts));

    final response = await _model.generateContent(contents);
    return response.text?.trim().isNotEmpty == true
        ? response.text!.trim()
        : 'Gemini did not return a text response.';
  }

  Content _messageToContent(ChatMessage message) {
    final text = message.text.trim().isEmpty ? '(image only)' : message.text;
    return Content(
      message.role == ChatMessageRole.model ? 'model' : 'user',
      [TextPart(text)],
    );
  }
}

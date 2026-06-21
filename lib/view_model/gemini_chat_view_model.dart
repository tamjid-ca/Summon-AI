import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:summon_ai/model/chat_message.dart';

class GeminiChatViewModel extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;

  GenerativeModel? _model;
  ChatSession? _chatSession;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  GenerativeModel get model {
    _model ??= GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: dotenv.env['GEMINI_API_KEY'] ?? const String.fromEnvironment('GEMINI_API_KEY'),
    );
    return _model!;
  }

  ChatSession get chatSession {
    _chatSession ??= model.startChat();
    return _chatSession!;
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage.user(text);
    _messages.add(userMessage);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await chatSession.sendMessage(Content.text(text));
      final replyText = response.text ?? 'No response from Gemini';
      
      _messages.add(ChatMessage.ai(replyText));
    } catch (e) {
      _errorMessage = 'Gemini Chat Error: $e';
      // If we encounter a critical error, reset the chat session so it can re-initialize next time.
      _chatSession = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearChat() {
    _messages.clear();
    _chatSession = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}

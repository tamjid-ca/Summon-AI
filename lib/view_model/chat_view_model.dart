import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:summon_ai/model/chat_model.dart';
import 'package:summon_ai/service/chat_session_service.dart';
import 'package:summon_ai/service/gemini_chat_service.dart';

class ChatViewModel extends ChangeNotifier {
  ChatViewModel({
    ChatSessionService? chatSessionService,
    GeminiChatService? geminiChatService,
  })  : _chatSessionService = chatSessionService ?? ChatSessionService(),
        _geminiChatService = geminiChatService ?? GeminiChatService();

  static const int maxImageBytes = 2 * 1024 * 1024;

  final ChatSessionService _chatSessionService;
  final GeminiChatService _geminiChatService;

  StreamSubscription<List<ChatSession>>? _sessionsSubscription;
  StreamSubscription<List<ChatMessage>>? _messagesSubscription;

  final List<ChatSession> sessions = [];
  final List<ChatMessage> messages = [];

  String? selectedSessionId;
  bool isLoadingSessions = true;
  bool isSending = false;
  String? errorMessage;

  void start() {
    _sessionsSubscription?.cancel();
    isLoadingSessions = true;
    _sessionsSubscription = _chatSessionService.watchSessions().listen(
      (items) async {
        sessions
          ..clear()
          ..addAll(items);
        isLoadingSessions = false;
        if (selectedSessionId == null && sessions.isNotEmpty) {
          await selectSession(sessions.first.id);
        } else if (selectedSessionId != null &&
            sessions.every((session) => session.id != selectedSessionId)) {
          selectedSessionId = null;
          messages.clear();
        }
        notifyListeners();
      },
      onError: (Object error) {
        isLoadingSessions = false;
        errorMessage = 'Could not load chat sessions: $error';
        notifyListeners();
      },
    );
  }

  Future<void> createNewChat() async {
    errorMessage = null;
    final id = await _chatSessionService.createSession();
    await selectSession(id);
  }

  Future<void> selectSession(String sessionId) async {
    selectedSessionId = sessionId;
    messages.clear();
    await _messagesSubscription?.cancel();
    _messagesSubscription = _chatSessionService.watchMessages(sessionId).listen(
      (items) {
        messages
          ..clear()
          ..addAll(items);
        notifyListeners();
      },
      onError: (Object error) {
        errorMessage = 'Could not load messages: $error';
        notifyListeners();
      },
    );
    notifyListeners();
  }

  Future<void> renameSession(String sessionId, String title) async {
    await _chatSessionService.renameSession(sessionId, title);
  }

  Future<void> deleteSession(String sessionId) async {
    await _chatSessionService.deleteSession(sessionId);
    if (selectedSessionId == sessionId) {
      selectedSessionId = null;
      messages.clear();
      await _messagesSubscription?.cancel();
      notifyListeners();
    }
  }

  Future<void> sendMessage(String prompt, PendingChatImage? image) async {
    if (prompt.trim().isEmpty && image == null) return;
    if (image != null && image.sizeBytes > maxImageBytes) {
      errorMessage = 'Image must be 2 MB or smaller.';
      notifyListeners();
      return;
    }

    isSending = true;
    errorMessage = null;
    notifyListeners();

    try {
      final sessionId = selectedSessionId ??
          await _chatSessionService.createSession(title: _titleFrom(prompt));
      if (selectedSessionId == null) {
        await selectSession(sessionId);
      }

      ChatImageAttachment? attachment;
      Uint8List? imageBytes;
      String? imageBase64;
      if (image != null) {
        imageBase64 = base64Encode(image.bytes);
        attachment = ChatImageAttachment(
          fileName: image.fileName,
          mimeType: image.mimeType,
          sizeBytes: image.sizeBytes,
          base64ChunkCount: _chatSessionService.base64ChunkCount(imageBase64),
        );
        imageBytes = base64Decode(imageBase64);
      }

      final history = List<ChatMessage>.from(messages);
      final userMessageRef = await _chatSessionService.addMessage(
        sessionId,
        ChatMessage(
          id: '',
          role: ChatMessageRole.user,
          text: prompt.trim(),
          attachment: attachment,
          createdAt: DateTime.now(),
        ),
      );
      if (imageBase64 != null && attachment != null) {
        await _chatSessionService.saveImageBase64Chunks(
          sessionId: sessionId,
          messageId: userMessageRef.id,
          base64Data: imageBase64,
        );
      }

      final reply = await _geminiChatService.sendMessage(
        history: history,
        prompt: prompt,
        imageBytes: imageBytes,
        imageMimeType: image?.mimeType,
      );

      await _chatSessionService.addMessage(
        sessionId,
        ChatMessage(
          id: '',
          role: ChatMessageRole.model,
          text: reply,
          createdAt: DateTime.now(),
        ),
      );

      String? currentTitle;
      for (final session in sessions) {
        if (session.id == sessionId) {
          currentTitle = session.title;
          break;
        }
      }
      if (currentTitle == null || currentTitle == 'New chat') {
        await _chatSessionService.renameSession(
          sessionId,
          _titleFrom(prompt, hasImage: image != null),
        );
      }
    } catch (e) {
      errorMessage = 'Chat failed: ${_friendlyFirebaseError(e)}';
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  Future<Uint8List?> imageBytesFor(ChatMessage message) async {
    final attachment = message.attachment;
    final sessionId = selectedSessionId;
    if (attachment == null || sessionId == null) return null;
    final inlineBase64 = attachment.base64Data;
    final base64Data = inlineBase64 != null && inlineBase64.isNotEmpty
        ? inlineBase64
        : await _chatSessionService.loadImageBase64(
            sessionId: sessionId,
            messageId: message.id,
          );
    if (base64Data.isEmpty) return null;
    return base64Decode(base64Data);
  }

  String _titleFrom(String prompt, {bool hasImage = false}) {
    final text = prompt.trim();
    if (text.isEmpty) return hasImage ? 'Image chat' : 'New chat';
    return text.length <= 42 ? text : '${text.substring(0, 42)}...';
  }

  String _friendlyFirebaseError(Object error) {
    if (error is FirebaseException) {

      return '${error.plugin}/${error.code}: ${error.message ?? error}';
    }
    return error.toString();
  }

  @override
  void dispose() {
    _sessionsSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }
}


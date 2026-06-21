import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:summon_ai/firebase_options.dart';
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
      Object? imageStorageError;
      if (image != null) {
        imageBytes = Uint8List.fromList(image.bytes);
        try {
          attachment = await _chatSessionService.uploadImage(
            sessionId: sessionId,
            fileName: image.fileName,
            mimeType: image.mimeType,
            bytes: imageBytes,
          );
        } catch (error) {
          imageStorageError = error;
        }
      }

      final history = List<ChatMessage>.from(messages);
      await _chatSessionService.addMessage(
        sessionId,
        ChatMessage(
          id: '',
          role: ChatMessageRole.user,
          text: prompt.trim(),
          attachment: attachment,
          createdAt: DateTime.now(),
        ),
      );

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

      if (imageStorageError != null) {
        errorMessage =
            'Gemini replied, but the image was not saved in Firebase Storage. '
            '${_friendlyFirebaseError(imageStorageError)}';
      }
    } catch (e) {
      errorMessage = 'Chat failed: ${_friendlyFirebaseError(e)}';
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  String _titleFrom(String prompt, {bool hasImage = false}) {
    final text = prompt.trim();
    if (text.isEmpty) return hasImage ? 'Image chat' : 'New chat';
    return text.length <= 42 ? text : '${text.substring(0, 42)}...';
  }

  String _friendlyFirebaseError(Object error) {
    if (error is FirebaseException) {
      if (error.plugin == 'firebase_storage' ||
          error.plugin == 'firebase_storage_web') {
        if (error.code == 'object-not-found') {
          final bucket =
              'gs://${DefaultFirebaseOptions.currentPlatform.storageBucket}';
          return 'Firebase Storage could not find the uploaded object. '
              'Enable Firebase Storage for bucket "$bucket", then deploy '
              'storage.rules for the same Firebase project.';
        }
        if (error.code == 'unauthorized' || error.code == 'permission-denied') {
          return 'Firebase Storage rejected the upload. Sign in again and '
              'deploy the storage rules.';
        }
        if (error.code == 'bucket-not-found') {
          return 'Firebase Storage bucket was not found. Open Firebase '
              'Console > Storage and create the default bucket.';
        }
      }
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

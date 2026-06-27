import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatMessageRole {
  user,
  model,
}

class ChatImageAttachment {
  const ChatImageAttachment({
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    this.base64Data,
    this.base64ChunkCount = 0,
  });

  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final String? base64Data;
  final int base64ChunkCount;

  factory ChatImageAttachment.fromMap(Map<String, dynamic> map) {
    return ChatImageAttachment(
      fileName: map['fileName'] as String? ?? 'image',
      mimeType: map['mimeType'] as String? ?? 'image/jpeg',
      sizeBytes: map['sizeBytes'] as int? ?? 0,
      base64Data: map['base64Data'] as String?,
      base64ChunkCount: map['base64ChunkCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      if (base64Data != null) 'base64Data': base64Data,
      if (base64ChunkCount > 0) 'base64ChunkCount': base64ChunkCount,
    };
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.attachment,
    this.createdAt,
  });

  final String id;
  final ChatMessageRole role;
  final String text;
  final ChatImageAttachment? attachment;
  final DateTime? createdAt;

  factory ChatMessage.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final attachmentMap = data['attachment'];
    final timestamp = data['createdAt'];
    return ChatMessage(
      id: doc.id,
      role: (data['role'] as String?) == 'model'
          ? ChatMessageRole.model
          : ChatMessageRole.user,
      text: data['text'] as String? ?? '',
      attachment: attachmentMap is Map<String, dynamic>
          ? ChatImageAttachment.fromMap(attachmentMap)
          : null,
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role == ChatMessageRole.model ? 'model' : 'user',
      'text': text,
      if (attachment != null) 'attachment': attachment!.toMap(),
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}

class ChatSession {
  const ChatSession({
    required this.id,
    required this.title,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ChatSession.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final createdAt = data['createdAt'];
    final updatedAt = data['updatedAt'];
    return ChatSession(
      id: doc.id,
      title: data['title'] as String? ?? 'New chat',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : null,
    );
  }
}

class PendingChatImage {
  const PendingChatImage({
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.bytes,
  });

  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final List<int> bytes;
}


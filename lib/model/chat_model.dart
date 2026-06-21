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
    required this.storagePath,
    required this.downloadUrl,
  });

  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final String storagePath;
  final String downloadUrl;

  factory ChatImageAttachment.fromMap(Map<String, dynamic> map) {
    return ChatImageAttachment(
      fileName: map['fileName'] as String? ?? 'image',
      mimeType: map['mimeType'] as String? ?? 'image/jpeg',
      sizeBytes: map['sizeBytes'] as int? ?? 0,
      storagePath: map['storagePath'] as String? ?? '',
      downloadUrl: map['downloadUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
      'storagePath': storagePath,
      'downloadUrl': downloadUrl,
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
    required this.base64Data,
  });

  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final List<int> bytes;
  final String base64Data;
}

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:summon_ai/firebase_options.dart';
import 'package:summon_ai/model/chat_model.dart';

class ChatSessionService {
  ChatSessionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _storage = storage ??
            FirebaseStorage.instanceFor(
              bucket:
                  'gs://${DefaultFirebaseOptions.currentPlatform.storageBucket}',
            );

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final FirebaseStorage _storage;

  String get _uid {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) {
      throw Exception('You must be signed in to use chat.');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _sessions {
    return _firestore.collection('users').doc(_uid).collection('chatSessions');
  }

  CollectionReference<Map<String, dynamic>> _messages(String sessionId) {
    return _sessions.doc(sessionId).collection('messages');
  }

  Stream<List<ChatSession>> watchSessions() {
    return _sessions.orderBy('updatedAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map(ChatSession.fromDoc).toList(),
        );
  }

  Stream<List<ChatMessage>> watchMessages(String sessionId) {
    return _messages(sessionId).orderBy('createdAt').snapshots().map(
          (snapshot) => snapshot.docs.map(ChatMessage.fromDoc).toList(),
        );
  }

  Future<String> createSession({String title = 'New chat'}) async {
    final doc = await _sessions.add({
      'title': title,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> renameSession(String sessionId, String title) async {
    await _sessions.doc(sessionId).set({
      'title': title.trim().isEmpty ? 'New chat' : title.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteSession(String sessionId) async {
    final messages = await _messages(sessionId).limit(100).get();
    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_sessions.doc(sessionId));
    await batch.commit();
  }

  Future<void> addMessage(String sessionId, ChatMessage message) async {
    await _messages(sessionId).add(message.toMap());
    await _sessions.doc(sessionId).set({
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<ChatImageAttachment> uploadImage({
    required String sessionId,
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path =
        'users/$_uid/chatSessions/$sessionId/images/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final ref = _storage.ref(path);
    final snapshot = await ref.putData(
      bytes,
      SettableMetadata(
        contentType: mimeType,
        customMetadata: {
          'ownerUid': _uid,
          'sessionId': sessionId,
        },
      ),
    );
    if (snapshot.state != TaskState.success) {
      throw FirebaseException(
        plugin: 'firebase_storage',
        code: 'upload-incomplete',
        message: 'Image upload did not finish successfully.',
      );
    }

    final downloadUrl = await snapshot.ref.getDownloadURL();
    return ChatImageAttachment(
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: bytes.length,
      storagePath: path,
      downloadUrl: downloadUrl,
    );
  }
}

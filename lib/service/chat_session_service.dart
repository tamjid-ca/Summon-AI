import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:summon_ai/model/chat_model.dart';

class ChatSessionService {
  ChatSessionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  static const int base64ChunkSize = 700000;

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
      final chunks = await doc.reference.collection('imageBase64Chunks').get();
      for (final chunk in chunks.docs) {
        batch.delete(chunk.reference);
      }
      batch.delete(doc.reference);
    }
    batch.delete(_sessions.doc(sessionId));
    await batch.commit();
  }

  Future<DocumentReference<Map<String, dynamic>>> addMessage(
    String sessionId,
    ChatMessage message,
  ) async {
    final doc = await _messages(sessionId).add(message.toMap());
    await _sessions.doc(sessionId).set({
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return doc;
  }

  Future<void> saveImageBase64Chunks({
    required String sessionId,
    required String messageId,
    required String base64Data,
  }) async {
    final chunks = _splitBase64(base64Data);
    final batch = _firestore.batch();
    final collection = _messages(sessionId).doc(messageId).collection(
          'imageBase64Chunks',
        );
    for (var index = 0; index < chunks.length; index++) {
      batch.set(collection.doc(index.toString().padLeft(4, '0')), {
        'index': index,
        'data': chunks[index],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<String> loadImageBase64({
    required String sessionId,
    required String messageId,
  }) async {
    final snapshot = await _messages(sessionId)
        .doc(messageId)
        .collection('imageBase64Chunks')
        .orderBy('index')
        .get();
    return snapshot.docs.map((doc) => doc.data()['data'] as String? ?? '').join();
  }

  int base64ChunkCount(String base64Data) {
    return _splitBase64(base64Data).length;
  }

  List<String> _splitBase64(String base64Data) {
    final chunks = <String>[];
    for (var start = 0; start < base64Data.length; start += base64ChunkSize) {
      final end = (start + base64ChunkSize).clamp(0, base64Data.length) as int;
      chunks.add(base64Data.substring(start, end));
    }
    return chunks;
  }

  Future<void> updateMessageAttachment({
    required String sessionId,
    required String messageId,
    required ChatImageAttachment attachment,
  }) async {
    await _messages(sessionId).doc(messageId).set(
      {'attachment': attachment.toMap()},
      SetOptions(merge: true),
    );
  }
}

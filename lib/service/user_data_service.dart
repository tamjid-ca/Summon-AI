import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:summon_ai/model/ai_model.dart';
import 'package:summon_ai/model/weather_model.dart';

class UserDataService {
  UserDataService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  String? get _uid => _firebaseAuth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _jokesCollection {
    final uid = _uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('jokes');
  }

  CollectionReference<Map<String, dynamic>>? get _weatherCollection {
    final uid = _uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('weatherSearches');
  }

  Future<void> saveUserProfile(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'displayName': user.displayName,
      'email': user.email,
      'photoURL': user.photoURL,
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<AIResponseModel>> loadJokes() async {
    final collection = _jokesCollection;
    if (collection == null) return [];

    final snapshot = await collection.orderBy('createdAt', descending: true).limit(20).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      final timestamp = data['createdAt'];
      return AIResponseModel.fromMap({
        ...data,
        'createdAt': timestamp is Timestamp ? timestamp.toDate() : null,
      });
    }).toList();
  }

  Future<void> saveJoke(AIResponseModel joke) async {
    final collection = _jokesCollection;
    if (collection == null) return;

    await collection.add({
      ...joke.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> clearJokes() async {
    await _deleteCollection(_jokesCollection);
  }

  Future<List<WeatherModel>> loadWeatherSearches() async {
    final collection = _weatherCollection;
    if (collection == null) return [];

    final snapshot = await collection.orderBy('createdAt', descending: true).limit(10).get();
    return snapshot.docs.map((doc) => WeatherModel.fromJson(doc.data())).toList();
  }

  Future<void> saveWeatherSearch(WeatherModel weather) async {
    final collection = _weatherCollection;
    if (collection == null) return;

    await collection.add({
      ...weather.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> clearWeatherSearches() async {
    await _deleteCollection(_weatherCollection);
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>>? collection,
  ) async {
    if (collection == null) return;

    final snapshot = await collection.limit(50).get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

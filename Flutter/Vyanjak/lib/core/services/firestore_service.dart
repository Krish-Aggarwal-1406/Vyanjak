import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();

  String? get _uid => _auth.uid;



  Future<void> saveBridgeSession(Map<String, dynamic> session) async {
    if (_uid == null) return;
    await _db
        .collection('users')
        .doc(_uid)
        .collection('bridge_sessions')
        .add({
      ...session,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getBridgeSessions() async {
    if (_uid == null) return [];
    final snap = await _db
        .collection('users')
        .doc(_uid)
        .collection('bridge_sessions')
        .orderBy('timestamp', descending: true)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }



  Future<void> savePracticeSession(Map<String, dynamic> session) async {
    if (_uid == null) return;
    await _db
        .collection('users')
        .doc(_uid)
        .collection('practice_sessions')
        .add({
      ...session,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getPracticeSessions() async {
    if (_uid == null) return [];
    final snap = await _db
        .collection('users')
        .doc(_uid)
        .collection('practice_sessions')
        .orderBy('timestamp', descending: true)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }



  Future<void> updateStruggleWords(
      List<Map<String, dynamic>> results) async {
    if (_uid == null) return;
    final ref = _db.collection('users').doc(_uid).collection('struggle_words');

    for (final r in results) {
      final word = (r['word'] ?? '').toString().toLowerCase();
      if (word.isEmpty) continue;
      final docRef = ref.doc(word);
      final snap = await docRef.get();

      if (!snap.exists) {
        await docRef.set({'word': word, 'attempts': 1,
          'failures': r['correct'] == false ? 1 : 0});
      } else {
        final data = snap.data()!;
        await docRef.update({
          'attempts': (data['attempts'] ?? 0) + 1,
          'failures': (data['failures'] ?? 0) +
              (r['correct'] == false ? 1 : 0),
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> getStruggleWords() async {
    if (_uid == null) return [];
    final snap = await _db
        .collection('users')
        .doc(_uid)
        .collection('struggle_words')
        .get();

    final list = snap.docs.map((d) {
      final data = d.data();
      final attempts = (data['attempts'] ?? 1) as int;
      final failures = (data['failures'] ?? 0) as int;
      return {
        ...data,
        'fail_rate': failures / attempts,
      };
    }).toList();

    list.sort((a, b) =>
        (b['fail_rate'] as double).compareTo(a['fail_rate'] as double));
    return list;
  }



  Future<Map<String, dynamic>?> getUserProfile() async {
    if (_uid == null) return null;
    final snap = await _db.collection('users').doc(_uid).get();
    return snap.data();
  }
}
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> login(String identifier, String password) async {
    String email = identifier;
    if (!identifier.contains('@')) {
      String phone = identifier.replaceAll(RegExp(r'\D'), '');
      if (phone.startsWith('07') && phone.length == 10) {
        phone = '+256${phone.substring(1)}';
      }
      final snap = await _db.collection('users')
          .where('phoneNumber', isEqualTo: phone).limit(1).get();
      if (snap.docs.isEmpty) throw Exception('account_not_found');
      email = snap.docs.first.data()['email'];
    }
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    _updateOnlineStatus(true);
  }

  Future<void> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    String formattedPhone = phone;
    if (phone.startsWith('0')) formattedPhone = '+256${phone.substring(1)}';

    final phoneSnap = await _db.collection('users')
        .where('phoneNumber', isEqualTo: formattedPhone).limit(1).get();
    if (phoneSnap.docs.isNotEmpty) throw Exception('phone_taken');

    final emailSnap = await _db.collection('users')
        .where('email', isEqualTo: email).limit(1).get();
    if (emailSnap.docs.isNotEmpty) throw Exception('email_taken');

    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await cred.user!.updateDisplayName(name);

    await _db.collection('users').doc(cred.user!.uid).set({
      'uid': cred.user!.uid,
      'displayName': name,
      'email': email,
      'phoneNumber': formattedPhone,
      'photoURL': '',
      'about': 'Hey I use FLUX',
      'isOnline': true,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> signOut() async {
    _updateOnlineStatus(false);
    await _auth.signOut();
  }

  void _updateOnlineStatus(bool online) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    _db.collection('users').doc(uid).update({
      'isOnline': online,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
    }).catchError((_) {});
  }
}
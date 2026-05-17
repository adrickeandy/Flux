import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login with email or phone
  Future<void> login(String identifier, String password) async {
    String email = identifier;

    if (!identifier.contains('@')) {
      // It's a phone — look up email from Firestore
      String phone = identifier;
      if (phone.startsWith('07') && phone.length == 10) {
        phone = '+256${phone.substring(1)}';
      }
      final snap = await _db.collection('users')
          .where('phoneNumber', isEqualTo: phone)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) throw Exception('account_not_found');
      email = snap.docs.first.data()['email'];
    }

    await _auth.signInWithEmailAndPassword(email: email, password: password);
    _updateOnlineStatus(true);
  }

  // Sign up
  Future<void> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    // Format Uganda phone
    String formattedPhone = phone;
    if (phone.startsWith('0')) formattedPhone = '+256${phone.substring(1)}';

    // Check phone not taken
    final phoneSnap = await _db.collection('users')
        .where('phoneNumber', isEqualTo: formattedPhone)
        .limit(1)
        .get();
    if (phoneSnap.docs.isNotEmpty) throw Exception('phone_taken');

    // Check email not taken
    final emailSnap = await _db.collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (emailSnap.docs.isNotEmpty) throw Exception('email_taken');

    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await cred.user!.updateDisplayName(name);

    await _db.collection('users').doc(cred.user!.uid).set({
      'uid': cred.user!.uid,
      'displayName': name,
      'email': email,
      'phoneNumber': formattedPhone,
      'about': 'Hey there! I am using FLUX.',
      'photoURL': null,
      'isOnline': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Sign out
  Future<void> signOut() async {
    _updateOnlineStatus(false);
    await _auth.signOut();
    notifyListeners();
  }

  void _updateOnlineStatus(bool online) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    _db.collection('users').doc(uid).update({
      'isOnline': online,
      'lastSeen': FieldValue.serverTimestamp(),
    }).catchError((_) {});
  }
}
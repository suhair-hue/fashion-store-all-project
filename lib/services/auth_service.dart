import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Register ─────────────────────────────────────────────────────────────
  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
    String phone = '',
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Save extra profile info in Firestore
    await _db.collection('users').doc(cred.user!.uid).set({
      'uid': cred.user!.uid,
      'name': name,
      'email': email,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await cred.user!.updateDisplayName(name);
    return cred;
  }

  // ─── Login ────────────────────────────────────────────────────────────────
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ─── Logout ───────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ─── Get User Profile ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUser == null) return null;
    final doc = await _db.collection('users').doc(currentUser!.uid).get();
    return doc.data();
  }

  // ─── Update User Profile ──────────────────────────────────────────────────
  Future<void> updateProfile({
    required String name,
    required String phone,
  }) async {
    if (currentUser == null) return;
    await _db.collection('users').doc(currentUser!.uid).update({
      'name': name,
      'phone': phone,
    });
    await currentUser!.updateDisplayName(name);
  }
}

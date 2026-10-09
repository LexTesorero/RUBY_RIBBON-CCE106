import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Staff accounts are NOT self-registered. Create the user in the Firebase
/// Auth console, then add a `users/{uid}` document with `role: 'staff'`.
/// (The app's single login page signs staff in; this service handles the
/// staff-only checks and profile.)
class StaffAuthService {
  static const String role = 'staff';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? lastError;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get userStream => _auth.authStateChanges();

  /// Strict staff-only sign-in (signs out again if the account is not staff).
  Future<User?> signinEmail(String email, String password) async {
    lastError = null;
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      final user = cred.user!;
      if (!await isStaff()) {
        await _auth.signOut();
        lastError = 'This account does not have staff access.';
        return null;
      }
      return user;
    } on FirebaseAuthException catch (e) {
      lastError = _friendly(e);
      return null;
    } catch (e) {
      debugPrint('Staff login error: $e');
      lastError = 'Something went wrong. Please try again.';
      return null;
    }
  }

  Future<bool> isStaff() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final snap = await _db.collection('users').doc(user.uid).get();
    return snap.data()?['role'] == role;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> staffProfileStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _db.collection('users').doc(user.uid).snapshots();
  }

  Future<bool> resetPassword(String email) async {
    lastError = null;
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      lastError = _friendly(e);
      return false;
    }
  }

  Future<void> signout() => _auth.signOut();

  String _friendly(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}
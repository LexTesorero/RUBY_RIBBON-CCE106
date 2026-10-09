import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:google_sign_in/google_sign_in.dart';

/// Sign-in methods are role-agnostic: AppState reads the account's role from
/// Firestore and AuthGate routes customers and staff to the right side.
class CustomerAuthService {
  static const String role = 'customer';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn? _googleSignIn = kIsWeb ? null : GoogleSignIn();

  /// Readable reason for the last failed call (show it in a SnackBar).
  String? lastError;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  User? get currentUser => _auth.currentUser;
  Stream<User?> get userStream => _auth.authStateChanges();

  // ---------- Register (email) ----------
  Future<User?> registerEmail({
    required String name,
    required String email,
    required String password,
    String contact = '',
    String address = '',
  }) async {
    lastError = null;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      final user = cred.user!;
      await user.updateDisplayName(name);
      await _users.doc(user.uid).set({
        'name': name,
        'email': user.email,
        'contact': contact,
        'address': address,
        'role': role,
        'created_at': Timestamp.now(),
      });
      try {
        await user.sendEmailVerification();
      } catch (e) {
        debugPrint('Verification email failed: $e'); // can be resent from the verify screen
      }
      return user;
    } on FirebaseAuthException catch (e) {
      lastError = _friendly(e);
      return null;
    } catch (e) {
      debugPrint('Registration error: $e');
      lastError = 'Something went wrong. Please try again.';
      return null;
    }
  }

  // ---------- Login (email) ----------
  Future<User?> signinEmail(String email, String password) async {
    lastError = null;
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      return cred.user;
    } on FirebaseAuthException catch (e) {
      lastError = _friendly(e);
      return null;
    } catch (e) {
      debugPrint('Login error: $e');
      lastError = 'Something went wrong. Please try again.';
      return null;
    }
  }

  // ---------- Login (Google) ----------
  Future<User?> signinGoogle() async {
    lastError = null;
    try {
      User? user;
      if (kIsWeb) {
        user = (await _auth.signInWithPopup(GoogleAuthProvider())).user;
      } else {
        final googleUser = await _googleSignIn!.signIn();
        if (googleUser == null) return null; // user cancelled
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        user = (await _auth.signInWithCredential(credential)).user;
      }
      return user == null ? null : await _ensureProfile(user);
    } on FirebaseAuthException catch (e) {
      lastError = _friendly(e);
      return null;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      lastError = 'Google sign-in failed. Please try again.';
      return null;
    }
  }

  // ---------- Email verification ----------
  Future<bool> resendVerification() async {
    lastError = null;
    try {
      await _auth.currentUser?.sendEmailVerification();
      return true;
    } on FirebaseAuthException catch (e) {
      lastError = _friendly(e);
      return false;
    }
  }

  /// Reloads the user and refreshes the ID token so Firestore rules see email_verified.
  Future<bool> checkVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    final fresh = _auth.currentUser;
    if (fresh != null && fresh.emailVerified) {
      await fresh.getIdToken(true);
      return true;
    }
    return false;
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

  Future<void> signout() async {
    if (!kIsWeb) await _googleSignIn?.signOut();
    await _auth.signOut();
  }

  // ---------- Profile ----------
  Stream<DocumentSnapshot<Map<String, dynamic>>> profileStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _users.doc(user.uid).snapshots();
  }

  Future<void> updateProfile({
    required String name,
    required String contact,
    required String address,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _users.doc(user.uid).update({'name': name, 'contact': contact, 'address': address});
    await user.updateDisplayName(name);
  }

  // Creates the customer profile on first sign-in (e.g. Google). Existing
  // profiles, including staff, are left alone.
  Future<User?> _ensureProfile(User user) async {
    final ref = _users.doc(user.uid);
    if (!(await ref.get()).exists) {
      await ref.set({
        'name': user.displayName ?? '',
        'email': user.email,
        'contact': '',
        'address': '',
        'role': role,
        'created_at': Timestamp.now(),
      });
    }
    return user;
  }

  String _friendly(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
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
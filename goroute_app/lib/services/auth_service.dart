import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── Custom exceptions ─────────────────────────────────────────────────────────

/// Thrown when the Firestore role does not match the selected role.
class RoleMismatchException implements Exception {
  final String message;
  const RoleMismatchException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId:
        '953453444633-s4r10479fdvv9spbsga9gipdlv3oud0t.apps.googleusercontent.com',
  );

  User? get currentUser => _auth.currentUser;

  // ── Sign In with Email ────────────────────────────────────────────────
  //
  // Strict role enforcement:
  //   - selectedRole == 'driver'    → Firestore role MUST be 'driver'
  //   - selectedRole == 'passenger' → Firestore role MUST be 'passenger'
  //
  // Any mismatch → sign out + throw RoleMismatchException.

  Future<UserCredential> signInWithEmail(
    String email,
    String password, {
    required String selectedRole,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _enforceRole(credential.user!.uid, selectedRole);
    return credential;
  }

  // ── Register ──────────────────────────────────────────────────────────
  // Self-registration always creates a passenger account.
  // Drivers are created by admin only.

  Future<UserCredential> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _createUserDoc(
      credential.user!,
      role: 'passenger',
      nameOverride: name,
    );
    return credential;
  }

  // ── Google Sign In ────────────────────────────────────────────────────

  Future<UserCredential> signInWithGoogle({
    required String selectedRole,
  }) async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google Sign-In cancelled');

    final googleAuth = await googleUser.authentication;
    final oauthCredential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final credential = await _auth.signInWithCredential(oauthCredential);

    // First-time Google sign-in → create passenger doc
    final snap = await _db.collection('users').doc(credential.user!.uid).get();
    if (!snap.exists) {
      await _createUserDoc(credential.user!, role: 'passenger');
    }

    await _enforceRole(credential.user!.uid, selectedRole);
    return credential;
  }

  // ── Get role from Firestore ───────────────────────────────────────────

  Future<String> getUserRole(String uid) async {
    try {
      final snap = await _db.collection('users').doc(uid).get();
      if (!snap.exists) return 'passenger';
      return (snap.data()?['role'] as String?) ?? 'passenger';
    } catch (_) {
      return 'passenger';
    }
  }

  // ── Update last login ─────────────────────────────────────────────────

  Future<void> updateLastLogin(String uid) async {
    await _db.collection('users').doc(uid).update({
      'lastLogin': FieldValue.serverTimestamp(),
      'isOnline': true,
    });
  }

  // ── Mark offline on sign-out ──────────────────────────────────────────

  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _db.collection('users').doc(uid).update({'isOnline': false});
    }
    await _auth.signOut();
  }

  // ── Internal helpers ──────────────────────────────────────────────────

  /// Checks that the Firestore role exactly matches [selectedRole].
  /// Signs out and throws [RoleMismatchException] on mismatch.
  Future<void> _enforceRole(String uid, String selectedRole) async {
    final firestoreRole = await getUserRole(uid);

    if (firestoreRole != selectedRole) {
      await _auth.signOut();
      throw RoleMismatchException(
        'Invalid role access. '
        'You selected "$selectedRole" but your account is registered as '
        '"$firestoreRole". Please choose the correct role.',
      );
    }
  }

  Future<void> _createUserDoc(
    User user, {
    required String role,
    String? nameOverride,
  }) async {
    await _db.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': nameOverride ?? user.displayName ?? 'No Name',
      'email': user.email ?? '',
      'role': role,
      'isActive': true,
      'isOnline': false,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

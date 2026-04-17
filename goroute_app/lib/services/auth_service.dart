import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirebaseAuth get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      throw Exception('Firebase is not initialized. Please check your setup.');
    }
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'https://www.googleapis.com/auth/contacts.readonly'],
  );

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle({required String role}) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      if (userCredential.user != null) {
        await syncUserToFirestore(userCredential.user!, role: role);
      }
      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  // Sign in with Email and Password
  Future<UserCredential?> signInWithEmail(
    String email,
    String password, {
    required String role,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        await syncUserToFirestore(userCredential.user!, role: role);
      }
      return userCredential;
    } catch (e) {
      print('Error signing in with email: $e');
      return null;
    }
  }

  // Register with Email and Password
  Future<UserCredential?> registerWithEmail(
    String email,
    String password,
    String name, {
    required String role,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(name);
        await syncUserToFirestore(
          userCredential.user!,
          role: role,
          nameOverride: name,
        );
      }
      return userCredential;
    } catch (e) {
      print('Error registering: $e');
      return null;
    }
  }

  // Sync user data to Firestore
  Future<void> syncUserToFirestore(
    User user, {
    required String role,
    String? nameOverride,
  }) async {
    try {
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': nameOverride ?? user.displayName ?? 'No Name',
        'email': user.email,
        'role': role,
        'isOnline': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error syncing user to Firestore: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    if (currentUser != null) {
      await _db.collection('users').doc(currentUser!.uid).update({
        'isOnline': false,
      });
    }
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}

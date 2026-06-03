import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;
  static final _googleSignIn = GoogleSignIn();

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  static bool get isLoggedIn => currentUser != null;
  static String get userId => currentUser?.uid ?? '';

  // ── Google Sign In ────────────────────────────────────────────────────────
  static Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      await _createOrUpdateUser(userCredential.user!);
      await FirebaseService.logEvent('login', {'method': 'google'});
      return userCredential.user;
    } catch (e) {
      print('Google sign in error: $e');
      return null;
    }
  }

  // ── Apple Sign In ─────────────────────────────────────────────────────────
  static Future<User?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      await _createOrUpdateUser(userCredential.user!);
      await FirebaseService.logEvent('login', {'method': 'apple'});
      return userCredential.user;
    } catch (e) {
      print('Apple sign in error: $e');
      return null;
    }
  }

  // ── Email & Password ──────────────────────────────────────────────────────
  static Future<User?> signUpWithEmail(String email, String password, String name) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await credential.user?.updateDisplayName(name);
      await _createOrUpdateUser(credential.user!);
      await FirebaseService.logEvent('sign_up', {'method': 'email'});
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _authError(e.code);
    }
  }

  static Future<User?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      await FirebaseService.logEvent('login', {'method': 'email'});
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _authError(e.code);
    }
  }

  static Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    await FirebaseService.logEvent('logout');
  }

  // ── Firestore User Doc ────────────────────────────────────────────────────
  static Future<void> _createOrUpdateUser(User user) async {
    final doc = _firestore.collection('users').doc(user.uid);
    final snap = await doc.get();

    if (!snap.exists) {
      await doc.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'name': user.displayName ?? '',
        'photoUrl': user.photoURL ?? '',
        'plan': 'free',
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
        'totalSearches': 0,
        'dietaryPrefs': [],
        'notificationsEnabled': true,
      });
    } else {
      await doc.update({'lastSeen': FieldValue.serverTimestamp()});
    }

    await FirebaseService.setUserProperty('plan', snap.data()?['plan'] ?? 'free');
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    if (!isLoggedIn) return null;
    final snap = await _firestore.collection('users').doc(userId).get();
    return snap.data();
  }

  static Future<void> updateUserData(Map<String, dynamic> data) async {
    if (!isLoggedIn) return;
    await _firestore.collection('users').doc(userId).update(data);
  }

  static String _authError(String code) {
    switch (code) {
      case 'email-already-in-use': return 'This email is already registered.';
      case 'invalid-email': return 'Please enter a valid email address.';
      case 'weak-password': return 'Password must be at least 6 characters.';
      case 'user-not-found': return 'No account found with this email.';
      case 'wrong-password': return 'Incorrect password. Try again.';
      default: return 'Something went wrong. Please try again.';
    }
  }
}

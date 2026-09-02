import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<UserCredential> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    final userCredential =
        await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = userCredential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-created',
        message: 'The user account could not be created.',
      );
    }
await user.sendEmailVerification();

    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'fullName': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'role': role,
      'active': true,
      'verificationStatus':
          role == 'cook' ? 'not_started' : 'not_applicable',
      'verificationSubmitted':
          role == 'cook' ? false : true,
      'verified':
          role == 'cook' ? false : true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return userCredential;
  }

  Future<UserCredential> signIn({
  required String email,
  required String password,
}) async {
  return _auth.signInWithEmailAndPassword(
    email: email.trim(),
    password: password,
  );
}
Future<void> resendEmailVerification() async {
  final user = _auth.currentUser;

  if (user == null) {
    throw FirebaseAuthException(
      code: 'no-current-user',
      message: 'No signed-in user was found.',
    );
  }

  await user.sendEmailVerification();
}

Future<bool> refreshEmailVerificationStatus() async {
  final user = _auth.currentUser;

  if (user == null) {
    return false;
  }

  await user.reload();

  final refreshedUser = _auth.currentUser;

  return refreshedUser?.emailVerified ?? false;
}
  Future<void> logout() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges =>
      _auth.authStateChanges();
}
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_backend.dart';
import 'package:firebase_auth/firebase_auth.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final authUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authServiceProvider).currentUser?.uid;
});

class AuthService {
  AuthService([AuthBackend? authBackend])
    : _auth = authBackend ?? FirebaseAuthBackend();

  final AuthBackend _auth;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final user = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Unknown Error';
    }
  }

  Future<User?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final user = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Unknown Error';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

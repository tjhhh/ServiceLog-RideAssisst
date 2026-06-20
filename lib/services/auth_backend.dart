import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class AuthBackend {
  Stream<User?> authStateChanges();
  User? get currentUser;
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<User?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<void> signOut();
}

class FirebaseAuthBackend implements AuthBackend {
  FirebaseAuthBackend([FirebaseAuth? auth])
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return (await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    )).user;
  }

  @override
  Future<User?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return (await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    )).user;
  }

  @override
  Future<void> signOut() => _auth.signOut();
}

final authBackendProvider = Provider<AuthBackend>(
  (ref) => FirebaseAuthBackend(),
);

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Dedicated Authentication Repository for FreeWatch (`freewatch-a0bc7`)
class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseDatabase _database;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseDatabase? database,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _database = database ?? FirebaseDatabase.instance;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  /// Register new user account and save initial profile to FreeWatch RTDB
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String avatarAsset,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      try {
        await user.updateDisplayName(name.trim());
      } catch (_) {}

      try {
        final userRef = _database.ref('users/${user.uid}/profile');
        await userRef.set({
          'uid': user.uid,
          'email': user.email ?? email.trim(),
          'name': name.trim(),
          'avatar': avatarAsset,
          'createdAt': DateTime.now().toIso8601String(),
          'bio': 'Action & Sci-Fi enthusiast • FreeWatch member',
        });
      } catch (e) {
        debugPrint('Failed to save profile to RTDB: $e');
      }
    }

    return credential;
  }

  /// Sign in existing user account with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  /// Fetch user profile from FreeWatch RTDB
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final snapshot = await _database.ref('users/$uid/profile').get();
      if (snapshot.exists && snapshot.value is Map) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
    } catch (e) {
      debugPrint('Failed to read profile from RTDB: $e');
    }
    return null;
  }
}

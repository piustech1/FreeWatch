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
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: cleanPassword,
    );

    final user = credential.user;
    if (user != null) {
      try {
        await user.updateDisplayName(name.trim());
      } catch (_) {}

      // Save initial profile asynchronously without blocking instant UI navigation
      final userRef = _database.ref('users/${user.uid}/profile');
      userRef.set({
        'uid': user.uid,
        'email': user.email ?? cleanEmail,
        'name': name.trim(),
        'avatar': avatarAsset,
        'createdAt': DateTime.now().toIso8601String(),
        'bio': 'Action & Sci-Fi enthusiast • FreeWatch member',
      }).timeout(
        const Duration(seconds: 2),
        onTimeout: () => debugPrint('RTDB profile set timed out, continuing in background'),
      ).catchError((e) {
        debugPrint('Failed to save profile to RTDB: $e');
      });
    }

    return credential;
  }

  /// Sign in existing user account with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: cleanEmail,
      password: cleanPassword,
    );
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  /// Fetch user profile from FreeWatch RTDB (with quick timeout)
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final snapshot = await _database
          .ref('users/$uid/profile')
          .get()
          .timeout(const Duration(seconds: 2));
      if (snapshot.exists && snapshot.value is Map) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
    } catch (e) {
      debugPrint('Failed to read profile from RTDB: $e');
    }
    return null;
  }
}

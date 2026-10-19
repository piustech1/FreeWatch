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
        'role': 'Member',
        'status': 'Active',
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
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: cleanEmail,
      password: cleanPassword,
    );

    // Verify account status in Firebase RTDB
    final user = credential.user;
    if (user != null) {
      try {
        final profileSnap = await _database
            .ref('users/${user.uid}/profile')
            .get()
            .timeout(const Duration(seconds: 3));
        if (profileSnap.exists && profileSnap.value is Map) {
          final data = Map<String, dynamic>.from(profileSnap.value as Map);
          if (data['status'] == 'Banned') {
            await _firebaseAuth.signOut();
            throw FirebaseAuthException(
              code: 'user-disabled',
              message: 'Your account has been suspended by administration. Please contact support.',
            );
          }
        }
        _database.ref('users/${user.uid}/profile/lastLogin').set(DateTime.now().toIso8601String());
      } catch (e) {
        if (e is FirebaseAuthException) rethrow;
      }
    }

    return credential;
  }

  /// Sign in as Guest (Anonymous) for quick 1-click access without password entry
  Future<UserCredential> signInAsGuest() async {
    final credential = await _firebaseAuth.signInAnonymously();
    final user = credential.user;
    if (user != null) {
      final userRef = _database.ref('users/${user.uid}/profile');
      userRef.set({
        'uid': user.uid,
        'email': 'guest@freewatch.app',
        'name': 'Guest User',
        'avatar': 'assets/avatars/avatar_mirabel.png',
        'createdAt': DateTime.now().toIso8601String(),
        'lastLogin': DateTime.now().toIso8601String(),
        'bio': 'Streaming as Guest • FreeWatch',
        'role': 'Member',
        'status': 'Active',
      }).catchError((_) {});
    }
    return credential;
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

  /// Persist user favorites to FreeWatch RTDB
  Future<void> saveUserFavorites(String uid, List<Map<String, dynamic>> favoritesJson) async {
    try {
      await _database.ref('users/$uid/favorites').set(favoritesJson).timeout(
        const Duration(seconds: 4),
        onTimeout: () => debugPrint('RTDB save favorites timed out, continuing in background'),
      );
    } catch (e) {
      debugPrint('Failed to save favorites to RTDB: $e');
    }
  }

  /// Retrieve user favorites from FreeWatch RTDB
  Future<List<Map<String, dynamic>>> getUserFavorites(String uid) async {
    try {
      final snapshot = await _database
          .ref('users/$uid/favorites')
          .get()
          .timeout(const Duration(seconds: 4));
      if (snapshot.exists && snapshot.value is List) {
        final list = snapshot.value as List;
        return list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to read favorites from RTDB: $e');
    }
    return [];
  }

  /// Persist user watch history to FreeWatch RTDB
  Future<void> saveUserWatchHistory(String uid, List<Map<String, dynamic>> historyJson) async {
    try {
      await _database.ref('users/$uid/watch_history').set(historyJson).timeout(
        const Duration(seconds: 4),
        onTimeout: () => debugPrint('RTDB save watch history timed out, continuing in background'),
      );
    } catch (e) {
      debugPrint('Failed to save watch history to RTDB: $e');
    }
  }

  /// Retrieve user watch history from FreeWatch RTDB
  Future<List<Map<String, dynamic>>> getUserWatchHistory(String uid) async {
    try {
      final snapshot = await _database
          .ref('users/$uid/watch_history')
          .get()
          .timeout(const Duration(seconds: 4));
      if (snapshot.exists && snapshot.value is List) {
        final list = snapshot.value as List;
        return list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to read watch history from RTDB: $e');
    }
    return [];
  }
}

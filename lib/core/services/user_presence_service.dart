import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// Service managing user online presence & last seen timestamps in Firebase RTDB
class UserPresenceService with WidgetsBindingObserver {
  static final UserPresenceService _instance = UserPresenceService._internal();
  factory UserPresenceService() => _instance;
  UserPresenceService._internal();

  StreamSubscription<DatabaseEvent>? _connectionSub;
  StreamSubscription<User?>? _authSub;
  bool _initialized = false;
  bool _isAppResumed = true;

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    WidgetsBinding.instance.addObserver(this);

    // Track active user changes
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _setupPresence(user.uid);
      } else {
        _cleanupPresence();
      }
    });

    // Also check current user immediately
    final current = FirebaseAuth.instance.currentUser;
    if (current != null) {
      _setupPresence(current.uid);
    }
  }

  void _setupPresence(String uid) {
    _connectionSub?.cancel();

    final connectedRef = FirebaseDatabase.instance.ref('.info/connected');
    _connectionSub = connectedRef.onValue.listen((event) async {
      final isConnected = event.snapshot.value == true;
      if (isConnected && _isAppResumed) {
        try {
          final presenceRef = FirebaseDatabase.instance.ref('users/$uid/presence');
          final profileRef = FirebaseDatabase.instance.ref('users/$uid/profile');

          // Register onDisconnect hooks
          await presenceRef.onDisconnect().update({
            'isOnline': false,
            'lastSeen': ServerValue.timestamp,
          });
          await profileRef.onDisconnect().update({
            'isOnline': false,
            'lastSeen': ServerValue.timestamp,
          });

          // Mark user online now
          await presenceRef.update({
            'isOnline': true,
            'lastSeen': ServerValue.timestamp,
            'platform': defaultTargetPlatform.name,
          });
          await profileRef.update({
            'isOnline': true,
            'lastSeen': ServerValue.timestamp,
          });
        } catch (e) {
          debugPrint('[UserPresenceService] Setup presence error: $e');
        }
      }
    });
  }

  void _cleanupPresence() {
    _connectionSub?.cancel();
    _connectionSub = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (state == AppLifecycleState.resumed) {
      _isAppResumed = true;
      _setOnlineStatus(uid, true);
    } else if (state == AppLifecycleState.paused ||
               state == AppLifecycleState.detached ||
               state == AppLifecycleState.inactive) {
      _isAppResumed = false;
      _setOnlineStatus(uid, false);
    }
  }

  Future<void> _setOnlineStatus(String uid, bool isOnline) async {
    try {
      final presenceRef = FirebaseDatabase.instance.ref('users/$uid/presence');
      final profileRef = FirebaseDatabase.instance.ref('users/$uid/profile');

      await presenceRef.update({
        'isOnline': isOnline,
        'lastSeen': ServerValue.timestamp,
      });
      await profileRef.update({
        'isOnline': isOnline,
        'lastSeen': ServerValue.timestamp,
      });
    } catch (_) {}
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupPresence();
    _authSub?.cancel();
    _authSub = null;
    _initialized = false;
  }
}

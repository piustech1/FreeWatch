import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../screens/banned_account_screen.dart';

/// Global widget that monitors account ban status in real-time.
/// If the account is marked Banned in Firebase RTDB, it immediately
/// presents the BannedAccountScreen over the active UI.
class UserBanWatcher extends StatefulWidget {
  final Widget child;
  const UserBanWatcher({super.key, required this.child});

  @override
  State<UserBanWatcher> createState() => _UserBanWatcherState();
}

class _UserBanWatcherState extends State<UserBanWatcher> {
  StreamSubscription<User?>? _authSub;
  StreamSubscription<DatabaseEvent>? _profileSub;
  bool _isBanned = false;
  String? _banReason;

  @override
  void initState() {
    super.initState();
    try {
      _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) {
          _subscribeToUserStatus(user.uid);
        } else {
          _unsubscribeFromUserStatus();
          if (_isBanned) {
            if (mounted) {
              setState(() {
                _isBanned = false;
                _banReason = null;
              });
            }
          }
        }
      });

      final current = FirebaseAuth.instance.currentUser;
      if (current != null) {
        _subscribeToUserStatus(current.uid);
      }
    } catch (_) {
      // In test environments where Firebase is not initialized
    }
  }

  void _subscribeToUserStatus(String uid) {
    _profileSub?.cancel();
    try {
      final profileRef = FirebaseDatabase.instance.ref('users/$uid/profile');
      _profileSub = profileRef.onValue.listen((event) {
        final val = event.snapshot.value;
        if (val is Map) {
          final data = Map<String, dynamic>.from(val);
          final status = data['status']?.toString();
          final isBanned = data['isBanned'] == true || status == 'Banned';
          final reason = data['banReason']?.toString();

          if (isBanned != _isBanned || reason != _banReason) {
            if (mounted) {
              setState(() {
                _isBanned = isBanned;
                _banReason = reason;
              });
            }
          }
        }
      });
    } catch (_) {}
  }

  void _unsubscribeFromUserStatus() {
    _profileSub?.cancel();
    _profileSub = null;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isBanned) {
      return BannedAccountScreen(initialReason: _banReason);
    }
    return widget.child;
  }
}

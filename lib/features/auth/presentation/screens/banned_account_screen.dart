import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../chat/presentation/screens/developer_chat_screen.dart';

class BannedAccountScreen extends StatefulWidget {
  final String? initialReason;
  const BannedAccountScreen({super.key, this.initialReason});

  @override
  State<BannedAccountScreen> createState() => _BannedAccountScreenState();
}

class _BannedAccountScreenState extends State<BannedAccountScreen> {
  StreamSubscription<DatabaseEvent>? _statusSub;
  String _reason = '';
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _reason = widget.initialReason ?? '';
    _listenToStatus();
  }

  void _listenToStatus() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final profileRef = FirebaseDatabase.instance.ref('users/$uid/profile');
    _statusSub = profileRef.onValue.listen((event) {
      if (!mounted) return;
      final val = event.snapshot.value;
      if (val is Map) {
        final data = Map<String, dynamic>.from(val);
        final status = data['status']?.toString();
        final isBanned = data['isBanned'] == true || status == 'Banned';
        final reason = data['banReason']?.toString() ?? '';

        if (reason.isNotEmpty) {
          setState(() => _reason = reason);
        }

        // If admin unbanned the user in real-time, auto-restore access!
        if (!isBanned) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account has been reactivated! Welcome back to FreeWatch.'),
              backgroundColor: Color(0xFF00E676),
            ),
          );
          context.go('/home');
        }
      }
    });
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    super.dispose();
  }

  Future<void> _handleSignOut() async {
    setState(() => _isSigningOut = true);
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        context.go('/onboarding');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  void _openLiveChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const DeveloperChatScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final uid = currentUser?.uid ?? 'Unknown';
    final email = currentUser?.email ?? 'Unknown User';

    return WillPopScope(
      onWillPop: () async => false, // Prevent back button navigation while banned
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // FreeWatch Glowing Suspension Shield
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0x33EF4444), Color(0x05EF4444)],
                      ),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withOpacity(0.2),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.gavel_rounded,
                        color: Color(0xFFEF4444),
                        size: 44,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Main Title
                  const Text(
                    'Account Suspended',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  // Explanation
                  Text(
                    'Your FreeWatch account access has been restricted by platform administration.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.65),
                      height: 1.45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141416),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Account Email', email),
                        const Divider(height: 20, color: Colors.white10),
                        _buildInfoRow('User ID', uid),
                        if (_reason.isNotEmpty) ...[
                          const Divider(height: 20, color: Colors.white10),
                          _buildInfoRow('Ban Reason', _reason, isHighlighted: true),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Action Button 1: Appeal / Contact Live Support
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _openLiveChat,
                      icon: const Icon(Icons.support_agent_rounded, color: Colors.black, size: 20),
                      label: const Text(
                        'Appeal via Live Support',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Action Button 2: Sign Out
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isSigningOut ? null : _handleSignOut,
                      icon: _isSigningOut
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.logout_rounded, color: Colors.white70, size: 18),
                      label: Text(
                        _isSigningOut ? 'Signing out...' : 'Sign Out & Return Home',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withOpacity(0.15)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlighted = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Colors.white.withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isHighlighted ? const Color(0xFFF87171) : Colors.white,
          ),
        ),
      ],
    );
  }
}

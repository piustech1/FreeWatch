import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

/// WhatsApp-style Account Review / Appeal Submission & Tracking Screen
class BannedReviewScreen extends StatefulWidget {
  final String? banReason;

  const BannedReviewScreen({super.key, this.banReason});

  @override
  State<BannedReviewScreen> createState() => _BannedReviewScreenState();
}

class _BannedReviewScreenState extends State<BannedReviewScreen> {
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoading = true;
  Map<String, dynamic>? _existingReview;
  StreamSubscription<DatabaseEvent>? _reviewSub;
  StreamSubscription<DatabaseEvent>? _profileSub;

  @override
  void initState() {
    super.initState();
    _fetchExistingReview();
    _listenToProfileChanges();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _reviewSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }

  void _listenToProfileChanges() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _profileSub = FirebaseDatabase.instance.ref('users/$uid/profile').onValue.listen((event) {
      if (!mounted) return;
      final val = event.snapshot.value;
      if (val is Map) {
        final data = Map<String, dynamic>.from(val);
        final status = data['status']?.toString();
        final isBanned = data['isBanned'] == true || status == 'Banned';
        if (!isBanned) {
          // User was unbanned in real-time!
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your appeal was approved! Account access restored.'),
              backgroundColor: Color(0xFF00E676),
            ),
          );
          context.go('/home');
        }
      }
    });
  }

  void _fetchExistingReview() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    final reviewRef = FirebaseDatabase.instance.ref('account_reviews/$uid');
    _reviewSub = reviewRef.onValue.listen((event) {
      if (!mounted) return;
      final val = event.snapshot.value;
      if (val is Map) {
        setState(() {
          _existingReview = Map<String, dynamic>.from(val);
          _isLoading = false;
        });
      } else {
        setState(() {
          _existingReview = null;
          _isLoading = false;
        });
      }
    }, onError: (_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  Future<void> _submitReview() async {
    final text = _reviewController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an explanation for your review request.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      final reviewRef = FirebaseDatabase.instance.ref('account_reviews/${user.uid}');
      await reviewRef.set({
        'uid': user.uid,
        'email': user.email ?? 'Unknown',
        'name': user.displayName ?? 'FreeWatch Viewer',
        'banReason': widget.banReason ?? 'Restricted by Admin',
        'reviewText': text,
        'status': 'pending',
        'createdAt': ServerValue.timestamp,
        'submittedAt': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review request submitted successfully.'),
          backgroundColor: Color(0xFF00E676),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit review: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Request a Review',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF00E676)),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: _existingReview != null && _existingReview!['status'] != 'rejected'
                    ? _buildReviewStatusView()
                    : _buildReviewFormView(),
              ),
      ),
    );
  }

  /// WhatsApp-styled review submission form
  Widget _buildReviewFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // WhatsApp Shield / Status Icon
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00E676).withOpacity(0.12),
              border: Border.all(
                color: const Color(0xFF00E676).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.assignment_ind_rounded,
                color: Color(0xFF00E676),
                size: 34,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        const Center(
          child: Text(
            'Submit Case for Evaluation',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 10),

        Center(
          child: Text(
            'FreeWatch platform administration will review your account details, activity logs, and appeal to check for compliance with our terms of service.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.65),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 28),

        // Ban reason context card
        if (widget.banReason != null && widget.banReason!.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x15EF4444),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x33EF4444)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFFF87171), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Recorded ban reason: "${widget.banReason}"',
                    style: const TextStyle(
                      color: Color(0xFFFCA5A5),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Text input field
        Text(
          'Add details to support your case',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.85),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141416),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: TextField(
            controller: _reviewController,
            maxLines: 6,
            maxLength: 500,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Explain why you believe this suspension was issued in error...',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 13,
              ),
              counterStyle: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Guidelines Notice
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.schedule_rounded, color: Colors.white.withOpacity(0.4), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Reviews usually take up to 24 hours. Once reviewed, your account will be unlocked automatically if approved.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Submit Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitReview,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : const Text(
                    'Submit Request',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  /// WhatsApp-styled Pending / In-Review status view
  Widget _buildReviewStatusView() {
    final status = _existingReview?['status']?.toString() ?? 'pending';
    final isApproved = status == 'approved';
    final submittedText = _existingReview?['reviewText']?.toString() ?? '';

    return Column(
      children: [
        const SizedBox(height: 30),
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isApproved
                ? const Color(0xFF00E676).withOpacity(0.15)
                : const Color(0xFFF59E0B).withOpacity(0.15),
            border: Border.all(
              color: isApproved
                  ? const Color(0xFF00E676).withOpacity(0.4)
                  : const Color(0xFFF59E0B).withOpacity(0.4),
              width: 2,
            ),
          ),
          child: Center(
            child: Icon(
              isApproved ? Icons.verified_rounded : Icons.pending_actions_rounded,
              color: isApproved ? const Color(0xFF00E676) : const Color(0xFFF59E0B),
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 24),

        Text(
          isApproved ? 'Appeal Approved' : 'Review in Progress',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),

        Text(
          isApproved
              ? 'Your account suspension has been lifted. You can now access FreeWatch.'
              : 'Your review request has been submitted to platform moderators. You will regain access automatically once approved.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.65),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),

        // Review Details Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF141416),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'STATUS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.4),
                      letterSpacing: 0.8,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isApproved
                          ? const Color(0xFF00E676).withOpacity(0.15)
                          : const Color(0xFFF59E0B).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isApproved ? 'Approved' : 'Pending Evaluation',
                      style: TextStyle(
                        color: isApproved ? const Color(0xFF00E676) : const Color(0xFFF59E0B),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              if (submittedText.isNotEmpty) ...[
                const Divider(height: 24, color: Colors.white10),
                Text(
                  'YOUR STATEMENT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.4),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  submittedText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 32),

        if (isApproved)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Open FreeWatch',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Checking latest review decision...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
              label: const Text(
                'Check Status',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
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
    );
  }
}

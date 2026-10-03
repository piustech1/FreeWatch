import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_colors.dart';

/// Persistent Top Header / App Bar with FreeWatch full logo, search, notification, and cast streaming buttons
class FreeWatchTopAppBar extends StatelessWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onNotificationTap;

  const FreeWatchTopAppBar({
    super.key,
    required this.onSearchTap,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 12, 6),
      child: Row(
        children: [
          // ── Brand Logo ────────────────────────────────────────────────────
          Image.asset(
            'assets/images/logo_full.png',
            height: 48,
            fit: BoxFit.contain,
          ),

          const Spacer(),

          // ── Search Button ─────────────────────────────────────────────────
          IconButton(
            onPressed: onSearchTap,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            icon: const Icon(
              IconlyBold.search,
              color: AppColors.textPrimary,
              size: 24,
            ),
          ),

          const SizedBox(width: 14),

          // ── Notification Button with Badge ────────────────────────────────
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                onPressed: onNotificationTap,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                icon: const Icon(
                  IconlyBold.notification,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          // ── Cast Button ───────────────────────────────────────────────────
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  duration: Duration(milliseconds: 1000),
                  backgroundColor: Color(0xFF161922),
                  content: Text('Searching for Google Cast & AirPlay devices...',
                      style: TextStyle(color: Colors.white)),
                ),
              );
            },
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            icon: const Icon(
              Icons.cast_rounded,
              color: AppColors.textPrimary,
              size: 23,
            ),
          ),
        ],
      ),
    );
  }
}

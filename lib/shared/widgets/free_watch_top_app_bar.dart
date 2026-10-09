import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_colors.dart';
import '../../features/auth/presentation/providers/user_avatar_provider.dart';
import '../../features/notifications/presentation/providers/notifications_provider.dart';

/// Persistent Top Header / App Bar with FreeWatch full logo, search, notification, and profile avatar
class FreeWatchTopAppBar extends ConsumerWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onNotificationTap;
  final VoidCallback? onProfileTap;

  const FreeWatchTopAppBar({
    super.key,
    required this.onSearchTap,
    required this.onNotificationTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = ref.watch(userAvatarProvider);
    final unreadNotifications = ref.watch(unreadNotificationsCountProvider);

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
              if (unreadNotifications > 0)
                Positioned(
                  top: 2,
                  right: 2,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        unreadNotifications > 99 ? '99+' : '$unreadNotifications',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 14),

          // ── User Selected Profile Avatar ──────────────────────────────────
          GestureDetector(
            onTap: onProfileTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.35),
                  width: 1.2,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  avatar.assetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    IconlyBold.profile,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


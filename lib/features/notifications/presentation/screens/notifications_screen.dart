import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../home/providers/home_providers.dart';
import '../../../home/widgets/floating_nav_bar.dart';
import '../../../movie_detail/presentation/screens/movie_detail_screen.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/free_watch_top_app_bar.dart';
import '../../data/models/notification_item.dart';
import '../providers/notifications_provider.dart';

/// Notifications screen replicating the clean iOS-inspired design from reference UI:
/// - Fixed FreeWatchTopAppBar and FloatingNavBar matching home screen
/// - iOS back chevron & subheader
/// - Prominent "Notifications" title with red circular count badge [2]
/// - Distinct "Today" & "This week" sections
/// - Dark squircle icon tiles with vivid category icons
/// - Engaging multi-line streaming notifications
/// - Solid red unread indicator dots on the right
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final currentNavIndex = ref.watch(bottomNavIndexProvider);

    // Group notifications by section (Today, This week, etc.)
    final todayItems =
        notifications.where((n) => n.section == 'Today').toList();
    final thisWeekItems =
        notifications.where((n) => n.section == 'This week').toList();
    final earlierItems = notifications
        .where((n) => n.section != 'Today' && n.section != 'This week')
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Header / App Bar (Fixed across all screens) ──────────────────
                FreeWatchTopAppBar(
                  onSearchTap: () {
                    Navigator.of(context).pop();
                    navigateToBottomNavTab(context, ref, 1);
                  },
                  onNotificationTap: () {},
                  onProfileTap: () {
                    Navigator.of(context).pop();
                    navigateToBottomNavTab(context, ref, 4);
                  },
                ),

                // ── Top Subheader: Back Navigation & Actions ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 16, 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                      if (unreadCount > 0)
                        TextButton(
                          onPressed: () {
                            ref.read(notificationsProvider.notifier).markAllAsRead();
                            AppToast.show(
                              context,
                              'All notifications marked as read',
                              isSuccess: true,
                            );
                          },
                          child: Text(
                            'Mark all read',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.60),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Page Header: "Notifications" + Circular Red Badge ─────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 10),
                        Container(
                          width: 25,
                          height: 25,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF3B30), // iOS vibrant red
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Scrollable Notifications List ──────────────────────────────
                Expanded(
                  child: notifications.isEmpty
                      ? _buildEmptyState()
                      : ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 96),
                          children: [
                            if (todayItems.isNotEmpty) ...[
                              _buildSectionHeader('Today'),
                              ...todayItems.map(
                                (item) => _buildNotificationRow(context, ref, item),
                              ),
                            ],
                            if (thisWeekItems.isNotEmpty) ...[
                              _buildSectionHeader('This week'),
                              ...thisWeekItems.map(
                                (item) => _buildNotificationRow(context, ref, item),
                              ),
                            ],
                            if (earlierItems.isNotEmpty) ...[
                              _buildSectionHeader('Earlier'),
                              ...earlierItems.map(
                                (item) => _buildNotificationRow(context, ref, item),
                              ),
                            ],
                          ],
                        ),
                ),
              ],
            ),

            // ── Floating Bottom Navigation Pill ──────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingNavBar(
                selectedIndex: currentNavIndex,
                onItemSelected: (index) {
                  Navigator.of(context).pop();
                  navigateToBottomNavTab(context, ref, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withOpacity(0.55),
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  Widget _buildNotificationRow(
    BuildContext context,
    WidgetRef ref,
    NotificationItem item,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ref.read(notificationsProvider.notifier).markAsRead(item.id);
          if (item.linkedMovie != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MovieDetailScreen(movie: item.linkedMovie!),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Squircle Icon Container
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF13151E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 0.8,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  item.icon,
                  color: item.iconColor,
                  size: 24,
                ),
              ),

              const SizedBox(width: 14),

              // 2. Middle Message Text & Timestamp
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.message,
                      style: TextStyle(
                        color: item.isRead
                            ? Colors.white.withOpacity(0.72)
                            : Colors.white,
                        fontSize: 14.5,
                        fontWeight:
                            item.isRead ? FontWeight.w500 : FontWeight.w600,
                        height: 1.35,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (item.time.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.time,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.38),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 3. Right Unread Solid Red Dot Indicator
              if (!item.isRead)
                Container(
                  margin: const EdgeInsets.only(left: 14),
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF3B30), // Solid red dot matching UI
                    shape: BoxShape.circle,
                  ),
                )
              else
                const SizedBox(width: 23),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.notifications_none_rounded,
              color: Colors.white.withOpacity(0.40),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Notifications',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You are completely caught up!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

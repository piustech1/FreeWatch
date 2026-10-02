import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/mock/mock_movies.dart';
import '../../../../data/models/movie.dart';
import '../../../movie_detail/presentation/screens/movie_detail_screen.dart';

class _NotificationItem {
  final String id;
  final String category; // 'Releases', 'VJ Drops', 'System'
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Movie? linkedMovie;
  bool isRead;

  _NotificationItem({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    this.linkedMovie,
    this.isRead = false,
  });
}

/// Dedicated full-screen Notifications screen
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedCategory = 'All';

  late final List<_NotificationItem> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = [
      _NotificationItem(
        id: '1',
        category: 'VJ Drops',
        title: 'New VJ Translation Drop! 🎙️',
        body: 'VJ Junior just released the exclusive Luganda studio translation for "Gladiator II". Stream now in 4K!',
        time: '12m ago',
        icon: Icons.record_voice_over_rounded,
        linkedMovie: MockData.newMovies[3], // Gladiator II
        isRead: false,
      ),
      _NotificationItem(
        id: '2',
        category: 'Releases',
        title: 'Blockbuster Arrival 🍿',
        body: '"Deadpool & Wolverine" is now streaming in Ultra HD with Dolby Atmos master sound.',
        time: '2h ago',
        icon: Icons.movie_filter_rounded,
        linkedMovie: MockData.trendingMovies[2], // Deadpool & Wolverine
        isRead: false,
      ),
      _NotificationItem(
        id: '3',
        category: 'VJ Drops',
        title: 'VJ Emmy Weekend Pick ⚡',
        body: 'VJ Emmy recommended "Dune: Part Two" with complete Luganda commentary and cultural breakdown.',
        time: '5h ago',
        icon: Icons.verified_rounded,
        linkedMovie: MockData.trendingMovies[1], // Dune 2
        isRead: true,
      ),
      _NotificationItem(
        id: '4',
        category: 'Releases',
        title: 'Fresh Animation Drop ✨',
        body: 'Disney\'s "Lilo & Stitch" live-action is ready to binge for family movie night.',
        time: 'Yesterday',
        icon: Icons.auto_awesome_rounded,
        linkedMovie: MockData.newMovies[0], // Lilo & Stitch
        isRead: true,
      ),
      _NotificationItem(
        id: '5',
        category: 'System',
        title: 'FreeWatch v1.0.12 Live 🚀',
        body: 'Your streaming app is now faster with instant video buffering, new search, and Disney avatars.',
        time: '2 days ago',
        icon: Icons.rocket_launch_rounded,
        isRead: true,
      ),
    ];
  }

  void _markAllAsRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        duration: Duration(milliseconds: 900),
        backgroundColor: Color(0xFF161922),
        content: Text('All notifications marked as read',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _notifications.where((n) {
      if (_selectedCategory == 'All') return true;
      return n.category == _selectedCategory;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text(
              'Mark all read',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Category Filters ────────────────────────────────────────────
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                children: ['All', 'VJ Drops', 'Releases', 'System'].map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent
                            : const Color(0xFF151821),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accent
                              : Colors.white.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // ── Notifications List ──────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No notifications in this category',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5), fontSize: 13),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final item = filtered[i];
                        return _buildNotificationCard(item);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(_NotificationItem item) {
    return GestureDetector(
      onTap: () {
        setState(() => item.isRead = true);
        if (item.linkedMovie != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MovieDetailScreen(movie: item.linkedMovie!),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isRead
              ? const Color(0xFF11141B)
              : const Color(0xFF161A24),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: item.isRead
                ? Colors.white.withOpacity(0.06)
                : AppColors.accent.withOpacity(0.35),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.isRead
                    ? const Color(0xFF1C202C)
                    : AppColors.accent.withOpacity(0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: item.isRead
                      ? Colors.white12
                      : AppColors.accent.withOpacity(0.6),
                  width: 1,
                ),
              ),
              child: Icon(
                item.icon,
                color: item.isRead ? Colors.white70 : AppColors.accent,
                size: 22,
              ),
            ),

            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: item.isRead
                                ? FontWeight.w700
                                : FontWeight.w900,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            item.time,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 11,
                            ),
                          ),
                          if (!item.isRead) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                  if (item.linkedMovie != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.play_circle_fill_rounded,
                            size: 14, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text(
                          'Stream "${item.linkedMovie!.title}"',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

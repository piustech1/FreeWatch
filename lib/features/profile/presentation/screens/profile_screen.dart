import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconly/iconly.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/mock/mock_movies.dart';
import '../../../../data/models/avatar_item.dart';
import '../../../../data/models/movie.dart';
import '../../../auth/presentation/providers/user_avatar_provider.dart';
import '../../../auth/presentation/screens/choose_avatar_screen.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../../home/providers/home_providers.dart';
import '../../../movie_detail/presentation/screens/movie_detail_screen.dart';
import '../../../movie_grid/presentation/screens/movie_grid_screen.dart';
import '../providers/user_profile_provider.dart';
import '../providers/watch_history_provider.dart';

/// Dedicated Profile Screen matching reference design (media_1791102724286.png)
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _streamingQuality = 'Auto (Up to 4K)';
  String _audioLanguage = 'Luganda (VJ Dubbed)';
  bool _wifiOnlyDownload = true;
  bool _pushNotifications = true;
  int _cacheSizeMb = 142;

  @override
  Widget build(BuildContext context) {
    final avatar = ref.watch(userAvatarProvider);
    final profile = ref.watch(userProfileProvider);
    final watchHistory = ref.watch(watchHistoryProvider);
    final favorites = ref.watch(favoritesProvider);

    // Provide 3 fallback movies for Saved Movies if favorites is empty
    final savedMovies = favorites.isNotEmpty
        ? favorites
        : [
            MockData.trendingMovies[1],
            MockData.trendingMovies[2],
            if (MockData.trendingMovies.length > 3) MockData.trendingMovies[3],
          ];

    return Scaffold(
      backgroundColor: const Color(0xFF161822),
      body: SafeArea(
        top: true,
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            // ── Top Navigation Bar (< Chevron) ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => navigateToBottomNavTab(context, ref, 0),
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),

            // ── User Identity & Stats Header ────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Circular Avatar with lavender disc
                  GestureDetector(
                    onTap: () => _openAvatarPicker(context),
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: const BoxDecoration(
                        color: Color(0xFFC4B5FD), // Soft lavender from reference
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x33C4B5FD),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Center(
                          child: avatar.assetPath != AvatarItem.defaultAvatar.assetPath
                              ? Image.asset(
                                  avatar.assetPath,
                                  width: 88,
                                  height: 88,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(
                                  Icons.person_rounded,
                                  size: 60,
                                  color: Color(0xFF1E1F2E),
                                ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 24),

                  // Right Metadata Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Name
                        Text(
                          profile.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Movies Watched Label & Count
                        const Text(
                          'Movies Watched',
                          style: TextStyle(
                            color: Color(0xFF8E92A4),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 1.5),
                        Text(
                          '${profile.moviesWatched}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Average Rating Label & Value
                        const Text(
                          'Average Rating',
                          style: TextStyle(
                            color: Color(0xFF8E92A4),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 1.5),
                        Text(
                          '${profile.averageRating}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ── Social Counters & Action Icons Row ──────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 0, 24, 18),
              child: Row(
                children: [
                  // Following
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Following',
                        style: TextStyle(
                          color: Color(0xFF8E92A4),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${profile.followingCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 22),

                  // Followers
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Followers',
                        style: TextStyle(
                          color: Color(0xFF8E92A4),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${profile.followersCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Action Icons: Edit, Share, Settings
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeaderActionButton(
                        icon: Icons.edit_outlined,
                        tooltip: 'Edit Profile',
                        onTap: () => _showEditProfileDialog(context, profile.name),
                      ),
                      const SizedBox(width: 14),
                      _buildHeaderActionButton(
                        icon: Icons.file_upload_outlined,
                        tooltip: 'Share Profile',
                        onTap: () => _shareProfile(context, profile.name),
                      ),
                      const SizedBox(width: 14),
                      _buildHeaderActionButton(
                        icon: Icons.settings_outlined,
                        tooltip: 'Settings',
                        onTap: () => _openSettingsModal(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Thin Divider ────────────────────────────────────────────
            Divider(
              height: 1,
              thickness: 0.8,
              color: Colors.white.withOpacity(0.08),
            ),

            const SizedBox(height: 18),

            // ── WATCH HISTORY ───────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'WATCH HISTORY',
                style: TextStyle(
                  color: Color(0xFF9EA3B2),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  for (int i = 0; i < 3 && i < watchHistory.length; i++) ...[
                    Expanded(
                      child: _buildSmallMovieCard(watchHistory[i]),
                    ),
                    const SizedBox(width: 10),
                  ],
                  _buildMorePillButton(
                    onTap: () {
                      Navigator.of(context).push(
                        MovieGridScreen.routeForCategory(
                          title: 'Watch History',
                          movies: watchHistory,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Thin Divider ────────────────────────────────────────────
            Divider(
              height: 1,
              thickness: 0.8,
              color: Colors.white.withOpacity(0.08),
            ),

            const SizedBox(height: 18),

            // ── SAVED MOVIES ────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'SAVED MOVIES',
                style: TextStyle(
                  color: Color(0xFF9EA3B2),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  for (int i = 0; i < 3 && i < savedMovies.length; i++) ...[
                    Expanded(
                      child: _buildSmallMovieCard(savedMovies[i]),
                    ),
                    const SizedBox(width: 10),
                  ],
                  _buildMorePillButton(
                    onTap: () => navigateToBottomNavTab(context, ref, 2),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Thin Divider ────────────────────────────────────────────
            Divider(
              height: 1,
              thickness: 0.8,
              color: Colors.white.withOpacity(0.08),
            ),

            const SizedBox(height: 20),

            // ── Preferences & Account Settings Section ──────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PLAYBACK & SETTINGS',
                    style: TextStyle(
                      color: Color(0xFF9EA3B2),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSectionContainer([
                    _buildSettingTile(
                      icon: Icons.high_quality_rounded,
                      title: 'Streaming Quality',
                      subtitle: _streamingQuality,
                      onTap: _showQualityPicker,
                    ),
                    _buildDivider(),
                    _buildSettingTile(
                      icon: Icons.record_voice_over_rounded,
                      title: 'Default Translation Audio',
                      subtitle: _audioLanguage,
                      onTap: _showAudioPicker,
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      icon: Icons.wifi_rounded,
                      title: 'Download via Wi-Fi only',
                      value: _wifiOnlyDownload,
                      onChanged: (val) => setState(() => _wifiOnlyDownload = val),
                    ),
                    _buildDivider(),
                    _buildSwitchTile(
                      icon: IconlyBold.notification,
                      title: 'Push Notifications',
                      value: _pushNotifications,
                      onChanged: (val) => setState(() => _pushNotifications = val),
                    ),
                    _buildDivider(),
                    _buildSettingTile(
                      icon: Icons.cleaning_services_rounded,
                      title: 'Clear Cache',
                      subtitle: '$_cacheSizeMb MB used',
                      trailing: TextButton(
                        onPressed: _clearCache,
                        child: const Text(
                          'Clear',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      onTap: _clearCache,
                    ),
                    _buildDivider(),
                    _buildSettingTile(
                      icon: Icons.info_outline_rounded,
                      title: 'App Version',
                      subtitle: 'FreeWatch v1.0.22 (Build 23)',
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // Log Out Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _showSignOutDialog,
                      icon: const Icon(IconlyLight.logout,
                          color: Color(0xFFFF5252), size: 18),
                      label: const Text(
                        'Log Out of FreeWatch',
                        style: TextStyle(
                          color: Color(0xFFFF5252),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: const Color(0xFFFF5252).withOpacity(0.4)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header Action Icon Button ─────────────────────────────────────────────
  Widget _buildHeaderActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.06),
          ),
          child: Center(
            child: Icon(
              icon,
              color: Colors.white,
              size: 17,
            ),
          ),
        ),
      ),
    );
  }

  // ── Small Movie Card for Watch History & Saved Movies ──────────────────────
  Widget _buildSmallMovieCard(Movie movie) {
    final posterUrl = movie.posterPath != null && movie.posterPath!.isNotEmpty
        ? (movie.posterPath!.startsWith('http')
            ? movie.posterPath!
            : '${ApiConstants.posterW342}${movie.posterPath}')
        : null;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MovieDetailScreen(movie: movie),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: AspectRatio(
        aspectRatio: 2 / 2.9,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: const Color(0xFF1E2130),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: posterUrl != null
                ? CachedNetworkImage(
                    imageUrl: posterUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: const Color(0xFF1E2130)),
                    errorWidget: (_, __, ___) => Container(
                      color: const Color(0xFF1E2130),
                      child: const Icon(Icons.movie_rounded,
                          color: Colors.white24, size: 20),
                    ),
                  )
                : Container(
                    color: const Color(0xFF1E2130),
                    child: const Icon(Icons.movie_rounded,
                        color: Colors.white24, size: 20),
                  ),
          ),
        ),
      ),
    );
  }

  // ── "More >" Pill Button matching reference ───────────────────────────────
  Widget _buildMorePillButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withOpacity(0.28),
            width: 1,
          ),
          color: Colors.white.withOpacity(0.04),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'More',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 2),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ── Edit Profile Dialog ───────────────────────────────────────────────────
  void _showEditProfileDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1C28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Display Name',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF242738),
                hintText: 'Enter your name',
                hintStyle: const TextStyle(color: Colors.white38),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                ref.read(userProfileProvider.notifier).updateName(newName);
              }
              Navigator.of(dialogCtx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Share Profile Action ──────────────────────────────────────────────────
  void _shareProfile(BuildContext context, String userName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile link for "$userName" copied to clipboard!'),
        backgroundColor: const Color(0xFF8B5CF6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Settings Bottom Sheet ─────────────────────────────────────────────────
  void _openSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181A26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Settings & Preferences',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.high_quality_rounded, color: AppColors.accent),
                title: const Text('Streaming Quality', style: TextStyle(color: Colors.white)),
                subtitle: Text(_streamingQuality, style: const TextStyle(color: Colors.white54)),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _showQualityPicker();
                },
              ),
              ListTile(
                leading: const Icon(Icons.record_voice_over_rounded, color: AppColors.accent),
                title: const Text('Translation Audio', style: TextStyle(color: Colors.white)),
                subtitle: Text(_audioLanguage, style: const TextStyle(color: Colors.white54)),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _showAudioPicker();
                },
              ),
              ListTile(
                leading: const Icon(Icons.cleaning_services_rounded, color: AppColors.accent),
                title: const Text('Clear Cache', style: TextStyle(color: Colors.white)),
                subtitle: Text('$_cacheSizeMb MB used', style: const TextStyle(color: Colors.white54)),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _clearCache();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAvatarPicker(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ChooseAvatarScreen(),
      ),
    );
  }

  Widget _buildSectionContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131620),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 0.8,
      color: Colors.white.withOpacity(0.06),
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.accent, size: 20),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11.5,
              ),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right_rounded,
                  color: Colors.white30, size: 20)
              : null),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppColors.accent, size: 20),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      value: value,
      activeColor: AppColors.accent,
      onChanged: onChanged,
    );
  }

  void _showQualityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181A26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select Streaming Quality',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
            for (final q in ['Auto (Up to 4K)', '1080p Full HD', '720p HD', '480p SD (Data Saver)'])
              ListTile(
                title: Text(q, style: const TextStyle(color: Colors.white)),
                trailing: _streamingQuality == q
                    ? const Icon(Icons.check, color: AppColors.accent)
                    : null,
                onTap: () {
                  setState(() => _streamingQuality = q);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showAudioPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181A26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Default Translation Audio',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
            for (final l in ['Luganda (VJ Dubbed)', 'English (Original Audio)', 'Swahili Translation'])
              ListTile(
                title: Text(l, style: const TextStyle(color: Colors.white)),
                trailing: _audioLanguage == l
                    ? const Icon(Icons.check, color: AppColors.accent)
                    : null,
                onTap: () {
                  setState(() => _audioLanguage = l);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _clearCache() {
    setState(() => _cacheSizeMb = 0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('App cache cleared successfully (0 MB)'),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2130),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log Out',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to log out of FreeWatch on this device?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out of FreeWatch')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

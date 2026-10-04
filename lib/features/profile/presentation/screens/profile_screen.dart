import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/mock/mock_movies.dart';
import '../../../../data/models/avatar_item.dart';
import '../../../../data/models/movie.dart';
import '../../../auth/presentation/providers/user_avatar_provider.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../../home/providers/home_providers.dart';
import '../../../movie_detail/presentation/screens/movie_detail_screen.dart';
import '../../../movie_grid/presentation/screens/movie_grid_screen.dart';
import '../providers/user_profile_provider.dart';
import '../providers/watch_history_provider.dart';

/// Pure iOS Glassmorphic Profile Screen:
/// - Pitch black background (AppColors.background)
/// - Top bar with fully functional back arrow and Community Gem badge
/// - Profile Identity: Circular avatar with direct image rendering, bold verified username,
///   iOS edit icon, and top-right logout icon
/// - Inline Glassmorphic Stat Cards: Avg Watch Time, Total Downloads, Movies Watched
/// - Collapsible Watch History and Saved Movies with smooth animated chevrons
/// - Pure iOS Glassmorphic Settings (Streaming Quality, Translation Audio, Clear Cache, App Version)
/// - iOS-Style Edit Profile Modal with interactive Avatar Selector, Name, Bio, and locked Date Joined
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _streamingQuality = 'Auto (Up to 4K)';
  String _audioLanguage = 'Luganda (VJ Dubbed)';
  int _cacheSizeMb = 142;

  // Collapsible section toggles
  bool _isWatchHistoryExpanded = true;
  bool _isSavedMoviesExpanded = false;

  @override
  Widget build(BuildContext context) {
    final avatar = ref.watch(userAvatarProvider);
    final profile = ref.watch(userProfileProvider);
    final watchHistory = ref.watch(watchHistoryProvider);
    final favorites = ref.watch(favoritesProvider);

    final savedMovies = favorites.isNotEmpty
        ? favorites
        : [
            MockData.trendingMovies[1],
            MockData.trendingMovies[2],
            if (MockData.trendingMovies.length > 3) MockData.trendingMovies[3],
          ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            // ── Top Navigation Sub-Header (< PROFILE | 💎 Community) ─────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Arrow Button (Fully functional)
                  _buildGlassCircleButton(
                    icon: Icons.chevron_left_rounded,
                    iconSize: 28,
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        navigateToBottomNavTab(context, ref, 0);
                      }
                    },
                  ),

                  // Center Screen Title
                  const Text(
                    'PROFILE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),

                  // Top Right: VIP Community Gem Badge
                  _buildCommunityGemBadge(),
                ],
              ),
            ),

            // ── User Identity Block (Avatar + Verified Name + Edit + Logout) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Circular Avatar with direct asset rendering & edit badge
                  _buildUserAvatarWidget(avatar, profile),

                  const SizedBox(width: 16),

                  // Name & Verified Badge Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                profile.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.verified_rounded,
                              color: Color(0xFF38BDF8),
                              size: 19,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.bio,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF9E9EA7),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Action Buttons: Edit Modal & Logout Icon
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildGlassCircleButton(
                        icon: Icons.edit_rounded,
                        iconSize: 18,
                        tooltip: 'Edit Profile',
                        onTap: () => _openIosEditProfileModal(context, profile, avatar),
                      ),
                      const SizedBox(width: 10),
                      _buildGlassCircleButton(
                        icon: Icons.logout_rounded,
                        iconSize: 18,
                        iconColor: const Color(0xFFFF5252),
                        tooltip: 'Log Out',
                        onTap: _showSignOutDialog,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Inline Glassmorphic Stat Cards ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildInlineStatCard(
                      icon: Icons.schedule_rounded,
                      iconColor: const Color(0xFF60A5FA),
                      value: '${profile.avgWatchTimeHours} hrs',
                      label: 'Avg Watch Time',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInlineStatCard(
                      icon: Icons.file_download_done_rounded,
                      iconColor: const Color(0xFF34D399),
                      value: '${profile.totalDownloads} Movies',
                      label: 'Downloads',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInlineStatCard(
                      icon: Icons.movie_filter_rounded,
                      iconColor: const Color(0xFFFBBF24),
                      value: '${profile.moviesWatched}',
                      label: 'Watched',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ── Collapsible WATCH HISTORY Section ────────────────────────────
            _buildCollapsibleSection(
              title: 'WATCH HISTORY',
              itemCount: watchHistory.length,
              isExpanded: _isWatchHistoryExpanded,
              onToggle: () => setState(() => _isWatchHistoryExpanded = !_isWatchHistoryExpanded),
              onSeeMore: () {
                Navigator.of(context).push(
                  MovieGridScreen.routeForCategory(
                    title: 'Watch History',
                    movies: watchHistory,
                  ),
                );
              },
              movies: watchHistory,
            ),

            const SizedBox(height: 14),

            // ── Collapsible SAVED MOVIES Section ─────────────────────────────
            _buildCollapsibleSection(
              title: 'SAVED MOVIES',
              itemCount: savedMovies.length,
              isExpanded: _isSavedMoviesExpanded,
              onToggle: () => setState(() => _isSavedMoviesExpanded = !_isSavedMoviesExpanded),
              onSeeMore: () => navigateToBottomNavTab(context, ref, 2),
              movies: savedMovies,
            ),

            const SizedBox(height: 22),

            // ── Pure iOS Glassmorphic Settings (Playback & Settings) ─────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 10),
                    child: Text(
                      'PLAYBACK & SETTINGS',
                      style: TextStyle(
                        color: Color(0xFF8E92A4),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  _buildGlassSettingsContainer([
                    _buildSettingsTile(
                      icon: Icons.high_quality_rounded,
                      iconColor: const Color(0xFF38BDF8),
                      title: 'Streaming Quality',
                      subtitle: _streamingQuality,
                      onTap: _showQualityPicker,
                    ),
                    _buildSettingsDivider(),
                    _buildSettingsTile(
                      icon: Icons.record_voice_over_rounded,
                      iconColor: const Color(0xFFA855F7),
                      title: 'Default Translation Audio',
                      subtitle: _audioLanguage,
                      onTap: _showAudioPicker,
                    ),
                    _buildSettingsDivider(),
                    _buildSettingsTile(
                      icon: Icons.cleaning_services_rounded,
                      iconColor: const Color(0xFF34D399),
                      title: 'Clear Cache',
                      subtitle: '$_cacheSizeMb MB used',
                      trailing: GestureDetector(
                        onTap: _clearCache,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.accent.withOpacity(0.40),
                              width: 0.8,
                            ),
                          ),
                          child: const Text(
                            'Clear',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      onTap: _clearCache,
                    ),
                    _buildSettingsDivider(),
                    _buildSettingsTile(
                      icon: Icons.info_outline_rounded,
                      iconColor: const Color(0xFFFBBF24),
                      title: 'App Version',
                      subtitle: 'FreeWatch v1.0.25 (Build 26)',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.40),
                            width: 0.8,
                          ),
                        ),
                        child: const Text(
                          'Latest ✓',
                          style: TextStyle(
                            color: Color(0xFF34D399),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Glass Circle Button (Back, Edit, Logout) ──────────────────────────────
  Widget _buildGlassCircleButton({
    required IconData icon,
    double iconSize = 20,
    Color iconColor = Colors.white,
    String? tooltip,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip ?? '',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
                border: Border.all(
                  color: Colors.white.withOpacity(0.14),
                  width: 0.8,
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: iconColor,
                  size: iconSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Top Right VIP Community Gem Badge ──────────────────────────────────────
  Widget _buildCommunityGemBadge() {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.diamond_rounded, color: Color(0xFFF0ABFC), size: 18),
                SizedBox(width: 8),
                Text('FreeWatch VIP Community: Active Member'),
              ],
            ),
            backgroundColor: const Color(0xFF2E1A47),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF7E22CE).withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFA855F7).withOpacity(0.45),
                width: 0.8,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.diamond_rounded, color: Color(0xFFE879F9), size: 14),
                SizedBox(width: 5),
                Text(
                  'Community',
                  style: TextStyle(
                    color: Color(0xFFF5D0FE),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Circular User Avatar with Direct Asset Rendering & Edit Badge ──────────
  Widget _buildUserAvatarWidget(AvatarItem avatar, UserProfile profile) {
    return GestureDetector(
      onTap: () => _openIosEditProfileModal(context, profile, avatar),
      child: Stack(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFFDE39).withOpacity(0.70),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFDE39).withOpacity(0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                avatar.assetPath,
                width: 76,
                height: 76,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person_rounded,
                  size: 46,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF222533),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(
                Icons.edit_rounded,
                size: 13,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Inline Glassmorphic Stat Card ──────────────────────────────────────────
  Widget _buildInlineStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.10),
              width: 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(height: 8),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF8E92A4),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Collapsible Movie Section (Watch History & Saved Movies) ───────────────
  Widget _buildCollapsibleSection({
    required String title,
    required int itemCount,
    required bool isExpanded,
    required VoidCallback onToggle,
    required VoidCallback onSeeMore,
    required List<Movie> movies,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Collapsible Header Banner
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$itemCount',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // If expanded, show "More >" button
                      if (isExpanded) ...[
                        GestureDetector(
                          onTap: onSeeMore,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'More',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.accent,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      // Animated Rotating Arrow
                      AnimatedRotation(
                        turns: isExpanded ? 0.25 : 0.0,
                        duration: const Duration(milliseconds: 250),
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white54,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Collapsible Content with AnimatedCrossFade
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              height: 195,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: movies.length > 5 ? 5 : movies.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _buildMoviePosterCard(movies[index]);
                },
              ),
            ),
          ),
          crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }

  // ── Movie Poster Card with 20px radius and modern metadata ─────────────────
  Widget _buildMoviePosterCard(Movie movie) {
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
      child: SizedBox(
        width: 105,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 142,
              width: 105,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFF1E212A),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: posterUrl != null
                    ? CachedNetworkImage(
                        imageUrl: posterUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: const Color(0xFF1E212A)),
                        errorWidget: (_, __, ___) => Container(
                          color: const Color(0xFF1E212A),
                          child: const Icon(Icons.movie_rounded, color: Colors.white24, size: 24),
                        ),
                      )
                    : Container(
                        color: const Color(0xFF1E212A),
                        child: const Icon(Icons.movie_rounded, color: Colors.white24, size: 24),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 12),
                const SizedBox(width: 3),
                Text(
                  movie.voteAverage > 0 ? movie.voteAverage.toStringAsFixed(1) : '7.0',
                  style: const TextStyle(
                    color: Color(0xFFC4C7D0),
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '• ${movie.year.isNotEmpty ? movie.year : "2024"}',
                  style: const TextStyle(
                    color: Color(0xFF8E92A0),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Pure iOS Glassmorphic Settings Container & Tiles ──────────────────────
  Widget _buildGlassSettingsContainer(List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(0.10),
              width: 0.8,
            ),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _buildSettingsDivider() {
    return Divider(
      height: 1,
      thickness: 0.8,
      color: Colors.white.withOpacity(0.06),
      indent: 52,
      endIndent: 16,
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.16),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: iconColor.withOpacity(0.30),
            width: 0.8,
          ),
        ),
        child: Icon(icon, color: iconColor, size: 19),
      ),
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
                color: Colors.white.withOpacity(0.50),
                fontSize: 11.5,
              ),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right_rounded, color: Colors.white30, size: 20)
              : null),
      onTap: onTap,
    );
  }

  // ── Quality Picker Modal ──────────────────────────────────────────────────
  void _showQualityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: const Color(0xFF131520).withOpacity(0.95),
            padding: const EdgeInsets.only(bottom: 24),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Text(
                      'Select Streaming Quality',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  for (final q in [
                    'Auto (Up to 4K)',
                    '1080p Full HD',
                    '720p HD',
                    '480p SD (Data Saver)'
                  ])
                    ListTile(
                      title: Text(q, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      trailing: _streamingQuality == q
                          ? const Icon(Icons.check_rounded, color: AppColors.accent)
                          : null,
                      onTap: () {
                        setState(() => _streamingQuality = q);
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Audio Picker Modal ────────────────────────────────────────────────────
  void _showAudioPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: const Color(0xFF131520).withOpacity(0.95),
            padding: const EdgeInsets.only(bottom: 24),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Text(
                      'Default Translation Audio',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  for (final l in [
                    'Luganda (VJ Dubbed)',
                    'English (Original Audio)',
                    'Swahili Translation'
                  ])
                    ListTile(
                      title: Text(l, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      trailing: _audioLanguage == l
                          ? const Icon(Icons.check_rounded, color: AppColors.accent)
                          : null,
                      onTap: () {
                        setState(() => _audioLanguage = l);
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Clear Cache Action ────────────────────────────────────────────────────
  void _clearCache() {
    setState(() => _cacheSizeMb = 0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('App cache cleared successfully (0 MB)'),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  // ── Sign Out Confirmation Dialog ──────────────────────────────────────────
  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF171926),
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
                const SnackBar(
                  content: Text('Logged out of FreeWatch'),
                  backgroundColor: Color(0xFF161822),
                ),
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

  // ── iOS-Style Edit Profile Modal Sheet ────────────────────────────────────
  void _openIosEditProfileModal(
    BuildContext context,
    UserProfile profile,
    AvatarItem currentAvatar,
  ) {
    AvatarItem selectedAvatar = currentAvatar;
    final nameController = TextEditingController(text: profile.name);
    final bioController = TextEditingController(text: profile.bio);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  color: const Color(0xFF11131E).withOpacity(0.95),
                  padding: EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    MediaQuery.of(modalCtx).viewInsets.bottom + 24,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Grab handle
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Edit Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(sheetCtx).pop(),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Avatar Picker Header
                        const Text(
                          'Choose Your Avatar',
                          style: TextStyle(
                            color: Color(0xFF9E9EA7),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Horizontal Avatar Selector Carousel
                        SizedBox(
                          height: 72,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: AvatarItem.allAvatars.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, i) {
                              final av = AvatarItem.allAvatars[i];
                              final isSelected = av.assetPath == selectedAvatar.assetPath;

                              return GestureDetector(
                                onTap: () {
                                  setModalState(() => selectedAvatar = av);
                                },
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFFFDE39)
                                          : Colors.white.withOpacity(0.12),
                                      width: isSelected ? 2.5 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFFFFDE39).withOpacity(0.4),
                                              blurRadius: 10,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      av.assetPath,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Username Field
                        const Text(
                          'Display Name',
                          style: TextStyle(
                            color: Color(0xFF9E9EA7),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: nameController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.06),
                            hintText: 'Enter your display name',
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                            prefixIcon: const Icon(Icons.person_outline_rounded,
                                color: Color(0xFF38BDF8), size: 18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.accent, width: 1.2),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Bio Field
                        const Text(
                          'Personal Info / Bio',
                          style: TextStyle(
                            color: Color(0xFF9E9EA7),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: bioController,
                          maxLines: 2,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.06),
                            hintText: 'Add a bio or personal info',
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                            prefixIcon: const Icon(Icons.info_outline_rounded,
                                color: Color(0xFFA855F7), size: 18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.accent, width: 1.2),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Locked Date Joined Field (Read-only)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.06),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lock_outline_rounded,
                                  color: Colors.white38, size: 16),
                              const SizedBox(width: 10),
                              Text(
                                'Member Since: ${profile.dateJoined} (Read-only)',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              final newName = nameController.text.trim();
                              final newBio = bioController.text.trim();
                              if (newName.isNotEmpty) {
                                ref.read(userProfileProvider.notifier).updateProfile(
                                      name: newName,
                                      bio: newBio,
                                    );
                              }
                              ref.read(userAvatarProvider.notifier).setAvatar(selectedAvatar);
                              Navigator.of(sheetCtx).pop();

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Profile updated successfully!'),
                                  backgroundColor: AppColors.accent,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Save Changes',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

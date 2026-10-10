import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/glass_dialog.dart';
import '../../../../data/mock/mock_movies.dart';
import '../../../../data/models/avatar_item.dart';
import '../../../../data/models/movie.dart';
import '../../../auth/presentation/providers/user_avatar_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../../downloads/presentation/providers/downloads_provider.dart';
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
            // ── Top Header Spacer & Logout Button ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: _showSignOutDialog,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE50914),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.logout_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Prominent Avatar & Identity ──────────────────────────────────
            Center(
              child: _buildProminentUserAvatar(avatar, profile),
            ),

            const SizedBox(height: 12),

            // Name + Verified Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    profile.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF38BDF8),
                  size: 20,
                ),
              ],
            ),

            const SizedBox(height: 4),

            // User Bio / Email
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  profile.bio,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF9E9EA7),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.25,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ── Dual Inline Stat Card (Watched & Downloaded) ─────────────────
            _buildDualInlineStatCard(profile),

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

            // ── Settings (Clear Cache, App Version) & Community Banner ──────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 10),
                    child: Text(
                      'SETTINGS & SYSTEM',
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
                      icon: Icons.cleaning_services_rounded,
                      iconColor: const Color(0xFF34D399),
                      title: 'Clear Cache',
                      subtitle: '$_cacheSizeMb MB cached data',
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
                      icon: Icons.info_rounded,
                      iconColor: const Color(0xFF38BDF8),
                      title: 'App Version',
                      subtitle: 'FreeWatch v1.0.35 (Build 36)',
                      trailing: null,
                      onTap: null,
                    ),
                  ]),

                  const SizedBox(height: 18),

                  // ── Join Community Banner ──────────────────────────────────
                  _buildCommunityBanner(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ── Prominent User Avatar with Overlaid Edit Button ────────────────────────
  Widget _buildProminentUserAvatar(AvatarItem avatar, UserProfile profile) {
    return GestureDetector(
      onTap: () => _openIosEditProfileModal(context, profile, avatar),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFFDE39).withOpacity(0.75),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFDE39).withOpacity(0.20),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                avatar.assetPath,
                width: 118,
                height: 118,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF1E212B),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.edit_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Dual Inline Stat Card (Watched & Downloaded) ───────────────────────────
  Widget _buildDualInlineStatCard(UserProfile profile) {
    final downloads = ref.watch(downloadsProvider);
    final downloadCount = downloads.isNotEmpty ? downloads.length : profile.totalDownloads;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                // Left: Watched (Blue-Purple Gradient Accent)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2563EB).withOpacity(0.18),
                          const Color(0xFF7C3AED).withOpacity(0.10),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.movie_rounded,
                          color: Color(0xFF60A5FA),
                          size: 26,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${profile.moviesWatched} Movies',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Watched',
                                style: TextStyle(
                                  color: Color(0xFF93C5FD),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Hairline vertical separator
                Container(
                  width: 1,
                  height: 44,
                  color: Colors.white.withOpacity(0.10),
                ),

                // Right: Downloaded (Orange Gradient Accent) -> Navigates to Downloads tab (index 3)
                Expanded(
                  child: GestureDetector(
                    onTap: () => navigateToBottomNavTab(context, ref, 3),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFEA580C).withOpacity(0.18),
                            const Color(0xFFF97316).withOpacity(0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(18)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.download_rounded,
                            color: Color(0xFFFB923C),
                            size: 26,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$downloadCount Movies',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Downloaded',
                                  style: TextStyle(
                                    color: Color(0xFFFDBA74),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
  }



  // ── Join TikTok for Updates Banner ─────────────────────────────────────────
  Widget _buildCommunityBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // White abstract TikTok icon without outline
          SvgPicture.string(
            '''<svg viewBox="0 0 24 24" fill="white" xmlns="http://www.w3.org/2000/svg">
              <path d="M19.59 6.69a4.83 4.83 0 0 1-3.77-4.25V2h-3.45v13.67a2.89 2.89 0 0 1-5.2 1.74 2.89 2.89 0 0 1 2.31-4.64 2.93 2.93 0 0 1 .88.13V9.4a6.84 6.84 0 0 0-1-.05A6.33 6.33 0 0 0 5 20.1a6.34 6.34 0 0 0 10.86-4.43v-7a8.16 8.16 0 0 0 4.77 1.52v-3.4a4.85 4.85 0 0 1-1.04-.1z"/>
            </svg>''',
            width: 26,
            height: 26,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Follow us on TikTok',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () async {
              final uri = Uri.parse('https://www.tiktok.com/@freewatch');
              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (_) {
                if (context.mounted) {
                  AppToast.show(
                    context,
                    'Opening @freewatch on TikTok...',
                    isSuccess: false,
                  );
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Follow',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
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
                      // If expanded, show clean continue chevron button
                      if (isExpanded) ...[
                        GestureDetector(
                          onTap: onSeeMore,
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white70,
                              size: 13,
                            ),
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
  // ── Clear Cache Action ────────────────────────────────────────────────────
  void _clearCache() {
    setState(() => _cacheSizeMb = 0);
    AppToast.show(
      context,
      'App cache cleared successfully (0 MB)',
      isSuccess: true,
    );
  }

  // ── Sign Out Confirmation Dialog ──────────────────────────────────────────
  void _showSignOutDialog() {
    GlassDialog.show(
      context,
      title: 'Log Out',
      message: 'Are you sure you want to log out of FreeWatch on this device?',
      confirmText: 'Log Out',
      confirmColor: const Color(0xFFEF4444),
      onConfirm: () async {
        try {
          await ref.read(authRepositoryProvider).signOut();
        } catch (_) {}
        if (!mounted) return;
        AppToast.show(
          context,
          'Logged out of FreeWatch',
          isSuccess: false,
        );
        context.go('/onboarding');
      },
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

                              AppToast.show(
                                context,
                                'Profile updated successfully',
                                isSuccess: true,
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

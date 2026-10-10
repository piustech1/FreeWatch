import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/mock/mock_movies.dart';
import '../../../../data/models/movie.dart';
import '../../../../data/models/movie_details_data.dart';
import '../../../../data/models/vj.dart';
import '../../../../data/repositories/movie_repository.dart';
import '../../../downloads/presentation/providers/downloads_provider.dart';
import '../../../home/widgets/floating_nav_bar.dart';
import '../../../../shared/widgets/free_watch_top_app_bar.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../../home/providers/home_providers.dart';
import '../../../movie_grid/presentation/screens/movie_grid_screen.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../profile/presentation/providers/watch_history_provider.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../providers/movie_detail_providers.dart';

/// Premium iOS Glassmorphic Movie Details Screen:
/// - Persistent FreeWatch Top App Bar & Floating Bottom Navigation Pill
/// - Extended backdrop poster running from below top app bar down towards the cast
/// - Top action row: Glass back button (left) and glass star rating badge (right, replacing 3-dots, no /10)
/// - Movie logo / title with compact translucent VJ badge (circular avatar + purple text fill)
/// - Pure iOS glassmorphic metadata pills (no harsh gray/green outlines)
/// - Rectangular green play button with curved corner radius and white triangular play icon
/// - Cast section with real TMDB circular avatars (No "See all" button)
/// - Collapsible synopsis enclosed in a thin transparent glassmorphic card
/// - Full skeleton shimmer loading state (MovieDetailShimmer)
class MovieDetailScreen extends ConsumerStatefulWidget {
  final Movie movie;
  final double? resumeProgress;
  final bool autoPlay;

  const MovieDetailScreen({
    super.key,
    required this.movie,
    this.resumeProgress,
    this.autoPlay = false,
  });

  @override
  ConsumerState<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends ConsumerState<MovieDetailScreen> {
  bool _isSynopsisExpanded = false;
  int _selectedSeason = 1;
  double _watchlistScale = 1.0;
  double _downloadScale = 1.0;

  VideoPlayerController? _videoPlayerController;
  bool _isPlayingVideo = false;
  bool _isInitializingVideo = false;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoPlay || widget.resumeProgress != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _playTrailer();
      });
    }
  }

  @override
  void dispose() {
    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Vj _resolveAssignedVj(String? rawName) {
    if (rawName == null || rawName.trim().isEmpty) {
      return MockData.vjs.first;
    }
    final norm = MovieRepository.normalizeVjName(rawName);
    return MockData.vjs.firstWhere(
      (v) => MovieRepository.normalizeVjName(v.name) == norm,
      orElse: () => Vj(
        id: norm.toLowerCase().replaceAll(' ', '_'),
        name: rawName.toUpperCase().startsWith('VJ ')
            ? rawName.toUpperCase()
            : 'VJ ${rawName.toUpperCase()}',
        nickname: rawName,
        specialty: 'Luganda Dubbing',
        imageUrl: 'assets/vjs/vj_junior.png',
        movieCount: 0,
        translatedMovieIds: const [],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  bool _checkIsSeries(Movie movie, MovieDetailsData details) {
    if (details.isTv || details.numberOfSeasons > 0 || movie.isTv) return true;
    final title = (details.title.isNotEmpty ? details.title : movie.title).toLowerCase();
    return title.contains('gentlemen') ||
        title.contains('house of the dragon') ||
        title.contains('loki') ||
        title.contains('stranger things') ||
        title.contains('breaking bad') ||
        title.contains('squid game') ||
        title.contains('wednesday') ||
        title.contains('money heist') ||
        title.contains('boys') ||
        title.contains('series') ||
        movie.genreIds.contains(10759) ||
        movie.genreIds.contains(10765) ||
        details.primaryGenre.toLowerCase().contains('tv') ||
        details.primaryGenre.toLowerCase().contains('series');
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullscreen) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            _toggleFullscreen();
          }
        },
        child: _buildLandscapeFullscreenPlayer(),
      );
    }

    final movie = widget.movie;
    final isFav = ref.watch(favoritesProvider.notifier).isFavorite(movie.id);

    // Watch live details from TMDB with append_to_response
    final detailsAsync = ref.watch(
      movieDetailsProvider(MovieDetailsParam(movieId: movie.id, isTv: movie.isTv)),
    );

    // Strictly resolve official TMDB movie backdrop (never stretch vertical posters or use random fallbacks)
    final officialBackdropPath = detailsAsync.valueOrNull?.backdropPath ?? movie.backdropPath;
    final backdropUrl = officialBackdropPath != null && officialBackdropPath.isNotEmpty
        ? (officialBackdropPath.startsWith('http')
            ? officialBackdropPath
            : '${ApiConstants.backdropW1280}$officialBackdropPath')
        : null;

    final rawVjName = movie.vjName ?? detailsAsync.valueOrNull?.vjName;
    final Vj assignedVj = _resolveAssignedVj(rawVjName);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // ── 1. Persistent Top Header / App Bar ───────────────────────
                FreeWatchTopAppBar(
                  onSearchTap: () => Navigator.pop(context),
                  onNotificationTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                  onProfileTap: () => navigateToBottomNavTab(context, ref, 4),
                ),

                // ── 2. Scrollable Movie Details Content ─────────────────────
                Expanded(
                  child: detailsAsync.when(
                    data: (details) {
                      final isSeries = _checkIsSeries(movie, details);
                      return CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          // Extended Backdrop Hero with Logo/Title, Rating, VJ, and King Action Row
                          SliverToBoxAdapter(
                            child: _buildExtendedBackdropHero(
                              backdropUrl: backdropUrl,
                              details: details,
                              assignedVj: assignedVj,
                              isSeries: isSeries,
                              isFav: isFav,
                            ),
                          ),

                          // Lower Body: Seasons/Episodes (if series), Cast, Glass Synopsis Card, Related
                          SliverToBoxAdapter(
                            child: _buildMovieDetailsLowerBody(
                              details: details,
                              isFav: isFav,
                              isSeries: isSeries,
                              backdropUrl: backdropUrl,
                              assignedVj: assignedVj,
                            ),
                          ),

                          // Bottom spacing for floating navigation pill
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 30),
                          ),
                        ],
                      );
                    },
                    loading: () => const MovieDetailShimmer(),
                    error: (_, __) => _buildFallbackScrollView(
                      movie: movie,
                      backdropUrl: backdropUrl,
                      assignedVj: assignedVj,
                      isFav: isFav,
                    ),
                  ),
                ),
              ],
            ),

            // ── 3. Floating Bottom Navigation Pill ──────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingNavBar(
                selectedIndex: ref.watch(bottomNavIndexProvider),
                onItemSelected: (index) {
                  navigateToBottomNavTab(context, ref, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Extended Backdrop Hero Section ─────────────────────────────────────────
  // Runs from below the top app bar down towards the cast, with center play button,
  // logo/title, series metadata / VJ mic capsule, and King Action Row sitting directly on top.
  Widget _buildExtendedBackdropHero({
    required String? backdropUrl,
    required MovieDetailsData details,
    required Vj assignedVj,
    required bool isSeries,
    required bool isFav,
  }) {
    if (_isPlayingVideo && _videoPlayerController != null && _videoPlayerController!.value.isInitialized) {
      return _buildEdgeToEdgeHeroPlayer(
        details: details,
        assignedVj: assignedVj,
        isSeries: isSeries,
        isFav: isFav,
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          // 1. Backdrop image filling background and fading seamlessly into cast
          Positioned.fill(
            child: Stack(
              fit: StackFit.expand,
              children: [
                backdropUrl != null
                    ? CachedNetworkImage(
                        imageUrl: backdropUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        placeholder: (_, __) => Shimmer.fromColors(
                          baseColor: const Color(0xFF141722),
                          highlightColor: const Color(0xFF222838),
                          child: Container(color: const Color(0xFF141722)),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: const Color(0xFF141722),
                          child: const Icon(Icons.movie_rounded,
                              size: 50, color: Colors.white24),
                        ),
                      )
                    : Container(
                        color: const Color(0xFF141722),
                        child: const Icon(Icons.movie_rounded,
                            size: 50, color: Colors.white24),
                      ),

                // Ambient gradient overlay for text readability & smooth blend into cast
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.65),
                        Colors.black.withOpacity(0.10),
                        Colors.black.withOpacity(0.45),
                        AppColors.background.withOpacity(0.90),
                        AppColors.background,
                      ],
                      stops: const [0.0, 0.28, 0.65, 0.90, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Foreground content sitting on top of the backdrop
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Action Row: Back button (left) and Rating badge (right, replacing 3-dots)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTopCircleButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    _buildTopRatingBadge(details.voteAverage),
                  ],
                ),

                // Buffering stream OR Centered circular play button
                SizedBox(
                  height: 210,
                  child: Center(
                    child: _isInitializingVideo
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: Color(0xFF22C55E),
                                strokeWidth: 2.5,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Connecting stream...',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : GestureDetector(
                            onTap: _playTrailer,
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.45),
                                    blurRadius: 14,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.black,
                                size: 34,
                              ),
                            ),
                          ),
                  ),
                ),

                // Release Date in subtle soft gray
                Text(
                  details.formattedReleaseDate,
                  style: const TextStyle(
                    color: Color(0xFF9E9EA7),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 8),

                // Movie/Series Logo or Title with Compact Translucent VJ Badge
                _buildTitleAndVjRow(
                  title: details.title.isNotEmpty ? details.title : widget.movie.title,
                  assignedVj: assignedVj,
                ),
                const SizedBox(height: 14),

                // iOS-Style Glassmorphic Metadata Pills
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildIosMetadataPill(
                      isSeries
                          ? (details.numberOfSeasons > 0
                              ? '${details.numberOfSeasons} ${details.numberOfSeasons == 1 ? "Season" : "Seasons"}'
                              : 'Series')
                          : details.formattedRuntime,
                    ),
                    _buildIosMetadataPill(details.primaryGenre),
                    _buildIosMetadataPill(isSeries ? 'TV Series' : 'Movie'),
                    _buildIosMetadataPill(details.certification),
                  ],
                ),

                const SizedBox(height: 18),

                // King Action Row: Wide White Play/Resume button + Add to Watchlist (+) + Download (⬇)
                _buildKingActionRow(isSeries: isSeries, isFav: isFav),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Rating Badge (Replaces 3-dots, no /10, gold star icon) ───────────────
  Widget _buildTopRatingBadge(double voteAverage) {
    final ratingDisplay = voteAverage > 0 ? voteAverage.toStringAsFixed(1) : '7.9';

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.38),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFFFB800),
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                ratingDisplay,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top Circle Button (Back arrow) ─────────────────────────────────────────
  Widget _buildTopCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.38),
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
                width: 0.8,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  // ── Movie Logo & Compact Translucent VJ Card Row ───────────────────────────
  Widget _buildTitleAndVjRow({
    required String title,
    required Vj assignedVj,
  }) {
    final logoAsync = ref.watch(movieLogoProvider(widget.movie.id));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left: Movie Logo (or stylized text title)
        Expanded(
          child: logoAsync.when(
            data: (logoUrl) {
              if (logoUrl != null && logoUrl.isNotEmpty) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    height: 38,
                    child: CachedNetworkImage(
                      imageUrl: logoUrl,
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                      placeholder: (_, __) => const SizedBox(height: 38, width: 140),
                      errorWidget: (_, __, ___) => _buildTextTitle(title),
                    ),
                  ),
                );
              }
              return _buildTextTitle(title);
            },
            loading: () => const SizedBox(height: 38, width: 140),
            error: (_, __) => _buildTextTitle(title),
          ),
        ),

        const SizedBox(width: 10),

        // Right: Compact Translucent VJ Badge (circular avatar + purple text fill)
        _buildCompactVjBadge(assignedVj),
      ],
    );
  }

  Widget _buildTextTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.3,
          height: 1.15,
        ),
      ),
    );
  }

  // ── Compact Translucent VJ Badge ───────────────────────────────────────────
  Widget _buildCompactVjBadge(Vj assignedVj) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MovieGridScreen.routeForVj(vj: assignedVj),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.35),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFA78BFA).withOpacity(0.40),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.20),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Circular profile avatar
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF221834),
                  ),
                  child: ClipOval(
                    child: assignedVj.imageUrl.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: assignedVj.imageUrl,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            assignedVj.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.record_voice_over_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  assignedVj.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Pure iOS Glassmorphic Metadata Pill ───────────────────────────────────
  Widget _buildIosMetadataPill(String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.14),
              width: 0.8,
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ── Red VJ Mic Capsule (as in reference image) ─────────────────────────────
  Widget _buildVjMicCapsule(Vj assignedVj) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MovieGridScreen.routeForVj(vj: assignedVj),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFE50914).withOpacity(0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE50914).withOpacity(0.50),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.mic_rounded,
              color: Color(0xFFE50914),
              size: 14,
            ),
            const SizedBox(width: 5),
            Text(
              'VJ ${assignedVj.name.replaceAll('VJ ', '').replaceAll('Vj ', '')}',
              style: const TextStyle(
                color: Color(0xFFFF5252),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── King Action Row: Vibrant Green Play Button + Solid Favorites & Downloads ─
  Widget _buildKingActionRow({
    required bool isSeries,
    required bool isFav,
  }) {
    final movie = widget.movie;
    final isDownloaded = ref.watch(downloadsProvider.notifier).isDownloaded(movie.id);

    final bool isCurrentlyPlaying = _isPlayingVideo && _videoPlayerController?.value.isPlaying == true;
    final String playLabel = _isPlayingVideo
        ? (isCurrentlyPlaying ? 'PAUSE' : 'PLAY')
        : (widget.resumeProgress != null
            ? 'RESUME (${(widget.resumeProgress! * 100).toInt()}%)'
            : (isSeries ? 'RESUME' : 'PLAY'));

    return Row(
      children: [
        // Main Vibrant Green Pill Play / Resume Button
        Expanded(
          child: GestureDetector(
            onTap: _playTrailer,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF22C55E).withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isCurrentlyPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    playLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Add to Watchlist / Favorites Button with AnimatedScale click bounce
        AnimatedScale(
          scale: _watchlistScale,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeInOut,
          child: GestureDetector(
            onTap: () async {
              setState(() => _watchlistScale = 0.82);
              await Future.delayed(const Duration(milliseconds: 140));
              if (mounted) setState(() => _watchlistScale = 1.0);

              ref.read(favoritesProvider.notifier).toggleFavorite(movie);
              if (mounted) {
                AppToast.show(
                  context,
                  !isFav ? 'Added "${movie.title}" to Watchlist' : 'Removed from Watchlist',
                  isSuccess: !isFav,
                );
              }
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF1E212B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isFav
                      ? AppColors.accent.withOpacity(0.70)
                      : Colors.white.withOpacity(0.16),
                  width: 1.2,
                ),
              ),
              child: Icon(
                isFav ? Icons.bookmark_added_rounded : Icons.bookmark_add_rounded,
                color: isFav ? AppColors.accent : Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Download Button with AnimatedScale click bounce and persistent downloadsProvider storage
        AnimatedScale(
          scale: _downloadScale,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeInOut,
          child: GestureDetector(
            onTap: _downloadMovie,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF1E212B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDownloaded
                      ? const Color(0xFF22C55E).withOpacity(0.60)
                      : Colors.white.withOpacity(0.16),
                  width: 1.2,
                ),
              ),
              child: Icon(
                isDownloaded ? Icons.file_download_done_rounded : Icons.download_rounded,
                color: isDownloaded ? const Color(0xFF22C55E) : Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Lower Body: Seasons/Episodes (if series), Cast, Glass Synopsis Card, Related
  Widget _buildMovieDetailsLowerBody({
    required MovieDetailsData details,
    required bool isFav,
    required bool isSeries,
    required String? backdropUrl,
    required Vj assignedVj,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // If Series: SEASONS and EPISODES first right below the King Action Row!
          if (isSeries) ...[
            const SizedBox(height: 10),
            _buildSeasonsSection(details),
            const SizedBox(height: 22),
            _buildEpisodesSection(backdropUrl, assignedVj),
            const SizedBox(height: 24),
          ],
          // 1. Cast Section (Live TMDB credits, circular & compact, NO "See all")
          if (details.cast.isNotEmpty) ...[
            const Text(
              'Cast',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            _buildCircularCastList(details.cast),
            const SizedBox(height: 22),
          ],

          // 2. Synopsis Section in Thin Transparent Glassmorphic Card
          const Text(
            'Synopsis',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          _buildCollapsibleSynopsis(
            details.overview.isNotEmpty ? details.overview : widget.movie.overview ?? '',
          ),

          // 3. Related Movies / More Like This Section (Horizontal Carousel)
          if (details.relatedMovies.isNotEmpty) ...[
            const SizedBox(height: 26),
            Text(
              (details.isTv || widget.movie.isTv) ? 'More Like This' : 'Related Movies',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            _buildRelatedMoviesList(details.relatedMovies),
          ],
        ],
      ),
    );
  }

  // ── Seasons Section ────────────────────────────────────────────────────────
  Widget _buildSeasonsSection([MovieDetailsData? details]) {
    List<int> seasonNumbers;
    if (details != null && details.seasons.isNotEmpty) {
      seasonNumbers = details.seasons.map((s) => s.seasonNumber).toList();
    } else if (details != null && details.numberOfSeasons > 0) {
      seasonNumbers = List.generate(details.numberOfSeasons, (i) => i + 1);
    } else {
      seasonNumbers = [1, 2, 3];
    }

    if (!seasonNumbers.contains(_selectedSeason) && seasonNumbers.isNotEmpty) {
      _selectedSeason = seasonNumbers.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SEASONS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: seasonNumbers.map((season) {
              final isSelected = _selectedSeason == season;
              return GestureDetector(
                onTap: () => setState(() => _selectedSeason = season),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFE50914)
                        : const Color(0xFF161822),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFE50914)
                          : Colors.white.withOpacity(0.20),
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFE50914).withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        'Season $season',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Episodes Section with Real TMDB Still Backdrops ────────────────────────
  Widget _buildEpisodesSection(
    String? backdropUrl,
    Vj assignedVj,
  ) {
    final episodesAsync = ref.watch(
      tvSeasonEpisodesProvider(
        TvSeasonParam(tvId: widget.movie.id, seasonNumber: _selectedSeason),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'EPISODES',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 178,
          child: episodesAsync.when(
            data: (episodes) {
              if (episodes.isEmpty) {
                return Center(
                  child: Text(
                    'No episodes available for Season $_selectedSeason',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: episodes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final ep = episodes[index];
                  final String? epImageUrl = ep.stillUrl ?? backdropUrl;

                  return GestureDetector(
                    onTap: () => _playEpisode(
                      context,
                      ep.name,
                      'EP ${ep.episodeNumber}',
                      assignedVj,
                      episodeVideoUrl: ep.videoUrl,
                    ),
                    child: SizedBox(
                      width: 195,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 16:9 Episode Thumbnail with real TMDB backdrop
                          Container(
                            height: 114,
                            width: 195,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
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
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  epImageUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: epImageUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Shimmer.fromColors(
                                            baseColor: const Color(0xFF1E212A),
                                            highlightColor: const Color(0xFF2C3240),
                                            child: Container(color: const Color(0xFF1E212A)),
                                          ),
                                          errorWidget: (_, __, ___) => Container(
                                            color: const Color(0xFF141722),
                                            child: const Icon(
                                              Icons.movie_rounded,
                                              color: Colors.white24,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: const Color(0xFF141722),
                                          child: const Icon(
                                            Icons.movie_rounded,
                                            color: Colors.white24,
                                          ),
                                        ),
                                  // Subtle vignette
                                  Container(
                                    color: Colors.black.withOpacity(0.28),
                                  ),
                                  // Centered circular white play button
                                  Center(
                                    child: Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.92),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.black,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                  // EP X Badge at bottom-right
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.70),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'EP ${ep.episodeNumber}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Episode Title
                          Text(
                            ep.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Duration
                          Text(
                            ep.formattedRuntime,
                            style: const TextStyle(
                              color: Color(0xFF8E92A0),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, __) => Shimmer.fromColors(
                baseColor: const Color(0xFF1E212A),
                highlightColor: const Color(0xFF2C3240),
                child: Container(
                  width: 195,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E212A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            error: (_, __) => Center(
              child: Text(
                'Episodes will load when streaming begins',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _playEpisode(BuildContext context, String title, String ep, Vj assignedVj, {String? episodeVideoUrl}) {
    AppToast.show(
      context,
      'Streaming Season $_selectedSeason $ep: "$title" translated by ${assignedVj.name}',
      isSuccess: true,
    );
    _playTrailer(streamUrl: episodeVideoUrl);
  }

  Future<void> _downloadMovie() async {
    setState(() => _downloadScale = 0.82);
    await Future.delayed(const Duration(milliseconds: 140));
    if (mounted) setState(() => _downloadScale = 1.0);

    final downloadsNotifier = ref.read(downloadsProvider.notifier);
    final alreadyDownloaded = downloadsNotifier.isDownloaded(widget.movie.id);
    final isDownloading = downloadsNotifier.isDownloading(widget.movie.id);

    if (alreadyDownloaded) {
      if (!mounted) return;
      AppToast.show(
        context,
        '"${widget.movie.title}" is already downloaded',
        isSuccess: true,
      );
      return;
    }

    if (isDownloading) {
      if (!mounted) return;
      AppToast.show(
        context,
        'Download is already in progress',
        isSuccess: true,
      );
      return;
    }

    final rawVjName = widget.movie.vjName;
    final Vj assignedVj = _resolveAssignedVj(rawVjName);

    await downloadsNotifier.startDownload(widget.movie, vjName: assignedVj.name);

    if (!mounted) return;
    AppToast.show(
      context,
      'Downloading "${widget.movie.title}" (1080p)',
      isSuccess: true,
    );
  }

  // ── Compact Circular Cast List (Live TMDB credits) ─────────────────────────
  Widget _buildCircularCastList(List<CastMember> cast) {
    if (cast.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: cast.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final member = cast[i];
          final photoUrl = member.photoUrl;

          return SizedBox(
            width: 64,
            child: Column(
              children: [
                // Circular Cast Avatar
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1E212A),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: photoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: photoUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Shimmer.fromColors(
                              baseColor: const Color(0xFF141722),
                              highlightColor: const Color(0xFF222838),
                              child: Container(color: const Color(0xFF141722)),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: const Color(0xFF1E212A),
                              child: const Icon(Icons.person_rounded,
                                  color: Colors.white30, size: 28),
                            ),
                          )
                        : Container(
                            color: const Color(0xFF1E212A),
                            child: const Icon(Icons.person_rounded,
                                color: Colors.white30, size: 28),
                          ),
                  ),
                ),

                const SizedBox(height: 6),

                // Real Name
                Text(
                  member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                // Character Role
                if (member.character != null && member.character!.isNotEmpty)
                  Text(
                    member.character!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF7E8290),
                      fontSize: 9.5,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Collapsible Synopsis in Thin Transparent Glassmorphic Card ─────────────
  Widget _buildCollapsibleSynopsis(String overview) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.10),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedCrossFade(
                firstChild: Text(
                  overview,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFC4C7D0),
                    fontSize: 13.5,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                secondChild: Text(
                  overview,
                  style: const TextStyle(
                    color: Color(0xFFC4C7D0),
                    fontSize: 13.5,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                crossFadeState: _isSynopsisExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => setState(() => _isSynopsisExpanded = !_isSynopsisExpanded),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.14),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isSynopsisExpanded ? 'Show less' : 'Read more',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isSynopsisExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Related Movies Horizontal List ─────────────────────────────────────────
  Widget _buildRelatedMoviesList(List<Movie> relatedMovies) {
    return SizedBox(
      height: 206,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: relatedMovies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final relMovie = relatedMovies[i];
          final posterUrl = relMovie.posterPath != null &&
                  relMovie.posterPath!.isNotEmpty
              ? (relMovie.posterPath!.startsWith('http')
                  ? relMovie.posterPath!
                  : '${ApiConstants.posterW342}${relMovie.posterPath}')
              : null;

          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MovieDetailScreen(movie: relMovie),
                ),
              );
            },
            child: SizedBox(
              width: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 148,
                    width: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xFF1E212A),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          posterUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: posterUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Shimmer.fromColors(
                                    baseColor: const Color(0xFF141722),
                                    highlightColor: const Color(0xFF222838),
                                    child: Container(color: const Color(0xFF141722)),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    color: const Color(0xFF1E212A),
                                    child: const Icon(Icons.movie_rounded,
                                        color: Colors.white24, size: 28),
                                  ),
                                )
                              : Container(
                                  color: const Color(0xFF1E212A),
                                  child: const Icon(Icons.movie_rounded,
                                      color: Colors.white24, size: 28),
                                ),

                          // Rating badge
                          Positioned(
                            top: 6,
                            right: 6,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.45),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.15),
                                      width: 0.6,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          color: Color(0xFFFFB800), size: 11),
                                      const SizedBox(width: 2),
                                      Text(
                                        relMovie.voteAverage > 0
                                            ? relMovie.voteAverage.toStringAsFixed(1)
                                            : '7.0',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    relMovie.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFB800),
                        size: 12,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        relMovie.voteAverage > 0
                            ? relMovie.voteAverage.toStringAsFixed(1)
                            : '7.0',
                        style: const TextStyle(
                          color: Color(0xFFC4C7D0),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '• ${relMovie.year.isNotEmpty ? relMovie.year : "2024"}',
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
        },
      ),
    );
  }

  bool _checkIsSeriesFallback(Movie movie) {
    final title = movie.title.toLowerCase();
    return title.contains('gentlemen') ||
        title.contains('house of the dragon') ||
        title.contains('loki') ||
        title.contains('stranger things') ||
        title.contains('breaking bad') ||
        title.contains('squid game') ||
        title.contains('boys') ||
        title.contains('series') ||
        movie.genreIds.contains(10759) ||
        movie.genreIds.contains(10765);
  }

  // ── Fallback Scroll View for Offline / Error ───────────────────────────────
  Widget _buildFallbackScrollView({
    required Movie movie,
    required String? backdropUrl,
    required Vj assignedVj,
    required bool isFav,
  }) {
    final isSeries = _checkIsSeriesFallback(movie);
    final year = movie.year.isNotEmpty ? movie.year : '2024';

    if (_isPlayingVideo && _videoPlayerController != null && _videoPlayerController!.value.isInitialized) {
      return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildEdgeToEdgeHeroPlayerFallback(
              movie: movie,
              assignedVj: assignedVj,
              isSeries: isSeries,
              isFav: isFav,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isSeries) ...[
                    _buildSeasonsSection(),
                    const SizedBox(height: 20),
                    _buildEpisodesSection(backdropUrl, assignedVj),
                    const SizedBox(height: 24),
                  ],
                  const Text(
                    'Synopsis',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildCollapsibleSynopsis(movie.overview ?? ''),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 30),
          ),
        ],
      );
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      backdropUrl != null
                          ? CachedNetworkImage(
                              imageUrl: backdropUrl,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              placeholder: (_, __) => Container(color: const Color(0xFF141722)),
                              errorWidget: (_, __, ___) => Container(
                                color: const Color(0xFF141722),
                                child: const Icon(Icons.movie_rounded,
                                    size: 50, color: Colors.white24),
                              ),
                            )
                          : Container(
                              color: const Color(0xFF141722),
                              child: const Icon(Icons.movie_rounded,
                                  size: 50, color: Colors.white24),
                            ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.65),
                              Colors.black.withOpacity(0.10),
                              Colors.black.withOpacity(0.45),
                              AppColors.background.withOpacity(0.90),
                              AppColors.background,
                            ],
                            stops: const [0.0, 0.28, 0.65, 0.90, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTopCircleButton(
                            icon: Icons.arrow_back_rounded,
                            onTap: () => Navigator.pop(context),
                          ),
                          _buildTopRatingBadge(movie.voteAverage),
                        ],
                      ),
                      // Backdrop center circular white play button
                      SizedBox(
                        height: 80,
                        child: Center(
                          child: GestureDetector(
                            onTap: _playTrailer,
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.45),
                                    blurRadius: 14,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.black,
                                size: 34,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (isSeries) ...[
                        Text(
                          movie.title.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFFFDE39),
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFB800),
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              movie.voteAverage > 0
                                  ? movie.voteAverage.toStringAsFixed(1)
                                  : '7.9',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '$year • 3 Seasons',
                              style: const TextStyle(
                                color: Color(0xFFC4C7D0),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF222838),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.25),
                                  width: 0.8,
                                ),
                              ),
                              child: const Text(
                                '4K',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildVjMicCapsule(assignedVj),
                      ] else ...[
                        Text(
                          year,
                          style: const TextStyle(
                            color: Color(0xFF9E9EA7),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildTitleAndVjRow(
                          title: movie.title,
                          assignedVj: assignedVj,
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildIosMetadataPill('1h 45min'),
                            _buildIosMetadataPill('Action'),
                            _buildIosMetadataPill('Movie'),
                            _buildIosMetadataPill('PG-13'),
                          ],
                        ),
                      ],
                      const SizedBox(height: 18),
                      _buildKingActionRow(isSeries: isSeries, isFav: isFav),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSeries) ...[
                  _buildSeasonsSection(),
                  const SizedBox(height: 20),
                  _buildEpisodesSection(backdropUrl, assignedVj),
                  const SizedBox(height: 24),
                ],
                const Text(
                  'Synopsis',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                _buildCollapsibleSynopsis(movie.overview ?? ''),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 30),
        ),
      ],
    );
  }

  void _playTrailer({String? streamUrl}) {
    if (streamUrl == null && _isPlayingVideo && _videoPlayerController != null) {
      if (_videoPlayerController!.value.isPlaying) {
        _videoPlayerController!.pause();
      } else {
        _videoPlayerController!.play();
      }
      setState(() {});
      return;
    }

    setState(() {
      _isInitializingVideo = true;
    });

    _videoPlayerController?.dispose();

    final details = ref
        .read(movieDetailsProvider(
            MovieDetailsParam(movieId: widget.movie.id, isTv: widget.movie.isTv)))
        .valueOrNull;

    // Check if offline local download file exists
    final downloaded = ref.read(downloadsProvider.notifier).getDownloadedMovie(widget.movie.id);
    final String? localFilePath = downloaded?.localFilePath;
    final bool hasLocalFile = localFilePath != null && File(localFilePath).existsSync();

    final String resolvedUrl = (streamUrl != null && streamUrl.isNotEmpty)
        ? streamUrl
        : ((details?.videoUrl?.isNotEmpty == true ? details!.videoUrl! : null) ??
           (widget.movie.videoUrl?.isNotEmpty == true ? widget.movie.videoUrl! : null) ??
           'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4');

    final rawVjName = widget.movie.vjName ?? details?.vjName;
    final Vj assignedVj = _resolveAssignedVj(rawVjName);

    // Save to watch history
    ref.read(watchHistoryProvider.notifier).addToHistory(
      widget.movie.copyWith(vjName: assignedVj.name),
    );

    final VideoPlayerController controller = hasLocalFile
        ? VideoPlayerController.file(File(localFilePath))
        : VideoPlayerController.networkUrl(Uri.parse(resolvedUrl));

    _videoPlayerController = controller;

    controller.addListener(() {
      if (!mounted) return;
      if (controller.value.isInitialized) {
        final duration = controller.value.duration;
        final position = controller.value.position;
        if (duration.inSeconds > 0) {
          final progress = (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
          ref.read(watchHistoryProvider.notifier).updateProgress(
            widget.movie.id,
            progress,
            position.inSeconds,
          );
        }
      }
    });

    controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _isInitializingVideo = false;
        _isPlayingVideo = true;
      });
      if (widget.resumeProgress != null && widget.resumeProgress! > 0) {
        final totalMs = controller.value.duration.inMilliseconds;
        final seekMs = (totalMs * widget.resumeProgress!).round();
        controller.seekTo(Duration(milliseconds: seekMs));
      }
      controller.play();
    }).catchError((error) {
      if (!mounted) return;
      setState(() {
        _isInitializingVideo = false;
        _isPlayingVideo = false;
      });
      AppToast.show(context, 'Failed to load video stream', isSuccess: false);
    });
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (_isFullscreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  Widget _buildEdgeToEdgeHeroPlayer({
    required MovieDetailsData details,
    required Vj assignedVj,
    required bool isSeries,
    required bool isFav,
  }) {
    final controller = _videoPlayerController!;
    final screenWidth = MediaQuery.of(context).size.width;
    final playerHeight = screenWidth * 9 / 16;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Seamless Edge-to-Edge Video Player container (0 margin, 0 padding, 0 border, 0 radius)
        Container(
          width: double.infinity,
          height: playerHeight,
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio > 0 ? controller.value.aspectRatio : 16 / 9,
                  child: VideoPlayer(controller),
                ),
              ),

              // Gradient overlays for top and bottom controls
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 60,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withOpacity(0.75), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.85), Colors.transparent],
                    ),
                  ),
                ),
              ),

              // Top Controls Bar (Back, Rating, Fullscreen, Close)
              Positioned(
                top: 10,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTopCircleButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () {
                        controller.pause();
                        Navigator.pop(context);
                      },
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTopRatingBadge(details.voteAverage),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _toggleFullscreen,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.20), width: 0.8),
                            ),
                            child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            controller.pause();
                            setState(() => _isPlayingVideo = false);
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.20), width: 0.8),
                            ),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Center Play/Pause overlay toggle
              Center(
                child: GestureDetector(
                  onTap: () {
                    if (controller.value.isPlaying) {
                      controller.pause();
                    } else {
                      controller.play();
                    }
                    setState(() {});
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.50),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.2),
                    ),
                    child: Icon(
                      controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),

              // Bottom Progress Scrubber with Timestamps
              Positioned(
                bottom: 4,
                left: 12,
                right: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VideoProgressIndicator(
                      controller,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      colors: const VideoProgressColors(
                        playedColor: Color(0xFF22C55E),
                        bufferedColor: Colors.white30,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: ValueListenableBuilder<VideoPlayerValue>(
                        valueListenable: controller,
                        builder: (context, value, _) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(value.position),
                                style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                _formatDuration(value.duration),
                                style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Metadata and King Action Row below edge-to-edge player
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                details.formattedReleaseDate,
                style: const TextStyle(
                  color: Color(0xFF9E9EA7),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              _buildTitleAndVjRow(
                title: details.title.isNotEmpty ? details.title : widget.movie.title,
                assignedVj: assignedVj,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildIosMetadataPill(
                    isSeries
                        ? (details.numberOfSeasons > 0
                            ? '${details.numberOfSeasons} ${details.numberOfSeasons == 1 ? "Season" : "Seasons"}'
                            : 'Series')
                        : details.formattedRuntime,
                  ),
                  _buildIosMetadataPill(details.primaryGenre),
                  _buildIosMetadataPill(isSeries ? 'TV Series' : 'Movie'),
                  _buildIosMetadataPill(details.certification),
                ],
              ),
              const SizedBox(height: 18),
              _buildKingActionRow(isSeries: isSeries, isFav: isFav),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEdgeToEdgeHeroPlayerFallback({
    required Movie movie,
    required Vj assignedVj,
    required bool isSeries,
    required bool isFav,
  }) {
    final controller = _videoPlayerController!;
    final screenWidth = MediaQuery.of(context).size.width;
    final playerHeight = screenWidth * 9 / 16;
    final year = movie.year.isNotEmpty ? movie.year : '2024';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: playerHeight,
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio > 0 ? controller.value.aspectRatio : 16 / 9,
                  child: VideoPlayer(controller),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 60,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withOpacity(0.75), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.85), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTopCircleButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () {
                        controller.pause();
                        Navigator.pop(context);
                      },
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTopRatingBadge(movie.voteAverage),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _toggleFullscreen,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.20), width: 0.8),
                            ),
                            child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            controller.pause();
                            setState(() => _isPlayingVideo = false);
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.20), width: 0.8),
                            ),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Center(
                child: GestureDetector(
                  onTap: () {
                    if (controller.value.isPlaying) {
                      controller.pause();
                    } else {
                      controller.play();
                    }
                    setState(() {});
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.50),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.2),
                    ),
                    child: Icon(
                      controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 4,
                left: 12,
                right: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VideoProgressIndicator(
                      controller,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      colors: const VideoProgressColors(
                        playedColor: Color(0xFF22C55E),
                        bufferedColor: Colors.white30,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: ValueListenableBuilder<VideoPlayerValue>(
                        valueListenable: controller,
                        builder: (context, value, _) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(value.position),
                                style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                _formatDuration(value.duration),
                                style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                year,
                style: const TextStyle(
                  color: Color(0xFF9E9EA7),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _buildTitleAndVjRow(
                title: movie.title,
                assignedVj: assignedVj,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildIosMetadataPill('1h 45min'),
                  _buildIosMetadataPill('Action'),
                  _buildIosMetadataPill(isSeries ? 'TV Series' : 'Movie'),
                  _buildIosMetadataPill('PG-13'),
                ],
              ),
              const SizedBox(height: 18),
              _buildKingActionRow(isSeries: isSeries, isFav: isFav),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeFullscreenPlayer() {
    final controller = _videoPlayerController;
    if (controller == null || !controller.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF22C55E)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),

            // Landscape Controls Overlay
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.25),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Bar
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _toggleFullscreen,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24, width: 0.8),
                            ),
                            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            widget.movie.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E).withOpacity(0.25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF22C55E), width: 0.8),
                          ),
                          child: const Text(
                            '1080p FHD',
                            style: TextStyle(
                              color: Color(0xFF22C55E),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Center Controls: Rewind 10s, Play/Pause, Forward 10s
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 36,
                          icon: const Icon(Icons.replay_10_rounded, color: Colors.white),
                          onPressed: () {
                            final current = controller.value.position;
                            controller.seekTo(current - const Duration(seconds: 10));
                          },
                        ),
                        const SizedBox(width: 32),
                        GestureDetector(
                          onTap: () {
                            if (controller.value.isPlaying) {
                              controller.pause();
                            } else {
                              controller.play();
                            }
                            setState(() {});
                          },
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF22C55E).withOpacity(0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                          ),
                        ),
                        const SizedBox(width: 32),
                        IconButton(
                          iconSize: 36,
                          icon: const Icon(Icons.forward_10_rounded, color: Colors.white),
                          onPressed: () {
                            final current = controller.value.position;
                            controller.seekTo(current + const Duration(seconds: 10));
                          },
                        ),
                      ],
                    ),

                    // Bottom Bar
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VideoProgressIndicator(
                          controller,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Color(0xFF22C55E),
                            bufferedColor: Colors.white30,
                            backgroundColor: Colors.white12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ValueListenableBuilder(
                              valueListenable: controller,
                              builder: (context, VideoPlayerValue value, _) {
                                final pos = value.position;
                                final dur = value.duration;
                                String format(Duration d) =>
                                    '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
                                return Text(
                                  '${format(pos)} / ${format(dur)}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                );
                              },
                            ),
                            GestureDetector(
                              onTap: _toggleFullscreen,
                              child: const Row(
                                children: [
                                  Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 4),
                                  Text(
                                    'Exit Fullscreen',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

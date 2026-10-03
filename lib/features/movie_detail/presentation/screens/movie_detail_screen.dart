import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/mock/mock_movies.dart';
import '../../../../data/models/movie.dart';
import '../../../../data/models/movie_details_data.dart';
import '../../../../data/models/vj.dart';
import '../../../home/widgets/floating_nav_bar.dart';
import '../../../../shared/widgets/free_watch_top_app_bar.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../../home/providers/home_providers.dart';
import '../../../home/widgets/vj_movies_sheet.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
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

  const MovieDetailScreen({
    super.key,
    required this.movie,
  });

  @override
  ConsumerState<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends ConsumerState<MovieDetailScreen> {
  bool _isSynopsisExpanded = false;
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final isFav = ref.watch(favoritesProvider.notifier).isFavorite(movie.id);

    // Watch live details from TMDB with append_to_response
    final detailsAsync = ref.watch(movieDetailsProvider(movie.id));

    // Backdrop URL with fallback
    final backdropUrl = movie.backdropPath != null && movie.backdropPath!.isNotEmpty
        ? (movie.backdropPath!.startsWith('http')
            ? movie.backdropPath!
            : '${ApiConstants.backdropW780}${movie.backdropPath}')
        : (movie.posterPath != null && movie.posterPath!.isNotEmpty
            ? (movie.posterPath!.startsWith('http')
                ? movie.posterPath!
                : '${ApiConstants.posterW500}${movie.posterPath}')
            : null);

    final Vj assignedVj = MockData.vjs.firstWhere(
      (v) => v.translatedMovieIds.contains(movie.id),
      orElse: () => MockData.vjs.first,
    );

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
                ),

                // ── 2. Scrollable Movie Details Content ─────────────────────
                Expanded(
                  child: detailsAsync.when(
                    data: (details) => CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        // Extended Backdrop Hero with Logo, VJ badge, Pills & Green Play Button
                        SliverToBoxAdapter(
                          child: _buildExtendedBackdropHero(
                            backdropUrl: backdropUrl,
                            details: details,
                            assignedVj: assignedVj,
                          ),
                        ),

                        // Lower Body: Cast, Glass Synopsis Card, Related Movies
                        SliverToBoxAdapter(
                          child: _buildMovieDetailsLowerBody(
                            details: details,
                            isFav: isFav,
                          ),
                        ),

                        // Bottom spacing for floating navigation pill
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 110),
                        ),
                      ],
                    ),
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
                selectedIndex: _selectedNavIndex,
                onItemSelected: (index) {
                  setState(() => _selectedNavIndex = index);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Extended Backdrop Hero Section ─────────────────────────────────────────
  // Runs from below the top app bar down towards the cast, with logo, VJ card,
  // metadata pills, and rectangular green play button sitting directly on top.
  Widget _buildExtendedBackdropHero({
    required String? backdropUrl,
    required MovieDetailsData details,
    required Vj assignedVj,
  }) {
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

                // Spacing so backdrop artwork is visible in the middle
                const SizedBox(height: 140),

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

                // Movie Logo / Title with Compact Translucent VJ Badge along it
                _buildTitleAndVjRow(
                  title: details.title,
                  assignedVj: assignedVj,
                ),

                const SizedBox(height: 14),

                // iOS-Style Glassmorphic Metadata Pills
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildIosMetadataPill(details.formattedRuntime),
                    _buildIosMetadataPill(details.primaryGenre),
                    _buildIosMetadataPill('Movie'),
                    _buildIosMetadataPill(details.certification),
                  ],
                ),

                const SizedBox(height: 18),

                // Rectangular Filled Green Play Button with White Triangular Icon
                _buildRectangularPlayButton(),
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
        VjMoviesSheet.show(
          context,
          vj: assignedVj,
          onMovieTap: (m) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MovieDetailScreen(movie: m),
              ),
            );
          },
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

  // ── Rectangular Filled Green Play Button with White Triangular Icon ────────
  Widget _buildRectangularPlayButton() {
    return GestureDetector(
      onTap: () => _playTrailer(context),
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.40),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 30,
            ),
            SizedBox(width: 8),
            Text(
              'Play Movie',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Lower Body: Cast, Glass Synopsis Card, Related Movies ──────────────────
  Widget _buildMovieDetailsLowerBody({
    required MovieDetailsData details,
    required bool isFav,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          // 3. Related Movies Section (Horizontal Carousel)
          if (details.relatedMovies.isNotEmpty) ...[
            const SizedBox(height: 26),
            const Text(
              'Related Movies',
              style: TextStyle(
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
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => setState(() => _isSynopsisExpanded = !_isSynopsisExpanded),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isSynopsisExpanded ? 'Show less' : 'Read more',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isSynopsisExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.accent,
                      size: 18,
                    ),
                  ],
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
      height: 180,
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
                      borderRadius: BorderRadius.circular(14),
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
                      borderRadius: BorderRadius.circular(14),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Fallback Scroll View for Offline / Error ───────────────────────────────
  Widget _buildFallbackScrollView({
    required Movie movie,
    required String? backdropUrl,
    required Vj assignedVj,
    required bool isFav,
  }) {
    final year = movie.year.isNotEmpty ? movie.year : '2025';

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
                      const SizedBox(height: 140),
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
                      const SizedBox(height: 18),
                      _buildRectangularPlayButton(),
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
          child: SizedBox(height: 110),
        ),
      ],
    );
  }

  void _playTrailer(BuildContext context) {
    final Vj assignedVj = MockData.vjs.firstWhere(
      (v) => v.translatedMovieIds.contains(widget.movie.id),
      orElse: () => MockData.vjs.first,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1500),
        backgroundColor: const Color(0xFF161922),
        content: Text(
          'Streaming "${widget.movie.title}" translated by ${assignedVj.name}...',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

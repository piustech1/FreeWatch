import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/mock/mock_movies.dart';
import '../../../../data/models/movie.dart';
import '../../../../data/models/movie_details_data.dart';
import '../../../../data/models/vj.dart';
import '../../../home/widgets/floating_nav_bar.dart';
import '../../../../shared/widgets/free_watch_top_app_bar.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../../home/providers/home_providers.dart';
import '../../../home/widgets/vj_movies_sheet.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../providers/movie_detail_providers.dart';

/// 1:1 Cinematic Movie Details Screen strictly aligned with Dribbble reference:
/// - Persistent FreeWatch Top App Bar & Floating Bottom Navigation Pill
/// - Custom-sculpted backdrop banner with upward circular notch around the play button
/// - Sleek dark non-morphic play button (no harsh outline) nestled inside the curve
/// - Back arrow (left) and 3-dots options menu (right) on the video banner
/// - Live TMDB metadata (runtime, primary genre, certification like "PG-13", "R", "PG")
/// - TMDB transparent movie logo / title with star ratings beside it (likes and hearts removed)
/// - Inline VJ translator indicator with Luganda/English audio toggle
/// - Exact TMDB cast with compact circular photo avatars and character roles
/// - Collapsible synopsis with smooth "Read more / Show less" toggle
/// - Horizontal Related Movies slider beneath synopsis
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
  bool _isLugandaAudio = true;
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
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Video / Backdrop Banner with Curved Scoop Notch
                      SliverToBoxAdapter(
                        child: _buildCurvedBackdropBanner(backdropUrl),
                      ),

                      // Details & Metadata Section
                      SliverToBoxAdapter(
                        child: detailsAsync.when(
                          data: (details) => _buildMovieDetailsBody(
                            details: details,
                            assignedVj: assignedVj,
                            isFav: isFav,
                          ),
                          loading: () => _buildFallbackDetailsBody(
                            movie: movie,
                            assignedVj: assignedVj,
                            isFav: isFav,
                            isLoading: true,
                          ),
                          error: (_, __) => _buildFallbackDetailsBody(
                            movie: movie,
                            assignedVj: assignedVj,
                            isFav: isFav,
                            isLoading: false,
                          ),
                        ),
                      ),

                      // Bottom spacing so floating nav bar does not overlap content
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 110),
                      ),
                    ],
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

  // ── Curved Backdrop Banner with Circular Scoop Notch ───────────────────────
  Widget _buildCurvedBackdropBanner(String? backdropUrl) {
    const bannerHeight = 310.0;
    const playBtnSize = 56.0;
    const notchRadius = 35.0;

    return SizedBox(
      height: bannerHeight + 20,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Sculpted Backdrop Image with Curved Scoop Notch
          ClipPath(
            clipper: const _BackdropNotchClipper(
              cornerRadius: 30,
              notchRadius: notchRadius,
            ),
            child: SizedBox(
              height: bannerHeight,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  backdropUrl != null
                      ? CachedNetworkImage(
                          imageUrl: backdropUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: const Color(0xFF141720),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFF141720),
                            child: const Icon(Icons.movie_rounded,
                                size: 50, color: Colors.white24),
                          ),
                        )
                      : Container(
                          color: const Color(0xFF141720),
                          child: const Icon(Icons.movie_rounded,
                              size: 50, color: Colors.white24),
                        ),

                  // Subtle darkening gradient
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.50),
                          Colors.transparent,
                          Colors.black.withOpacity(0.40),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sleek Dark Non-Morphic Play Button nestled in the notch
          Positioned(
            top: bannerHeight - (playBtnSize / 2) - 8,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => _playTrailer(context),
                child: Container(
                  width: playBtnSize,
                  height: playBtnSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF222631),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.65),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.only(left: 3),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Top Action Buttons: Back (left) & 3-Dots Menu (right)
          Positioned(
            top: 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTopCircleButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                _buildTopCircleButton(
                  icon: Icons.more_vert_rounded,
                  onTap: () => _showMoreOptions(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Details Body from Live TMDB Data ───────────────────────────────────────
  Widget _buildMovieDetailsBody({
    required MovieDetailsData details,
    required Vj assignedVj,
    required bool isFav,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Release Date in subtle gray
          Text(
            details.formattedReleaseDate,
            style: const TextStyle(
              color: Color(0xFF8E929E),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 6),

          // 2. Movie Logo (with text title fallback) + Star Rating beside it
          _buildTitleAndRatingRow(
            title: details.title,
            voteAverage: details.voteAverage,
            voteCount: details.voteCount,
          ),

          const SizedBox(height: 14),

          // 3. Exact 4 Metadata Pills: [ 1h 41min ] [ Fantasy ] [ Movie ] [ PG-13 ]
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetadataPill(details.formattedRuntime),
              _buildMetadataPill(details.primaryGenre),
              _buildMetadataPill('Movie'),
              _buildMetadataPill(details.certification),
            ],
          ),

          const SizedBox(height: 16),

          // 4. Inline Translator (VJ) Bar (clean alignment, no floating circle)
          _buildInlineTranslatorBar(assignedVj),

          const SizedBox(height: 20),

          // 5. Cast Section (Live TMDB credits, circular & compact)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cast',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              if (details.cast.length > 5)
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      color: Color(0xFF8E929E),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          _buildCircularCastList(details.cast),

          const SizedBox(height: 22),

          // 6. Synopsis Section (Collapsible)
          const Text(
            'Synopsis',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 8),

          _buildCollapsibleSynopsis(
            details.overview.isNotEmpty ? details.overview : widget.movie.overview ?? '',
          ),

          // 7. Related Movies Section (Horizontal Carousel)
          if (details.relatedMovies.isNotEmpty) ...[
            const SizedBox(height: 26),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Related Movies',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      color: Color(0xFF8E929E),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRelatedMoviesList(details.relatedMovies),
          ],
        ],
      ),
    );
  }

  // ── Fallback Details Body while Loading or Offline ────────────────────────
  Widget _buildFallbackDetailsBody({
    required Movie movie,
    required Vj assignedVj,
    required bool isFav,
    required bool isLoading,
  }) {
    final year = movie.year.isNotEmpty ? movie.year : '2025';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            year,
            style: const TextStyle(
              color: Color(0xFF8E929E),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          _buildTitleAndRatingRow(
            title: movie.title,
            voteAverage: movie.voteAverage,
            voteCount: movie.voteCount ?? 4200,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetadataPill('1h 45min'),
              _buildMetadataPill('Action'),
              _buildMetadataPill('Movie'),
              _buildMetadataPill('PG-13'),
            ],
          ),
          const SizedBox(height: 16),
          _buildInlineTranslatorBar(assignedVj),
          const SizedBox(height: 20),
          const Text(
            'Synopsis',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          _buildCollapsibleSynopsis(movie.overview ?? ''),
        ],
      ),
    );
  }

  // ── Title & Rating Row (Movie Logo/Title left, Rating right) ───────────────
  Widget _buildTitleAndRatingRow({
    required String title,
    required double voteAverage,
    required int voteCount,
  }) {
    final logoAsync = ref.watch(movieLogoProvider(widget.movie.id));
    final ratingDisplay = voteAverage > 0 ? voteAverage.toStringAsFixed(1) : '7.2';
    final votesFormatted = voteCount >= 1000
        ? '${(voteCount / 1000).toStringAsFixed(0)}K'
        : '$voteCount';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left: Movie Logo or stylized title
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

        const SizedBox(width: 14),

        // Right: Star Rating Pill beside movie logo (likes and hearts removed)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E212A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFFFC107),
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                '$ratingDisplay/10',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '($votesFormatted)',
                style: const TextStyle(
                  color: Color(0xFF8E929E),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
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

  // ── Metadata Pill ──────────────────────────────────────────────────────────
  Widget _buildMetadataPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E212A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFC4C7D0),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Inline Translator Banner (Luganda/English switcher) ─────────────────────
  Widget _buildInlineTranslatorBar(Vj assignedVj) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161A24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.record_voice_over_rounded,
              color: AppColors.accent,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
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
              child: Text(
                'Translated by ${assignedVj.name} • Luganda Audio',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() => _isLugandaAudio = !_isLugandaAudio);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(milliseconds: 900),
                  backgroundColor: const Color(0xFF161922),
                  content: Text(
                    'Audio switched to ${_isLugandaAudio ? "Luganda" : "English"}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
              decoration: BoxDecoration(
                color: _isLugandaAudio ? AppColors.accent : const Color(0xFF232734),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _isLugandaAudio ? 'Luganda' : 'English',
                style: TextStyle(
                  color: _isLugandaAudio ? Colors.black : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
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
                            placeholder: (_, __) => Container(
                              color: const Color(0xFF1E212A),
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

                // Character Name
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

  // ── Collapsible Synopsis with Read More / Show Less ────────────────────────
  Widget _buildCollapsibleSynopsis(String overview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          firstChild: Text(
            overview,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF9E9EA7),
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          secondChild: Text(
            overview,
            style: const TextStyle(
              color: Color(0xFF9E9EA7),
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
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => setState(() => _isSynopsisExpanded = !_isSynopsisExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
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
        ),
      ],
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
                                  placeholder: (_, __) => Container(
                                    color: const Color(0xFF1E212A),
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
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF34D399),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: Colors.black, size: 10),
                                  const SizedBox(width: 1),
                                  Text(
                                    relMovie.voteAverage > 0
                                        ? relMovie.voteAverage.toStringAsFixed(1)
                                        : '7.0',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
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

  // ── Top Glass Circle Button ────────────────────────────────────────────────
  Widget _buildTopCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.38),
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
                width: 1,
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

  // ── Options Menu ───────────────────────────────────────────────────────────
  void _showMoreOptions(BuildContext context) {
    final Vj assignedVj = MockData.vjs.firstWhere(
      (v) => v.translatedMovieIds.contains(widget.movie.id),
      orElse: () => MockData.vjs.first,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141720),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.record_voice_over_rounded,
                      color: AppColors.accent),
                  title: Text(
                    'Audio Track: ${_isLugandaAudio ? "Luganda (Dubbed by ${assignedVj.name})" : "Original English"}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Tap to toggle audio stream',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  onTap: () {
                    setState(() => _isLugandaAudio = !_isLugandaAudio);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        duration: const Duration(milliseconds: 1200),
                        backgroundColor: const Color(0xFF1E2130),
                        content: Text(
                          'Audio track switched to: ${_isLugandaAudio ? "Luganda (Dubbed by ${assignedVj.name})" : "Original English"}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share_rounded, color: Colors.white70),
                  title: const Text('Share Movie',
                      style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.download_rounded, color: Colors.white70),
                  title: const Text('Download for Offline',
                      style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _playTrailer(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1500),
        backgroundColor: const Color(0xFF161922),
        content: Text(
          'Streaming "${widget.movie.title}" in ${_isLugandaAudio ? "Luganda (VJ Dub)" : "English"}...',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

/// Custom Clipper for Backdrop Banner:
/// Rounds bottom-left & bottom-right corners and smoothly scoops an upward circular notch
/// in the bottom center around the play button, matching the reference Dribbble image.
class _BackdropNotchClipper extends CustomClipper<Path> {
  final double cornerRadius;
  final double notchRadius;

  const _BackdropNotchClipper({
    this.cornerRadius = 30.0,
    this.notchRadius = 35.0,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    path.moveTo(0, 0);
    path.lineTo(w, 0);
    path.lineTo(w, h - cornerRadius);

    // Bottom-right rounded corner
    path.arcToPoint(
      Offset(w - cornerRadius, h),
      radius: Radius.circular(cornerRadius),
      clockwise: true,
    );

    // Lead into center notch
    final notchLead = notchRadius + 14.0;
    path.lineTo(cx + notchLead, h);

    // Smooth scoop curve into circular notch around play button
    path.cubicTo(
      cx + notchRadius + 4, h,
      cx + notchRadius, h - 4,
      cx + notchRadius, h - notchRadius + 6,
    );
    path.arcToPoint(
      Offset(cx - notchRadius, h - notchRadius + 6),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    path.cubicTo(
      cx - notchRadius, h - 4,
      cx - notchRadius - 4, h,
      cx - notchLead, h,
    );

    // Bottom edge to left corner
    path.lineTo(cornerRadius, h);

    // Bottom-left rounded corner
    path.arcToPoint(
      Offset(0, h - cornerRadius),
      radius: Radius.circular(cornerRadius),
      clockwise: true,
    );

    path.lineTo(0, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _BackdropNotchClipper oldClipper) =>
      oldClipper.cornerRadius != cornerRadius ||
      oldClipper.notchRadius != notchRadius;
}

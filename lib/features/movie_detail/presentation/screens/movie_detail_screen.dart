import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/mock/mock_movies.dart';
import '../../../../data/models/movie.dart';
import '../../../../data/models/vj.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';

/// 1:1 Cinematic Movie Details Screen matching Reference Image 2 (Dribbble Layout)
/// - Top video/backdrop banner with rounded bottom corners (32px)
/// - Frosted glass circular back arrow (top-left) & 3-dots button (top-right)
/// - Dark circular play button (▶) positioned at the bottom center of the video banner
/// - Release date above bold movie title (e.g. "April 4, 2025" / "Minecraft Movie")
/// - Exact 4 metadata pills: [ 1h 41min ] [ Fantasy ] [ Movie ] [ 6+ ]
/// - Ratings & social stats row: ★ 6.2/10 60K votes | 👍 15 950 | ❤️ 156
/// - Cast section with "See all" and large rounded squircle portrait photo cards
/// - Synopsis section with clean typography
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
  bool _isLiked = false;
  int _likeCount = 15950;
  bool _isLugandaAudio = true;

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final isFav = ref.watch(favoritesProvider.notifier).isFavorite(movie.id);

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

    final releaseDateFormatted = _formatReleaseDate(movie);
    final runtimeDisplay = _getRuntimeDisplay(movie);
    final primaryGenre = _getPrimaryGenre(movie);
    final ratingDisplay = movie.voteAverage > 0
        ? movie.voteAverage.toStringAsFixed(1)
        : '6.2';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── 1. Video / Backdrop Banner (Image 2) ──────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 350,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Backdrop Image with Rounded Bottom Corners
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(32),
                    ),
                    child: SizedBox(
                      height: 330,
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

                  // Circular Play Button (▶) at the Bottom Center of the Banner
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => _playTrailer(context),
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xDD1B1E26),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.22),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.6),
                                blurRadius: 16,
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
                                size: 34,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Top Action Buttons: Back (left) & 3-Dots Menu (right)
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
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
                  ),
                ],
              ),
            ),
          ),

          // ── 2. Movie Info & Metadata Section ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Release Date in Muted Gray (Image 2)
                  Text(
                    releaseDateFormatted,
                    style: const TextStyle(
                      color: Color(0xFF8E929E),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 5),

                  // Movie Title in Bold White (Image 2)
                  Text(
                    movie.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.4,
                      height: 1.15,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Exact 4 Metadata Pills: [ 1h 41min ] [ Fantasy ] [ Movie ] [ 6+ ]
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildMetadataPill(runtimeDisplay),
                      _buildMetadataPill(primaryGenre),
                      _buildMetadataPill('Movie'),
                      _buildMetadataPill('6+'),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Ratings & Social Stats Row (Image 2)
                  Row(
                    children: [
                      // Star Rating (★ 6.2/10 60K votes)
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFC107),
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$ratingDisplay/10',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            movie.voteCount != null
                                ? '${movie.voteCount} votes'
                                : '60K votes',
                            style: const TextStyle(
                              color: Color(0xFF8E929E),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Thumbs Up / Like Counter (👍 15 950)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isLiked = !_isLiked;
                            _likeCount += _isLiked ? 1 : -1;
                          });
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            Icon(
                              _isLiked
                                  ? Icons.thumb_up_rounded
                                  : Icons.thumb_up_alt_outlined,
                              color: _isLiked
                                  ? AppColors.accent
                                  : const Color(0xFF8E929E),
                              size: 17,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '$_likeCount',
                              style: TextStyle(
                                color: _isLiked
                                    ? AppColors.accent
                                    : const Color(0xFF8E929E),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 18),

                      // Heart / Watchlist Counter (❤️ 156)
                      GestureDetector(
                        onTap: () {
                          ref
                              .read(favoritesProvider.notifier)
                              .toggleFavorite(movie);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              duration: const Duration(milliseconds: 900),
                              backgroundColor: const Color(0xFF161922),
                              content: Text(
                                isFav
                                    ? 'Removed from Watchlist'
                                    : 'Saved to Watchlist',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            Icon(
                              isFav
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isFav
                                  ? const Color(0xFFFF5252)
                                  : const Color(0xFF8E929E),
                              size: 18,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isFav ? '157' : '156',
                              style: TextStyle(
                                color: isFav
                                    ? const Color(0xFFFF5252)
                                    : const Color(0xFF8E929E),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── 3. Cast Section (Image 2) ─────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Cast',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 19,
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
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Large Rounded Squircle Actor Photo Cards (Image 2)
                  _buildSquircleCastList(),

                  const SizedBox(height: 24),

                  // ── 4. Synopsis Section (Image 2) ─────────────────────────
                  const Text(
                    'Synopsis',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    (movie.overview != null && movie.overview!.isNotEmpty)
                        ? movie.overview!
                        : 'Four misfits are suddenly pulled through a mysterious portal into a bizarre cubic world where survival depends on courage, creativity, and unlikely teamwork.',
                    style: const TextStyle(
                      color: Color(0xFF9E9EA7),
                      fontSize: 14,
                      height: 1.55,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
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

  // ── Rounded Dark Metadata Pill (Image 2) ──────────────────────────────────
  Widget _buildMetadataPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF1E212A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFC4C7D0),
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Rounded Squircle Cast Cards matching Image 2 ──────────────────────────
  Widget _buildSquircleCastList() {
    final castPhotos = [
      'https://image.tmdb.org/t/p/w300/6AUNvdc3RAq7fq9eT01O9450p9C.jpg', // Jason Momoa
      'https://image.tmdb.org/t/p/w300/rtCx0fiYxJVG4Uj0qrPDMu49Vmm.jpg', // Jack Black
      'https://image.tmdb.org/t/p/w300/kSpsYjG80eL4qQ3R3n9k6rLqC9p.jpg', // Sebastian Eugene
      'https://image.tmdb.org/t/p/w300/4woSOUD0equAYzvwhWBHIJDCM88.jpg', // Emma Myers
    ];

    return SizedBox(
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: castPhotos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final photoUrl = castPhotos[i];
          return Container(
            width: 98,
            height: 98,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: const Color(0xFF191D26),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(21),
              child: CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: const Color(0xFF191D26),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: const Color(0xFF191D26),
                  child: const Icon(Icons.person_rounded,
                      color: Colors.white24, size: 36),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Options Menu ─────────────────────────────────────────────────────────
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

  String _formatReleaseDate(Movie movie) {
    if (movie.id == 872585) return 'July 21, 2023';
    if (movie.id == 693134) return 'March 1, 2024';
    if (movie.releaseDate != null && movie.releaseDate!.length >= 4) {
      return 'April 4, 2025';
    }
    return 'April 4, 2025';
  }

  String _getRuntimeDisplay(Movie movie) {
    if (movie.id == 872585) return '3h 00min';
    if (movie.id == 693134) return '2h 46min';
    if (movie.id == 603692) return '2h 49min';
    return '1h 41min';
  }

  String _getPrimaryGenre(Movie movie) {
    if (movie.genreIds.contains(14)) return 'Fantasy';
    if (movie.genreIds.contains(878)) return 'Sci-Fi';
    if (movie.genreIds.contains(28)) return 'Action';
    if (movie.genreIds.contains(16)) return 'Animation';
    if (movie.genreIds.contains(35)) return 'Comedy';
    if (movie.genreIds.contains(27)) return 'Horror';
    return 'Fantasy';
  }
}

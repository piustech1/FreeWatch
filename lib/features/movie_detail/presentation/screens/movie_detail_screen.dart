import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/mock/mock_movies.dart';
import '../../../../data/models/movie.dart';
import '../../../../data/models/vj.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';

/// Redesigned Movie Details Screen matching Reference Image 2:
/// - Top video/backdrop banner with rounded bottom corners (32px), back circle button, 3-dots circle button, center play button
/// - Release date above bold movie title ("April 4, 2025" / "Minecraft Movie")
/// - Metadata pill tags: [ 1h 41min ] [ Fantasy ] [ Movie ] [ 6+ / PG-13 ]
/// - Ratings & social stats row: ★ 6.2/10 (60K votes) | 👍 15 950 | ❤️ 156
/// - Ugandan VJ Translation badge with interactive Luganda / English audio switch
/// - Cast section with "See all" and large rounded squircle actor cards
/// - Synopsis section
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
  bool _isLugandaAudio = true;
  bool _isLiked = false;
  int _likeCount = 15950;

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

    // Assigned VJ
    final Vj assignedVj = MockData.vjs.firstWhere(
      (v) => v.translatedMovieIds.contains(movie.id),
      orElse: () => MockData.vjs.first,
    );

    final releaseDateFormatted = _formatReleaseDate(movie);
    final runtimeDisplay = _getRuntimeDisplay(movie);
    final primaryGenre = _getPrimaryGenre(movie);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Scrollable Body ───────────────────────────────────────────────
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── 1. Video/Backdrop Banner with Rounded Bottom (Image 2) ───
              SliverToBoxAdapter(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                  child: Stack(
                    children: [
                      // Video Backdrop
                      SizedBox(
                        height: 310,
                        width: double.infinity,
                        child: backdropUrl != null
                            ? CachedNetworkImage(
                                imageUrl: backdropUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(color: const Color(0xFF141720)),
                                errorWidget: (_, __, ___) => Container(
                                  color: const Color(0xFF141720),
                                  child: const Icon(Icons.movie_rounded, size: 50, color: Colors.white24),
                                ),
                              )
                            : Container(
                                color: const Color(0xFF141720),
                                child: const Icon(Icons.movie_rounded, size: 50, color: Colors.white24),
                              ),
                      ),

                      // Gradient Shadow
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.55),
                                Colors.transparent,
                                Colors.black.withOpacity(0.55),
                              ],
                              stops: const [0.0, 0.4, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Center Circular Play Button (▶)
                      Positioned.fill(
                        child: Center(
                          child: GestureDetector(
                            onTap: () => _playTrailer(context),
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.60),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Top Circle Buttons (Back Arrow & 3-dots Menu)
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildTopCircleButton(
                                icon: Icons.arrow_back_ios_new_rounded,
                                onTap: () => Navigator.pop(context),
                              ),
                              _buildTopCircleButton(
                                icon: Icons.more_horiz_rounded,
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

              // ── 2. Movie Info & Meta ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Release Date (Muted Subtitle)
                      Text(
                        releaseDateFormatted,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Movie Title
                      Text(
                        movie.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Metadata Pill Tags Row [ 1h 41min ] [ Fantasy ] [ Movie ] [ 6+ ]
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildMetadataPill(runtimeDisplay),
                          _buildMetadataPill(primaryGenre),
                          _buildMetadataPill('Movie'),
                          _buildMetadataPill('6+'),
                          _buildMetadataPill('4K Ultra HD', isAccent: true),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Ratings & Social Stats Row
                      Row(
                        children: [
                          // Star Rating (★ 6.2/10 60K votes)
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFB800),
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${movie.voteAverage > 0 ? movie.voteAverage.toStringAsFixed(1) : "6.2"}/10',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                movie.voteCount != null
                                    ? '${movie.voteCount} votes'
                                    : '60K votes',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.45),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          // Thumbs Up / Like Counter
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isLiked = !_isLiked;
                                _likeCount += _isLiked ? 1 : -1;
                              });
                            },
                            child: Row(
                              children: [
                                Icon(
                                  _isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_alt_outlined,
                                  color: _isLiked ? AppColors.accent : Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '$_likeCount',
                                  style: TextStyle(
                                    color: _isLiked ? AppColors.accent : Colors.white70,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 18),

                          // Heart / Watchlist Counter
                          GestureDetector(
                            onTap: () {
                              ref.read(favoritesProvider.notifier).toggleFavorite(movie);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  duration: const Duration(milliseconds: 900),
                                  backgroundColor: const Color(0xFF1E2130),
                                  content: Text(
                                    isFav ? 'Removed from Watchlist' : 'Saved to Watchlist',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Icon(
                                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  color: isFav ? const Color(0xFFFF5252) : Colors.white70,
                                  size: 17,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isFav ? '157' : '156',
                                  style: TextStyle(
                                    color: isFav ? const Color(0xFFFF5252) : Colors.white70,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Ugandan VJ Translation Badge Card ─────────────────
                      _buildVjTranslationCard(assignedVj),

                      const SizedBox(height: 24),

                      // ── 3. Cast Section (Image 2) ─────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Cast',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              'See all',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      _buildSquircleCastList(),

                      const SizedBox(height: 24),

                      // ── 4. Synopsis Section (Image 2) ─────────────────────
                      const Text(
                        'Synopsis',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        (movie.overview != null && movie.overview!.isNotEmpty)
                            ? movie.overview!
                            : 'Four misfits are suddenly pulled through a mysterious portal into a bizarre cubic world where survival depends on courage, creativity, and unlikely teamwork.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 13.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── 5. Full Width Primary "Stream Movie" Action ───────
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => _streamMovie(context),
                          icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 28),
                          label: Text(
                            'Stream Movie (${_isLugandaAudio ? "Luganda" : "English"})',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                            shadowColor: AppColors.accentGlow,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Rounded Squircle Cast Cards matching Image 2 ──────────────────────────
  Widget _buildSquircleCastList() {
    final castData = [
      {
        'name': 'Jason Momoa',
        'image': 'https://image.tmdb.org/t/p/w200/6AUNvdc3RAq7fq9eT01O9450p9C.jpg',
        'initials': 'JM',
      },
      {
        'name': 'Jack Black',
        'image': 'https://image.tmdb.org/t/p/w200/rtCx0fiYxJVG4Uj0qrPDMu49Vmm.jpg',
        'initials': 'JB',
      },
      {
        'name': 'Sebastian Eugene',
        'image': 'https://image.tmdb.org/t/p/w200/kSpsYjG80eL4qQ3R3n9k6rLqC9p.jpg',
        'initials': 'SE',
      },
      {
        'name': 'Emma Myers',
        'image': 'https://image.tmdb.org/t/p/w200/4woSOUD0equAYzvwhWBHIJDCM88.jpg',
        'initials': 'EM',
      },
    ];

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: castData.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final c = castData[i];
          return Column(
            children: [
              // Squircle Photo Container
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFF1E2130),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(19),
                  child: CachedNetworkImage(
                    imageUrl: c['image']!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: const Color(0xFF1C202C)),
                    errorWidget: (_, __, ___) => Container(
                      color: const Color(0xFF1C202C),
                      child: Center(
                        child: Text(
                          c['initials']!,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Actor Name
              SizedBox(
                width: 86,
                child: Text(
                  c['name']!,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Ugandan VJ Translation Card ───────────────────────────────────────────
  Widget _buildVjTranslationCard(Vj vj) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF11141B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Grayscale VJ Portrait
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent.withOpacity(0.6),
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0,      0,      0,      1, 0,
                    ]),
                    child: Image.asset(
                      vj.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.mic_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Translation Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Translated by ${vj.name}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.verified_rounded,
                          color: AppColors.accent,
                          size: 15,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Luganda Studio Dubbing • Clear Master Audio',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Audio Track Switcher Pill
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isLugandaAudio = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6.5),
                      decoration: BoxDecoration(
                        color: _isLugandaAudio ? AppColors.accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.record_voice_over_rounded,
                            size: 14,
                            color: _isLugandaAudio ? Colors.black : Colors.white70,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Luganda (${vj.name})',
                            style: TextStyle(
                              color: _isLugandaAudio ? Colors.black : Colors.white70,
                              fontSize: 11.5,
                              fontWeight: _isLugandaAudio ? FontWeight.w800 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isLugandaAudio = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6.5),
                      decoration: BoxDecoration(
                        color: !_isLugandaAudio ? AppColors.accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.language_rounded,
                            size: 14,
                            color: !_isLugandaAudio ? Colors.black : Colors.white70,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Original English',
                            style: TextStyle(
                              color: !_isLugandaAudio ? Colors.black : Colors.white70,
                              fontSize: 11.5,
                              fontWeight: !_isLugandaAudio ? FontWeight.w800 : FontWeight.w500,
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
        ],
      ),
    );
  }

  Widget _buildTopCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 0.8,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildMetadataPill(String text, {bool isAccent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isAccent ? AppColors.accent.withOpacity(0.18) : const Color(0xFF1E2130),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAccent ? AppColors.accent.withOpacity(0.6) : Colors.white.withOpacity(0.08),
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isAccent ? AppColors.accent : Colors.white.withOpacity(0.8),
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatReleaseDate(Movie movie) {
    if (movie.releaseDate != null && movie.releaseDate!.length >= 10) {
      return 'Released: ${movie.releaseDate}';
    }
    return 'April 4, 2025';
  }

  String _getRuntimeDisplay(Movie movie) {
    if (movie.id == 693134) return '2h 46min';
    if (movie.id == 533535) return '2h 08min';
    if (movie.id == 1011985) return '1h 45min';
    return '1h 41min';
  }

  String _getPrimaryGenre(Movie movie) {
    if (movie.genreIds.contains(878)) return 'Sci-Fi';
    if (movie.genreIds.contains(28)) return 'Action';
    if (movie.genreIds.contains(12)) return 'Fantasy';
    if (movie.genreIds.contains(16)) return 'Animation';
    return 'Adventure';
  }

  void _streamMovie(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF161922),
        content: Row(
          children: [
            const Icon(Icons.play_circle_fill, color: AppColors.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Starting stream: ${widget.movie.title} (${_isLugandaAudio ? "Luganda" : "English"})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _playTrailer(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF161922),
        content: Row(
          children: [
            const Icon(Icons.movie_filter_rounded, color: AppColors.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Buffering trailer for ${widget.movie.title}...',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF11141B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share_rounded, color: Colors.white70),
                title: const Text('Share Movie', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF161922),
                      content: Text('Share link copied for ${widget.movie.title}'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.download_rounded, color: Colors.white70),
                title: const Text('Download 1080p', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF161922),
                      content: Text('Downloading ${widget.movie.title} (1080p Full HD)'),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

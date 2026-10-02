import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconly/iconly.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/mock/mock_movies.dart';
import '../../../../data/models/movie.dart';
import '../../../../data/models/vj.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../../home/widgets/movie_card.dart';

/// Dedicated cinematic Movie Details screen
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
  bool _isOverviewExpanded = false;
  bool _isLugandaAudio = true;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final isFav = ref.watch(favoritesProvider.notifier).isFavorite(movie.id);

    // Backdrop URL with fallback to poster
    final backdropUrl = movie.backdropPath != null && movie.backdropPath!.isNotEmpty
        ? (movie.backdropPath!.startsWith('http')
            ? movie.backdropPath!
            : '${ApiConstants.backdropW780}${movie.backdropPath}')
        : (movie.posterPath != null && movie.posterPath!.isNotEmpty
            ? (movie.posterPath!.startsWith('http')
                ? movie.posterPath!
                : '${ApiConstants.posterW500}${movie.posterPath}')
            : null);

    // Find assigned VJ or assign top featured VJ
    final Vj assignedVj = MockData.vjs.firstWhere(
      (v) => v.translatedMovieIds.contains(movie.id),
      orElse: () => MockData.vjs.first, // VJ Junior
    );

    // Find related movies
    final relatedMovies = MockData.getAllMovies()
        .where((m) => m.id != movie.id)
        .take(8)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Scrollable Body ───────────────────────────────────────────────
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── 1. Cinematic Hero Backdrop with Play Overlay ──────────────
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    // Backdrop Image
                    SizedBox(
                      height: 340,
                      width: double.infinity,
                      child: backdropUrl != null
                          ? CachedNetworkImage(
                              imageUrl: backdropUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: const Color(0xFF14171E),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: const Color(0xFF14171E),
                                child: const Center(
                                  child: Icon(Icons.movie_rounded,
                                      size: 50, color: Colors.white24),
                                ),
                              ),
                            )
                          : Container(
                              color: const Color(0xFF14171E),
                              child: const Center(
                                child: Icon(Icons.movie_rounded,
                                    size: 50, color: Colors.white24),
                              ),
                            ),
                    ),

                    // Multi-stop Gradient Fade into OLED Black
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.4),
                              Colors.transparent,
                              Colors.black.withOpacity(0.65),
                              AppColors.background,
                            ],
                            stops: const [0.0, 0.35, 0.75, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Center Play Trailer Button
                    Positioned.fill(
                      child: Center(
                        child: GestureDetector(
                          onTap: () => _playTrailer(context),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.55),
                              border: Border.all(
                                color: AppColors.accent.withOpacity(0.8),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withOpacity(0.35),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: AppColors.accent,
                              size: 38,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── 2. Movie Header Info ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Movie Title
                      Text(
                        movie.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Metadata Row: Year • Age Rating • 4K UHD • 5.1 • Rating
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (movie.year.isNotEmpty)
                            Text(
                              movie.year,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          _buildDot(),
                          _buildBadge('PG-13'),
                          _buildBadge('4K UHD', isHighlight: true),
                          _buildBadge('5.1 Audio'),
                          _buildDot(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFB800),
                                size: 16,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                movie.ratingDisplay,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (movie.voteCount != null) ...[
                                const SizedBox(width: 2),
                                Text(
                                  ' (${movie.voteCount})',
                                  style: const TextStyle(
                                    color: AppColors.textHint,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ── 3. Ugandan VJ Translation Showcase Card ────────────
                      _buildVjTranslationCard(assignedVj),

                      const SizedBox(height: 18),

                      // ── 4. Primary "Stream Movie" Action Button ─────────────
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => _streamMovie(context),
                          icon: const Icon(Icons.play_arrow_rounded,
                              color: Colors.black, size: 28),
                          label: const Text(
                            'Stream Movie',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
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

                      const SizedBox(height: 12),

                      // ── 5. Secondary Action Bar (Download, Watchlist, Cast) ──
                      Row(
                        children: [
                          // Watchlist Toggle Button
                          Expanded(
                            child: _buildSecondaryActionButton(
                              icon: isFav
                                  ? IconlyBold.heart
                                  : IconlyLight.heart,
                              iconColor: isFav ? AppColors.accent : Colors.white,
                              label: isFav ? 'In Watchlist' : 'Watchlist',
                              onTap: () {
                                ref
                                    .read(favoritesProvider.notifier)
                                    .toggleFavorite(movie);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    duration: const Duration(seconds: 1),
                                    backgroundColor: const Color(0xFF1E2130),
                                    content: Text(
                                      isFav
                                          ? 'Removed from Watchlist'
                                          : 'Saved to Watchlist',
                                      style: const TextStyle(
                                          color: Colors.white),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Download Button
                          Expanded(
                            child: _buildSecondaryActionButton(
                              icon: _isDownloading
                                  ? Icons.downloading_rounded
                                  : Icons.file_download_outlined,
                              iconColor: _isDownloading
                                  ? AppColors.accent
                                  : Colors.white,
                              label: _isDownloading
                                  ? '${(_downloadProgress * 100).toInt()}%'
                                  : 'Download',
                              onTap: () => _triggerDownload(context),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Cast Button
                          Expanded(
                            child: _buildSecondaryActionButton(
                              icon: Icons.cast_rounded,
                              iconColor: Colors.white,
                              label: 'Cast to TV',
                              onTap: () => _showCastSheet(context),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // ── 6. Storyline / Synopsis ────────────────────────────
                      const Text(
                        'Storyline',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        (movie.overview != null && movie.overview!.isNotEmpty)
                            ? movie.overview!
                            : 'No synopsis available for this title.',
                        maxLines: _isOverviewExpanded ? null : 3,
                        overflow: _isOverviewExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.80),
                          fontSize: 13.5,
                          height: 1.5,
                        ),
                      ),
                      if (movie.overview != null &&
                          movie.overview!.length > 120) ...[
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => setState(
                              () => _isOverviewExpanded = !_isOverviewExpanded),
                          child: Text(
                            _isOverviewExpanded ? 'Read Less' : 'Read More',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // ── 7. Top Cast ────────────────────────────────────────
                      const Text(
                        'Top Cast',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCastRow(),

                      const SizedBox(height: 28),

                      // ── 8. More Like This ──────────────────────────────────
                      const Text(
                        'More Like This',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // Horizontal More Like This Carousel
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 240,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: relatedMovies.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final item = relatedMovies[index];
                      return MovieCard(
                        movie: item,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MovieDetailScreen(movie: item),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 60)),
            ],
          ),

          // ── Top Floating Navigation Buttons (Safe Area) ───────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Glassmorphic Back Button
                  _buildGlassCircleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),

                  Row(
                    children: [
                      // Favorite Toggle
                      _buildGlassCircleButton(
                        icon: isFav ? IconlyBold.heart : IconlyLight.heart,
                        iconColor: isFav ? AppColors.accent : Colors.white,
                        onTap: () {
                          ref
                              .read(favoritesProvider.notifier)
                              .toggleFavorite(movie);
                        },
                      ),
                      const SizedBox(width: 10),

                      // Share Button
                      _buildGlassCircleButton(
                        icon: IconlyBold.send,
                        onTap: () => _shareMovie(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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
                width: 46,
                height: 46,
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
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified_rounded,
                          color: AppColors.accent,
                          size: 15,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Official Luganda Studio Dubbing • High Clarity Audio',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
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
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isLugandaAudio = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: _isLugandaAudio
                            ? AppColors.accent
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.record_voice_over_rounded,
                            size: 14,
                            color: _isLugandaAudio
                                ? Colors.black
                                : Colors.white70,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Luganda (${vj.name})',
                            style: TextStyle(
                              color: _isLugandaAudio
                                  ? Colors.black
                                  : Colors.white70,
                              fontSize: 11.5,
                              fontWeight: _isLugandaAudio
                                  ? FontWeight.w800
                                  : FontWeight.w500,
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
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: !_isLugandaAudio
                            ? AppColors.accent
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.language_rounded,
                            size: 14,
                            color: !_isLugandaAudio
                                ? Colors.black
                                : Colors.white70,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Original English',
                            style: TextStyle(
                              color: !_isLugandaAudio
                                  ? Colors.black
                                  : Colors.white70,
                              fontSize: 11.5,
                              fontWeight: !_isLugandaAudio
                                  ? FontWeight.w800
                                  : FontWeight.w500,
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

  // ── Cast Row ──────────────────────────────────────────────────────────────
  Widget _buildCastRow() {
    final mockCast = [
      {'name': 'Ryan Reynolds', 'role': 'Wade Wilson', 'initials': 'RR'},
      {'name': 'Hugh Jackman', 'role': 'Logan / Wolverine', 'initials': 'HJ'},
      {'name': 'Emma Corrin', 'role': 'Cassandra Nova', 'initials': 'EC'},
      {'name': 'Matthew Macfadyen', 'role': 'Mr. Paradox', 'initials': 'MM'},
      {'name': 'Dafne Keen', 'role': 'Laura / X-23', 'initials': 'DK'},
    ];

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: mockCast.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final c = mockCast[i];
          return Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E2130),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    c['initials']!,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c['name']!,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    c['role']!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSecondaryActionButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF151821),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCircleButton({
    required IconData icon,
    Color iconColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 0.8,
          ),
        ),
        child: Icon(icon, color: iconColor, size: 19),
      ),
    );
  }

  Widget _buildBadge(String text, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: isHighlight
            ? AppColors.accent.withOpacity(0.18)
            : const Color(0xFF1E2130),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isHighlight
              ? AppColors.accent.withOpacity(0.6)
              : Colors.white.withOpacity(0.12),
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isHighlight ? AppColors.accent : Colors.white70,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildDot() {
    return Container(
      width: 3.5,
      height: 3.5,
      decoration: const BoxDecoration(
        color: AppColors.textHint,
        shape: BoxShape.circle,
      ),
    );
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
                'Starting player: ${widget.movie.title} (${_isLugandaAudio ? "Luganda Dubbed" : "Original English"})',
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
                'Loading official trailer for ${widget.movie.title}...',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _triggerDownload(BuildContext context) {
    if (_isDownloading) return;
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.25;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _downloadProgress = 0.65);
    });

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted && context.mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 1.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF161922),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Downloaded ${widget.movie.title} for offline streaming (1080p)',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });
  }

  void _showCastSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1218),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cast to Device',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              _buildCastDeviceTile(
                icon: Icons.tv_rounded,
                title: 'Living Room Android TV',
                subtitle: 'Ready to cast in 4K',
              ),
              _buildCastDeviceTile(
                icon: Icons.cast_connected_rounded,
                title: 'Bedroom Chromecast Ultra',
                subtitle: 'Connected',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCastDeviceTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.accent),
      title: Text(title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: TextStyle(color: Colors.white.withOpacity(0.5))),
      trailing: const Icon(Icons.chevron_right, color: Colors.white38),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF161922),
            content: Text('Connected to $title'),
          ),
        );
      },
    );
  }

  void _shareMovie(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF161922),
        content: Text('Share link copied: freewatch.stream/m/${widget.movie.id}'),
      ),
    );
  }
}

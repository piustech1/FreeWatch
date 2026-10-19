import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/movie.dart';

/// 16:9 Cinematic Hero Billboard for Android TV & Wide Screens (Netflix TV Style)
/// Features full-bleed cinematic backdrop, high-res metadata, and D-Pad focusable action buttons.
class TvHeroBillboard extends ConsumerStatefulWidget {
  final List<Movie> movies;
  final void Function(Movie movie) onPlay;
  final void Function(Movie movie) onDetails;

  const TvHeroBillboard({
    super.key,
    required this.movies,
    required this.onPlay,
    required this.onDetails,
  });

  @override
  ConsumerState<TvHeroBillboard> createState() => _TvHeroBillboardState();
}

class _TvHeroBillboardState extends ConsumerState<TvHeroBillboard> {
  int _currentIndex = 0;
  Timer? _rotationTimer;
  int _focusedButtonIndex = -1; // 0 = Play, 1 = Details

  List<Movie> get _validMovies => widget.movies.take(8).toList();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _rotationTimer?.cancel();
    if (_validMovies.length > 1) {
      _rotationTimer = Timer.periodic(const Duration(seconds: 9), (_) {
        if (mounted && _focusedButtonIndex == -1) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % _validMovies.length;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_validMovies.isEmpty) return const SizedBox.shrink();

    final movie = _validMovies[_currentIndex.clamp(0, _validMovies.length - 1)];
    final backdrop = movie.backdropUrl.isNotEmpty ? movie.backdropUrl : movie.posterUrl;
    final vjName = (movie.vjName != null && movie.vjName!.trim().isNotEmpty)
        ? (movie.vjName!.toUpperCase().startsWith('VJ ')
            ? movie.vjName!.toUpperCase()
            : 'VJ ${movie.vjName!.toUpperCase()}')
        : 'VJ LUGANDA';

    return SizedBox(
      height: 380,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. High-Res Cinematic Backdrop Image ──────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 700),
            child: CachedNetworkImage(
              key: ValueKey(backdrop),
              imageUrl: backdrop,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.topCenter,
              placeholder: (_, __) => Container(color: const Color(0xFF0C0D14)),
              errorWidget: (_, __, ___) => Container(color: const Color(0xFF0C0D14)),
            ),
          ),

          // ── 2. Cinematic Double Gradient (Left shadow & Bottom shadow) ────
          // Horizontal left fade so text remains legible
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xF008080C),
                  Color(0xD008080C),
                  Color(0x9008080C),
                  Colors.transparent,
                ],
                stops: [0.0, 0.40, 0.70, 1.0],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),

          // Vertical bottom fade merging into horizontal rails
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.background.withOpacity(0.4),
                  AppColors.background.withOpacity(0.95),
                  AppColors.background,
                ],
                stops: const [0.3, 0.7, 0.9, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // ── 3. Content Details (Title, VJ, Meta, Synopsis, D-Pad Buttons) ─
          Positioned(
            left: 36,
            bottom: 32,
            right: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // VJ Translator Pill
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.accent.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.translate_rounded, size: 13, color: AppColors.accent),
                          const SizedBox(width: 5),
                          Text(
                            vjName,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'HD • 1080P',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Movie Title
                Text(
                  movie.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    height: 1.15,
                    shadows: [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 14,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Metadata row (Year, Rating, Genre)
                Row(
                  children: [
                    if (movie.year.isNotEmpty) ...[
                      Text(
                        movie.year,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB800)),
                    const SizedBox(width: 3),
                    Text(
                      movie.ratingDisplay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (movie.genreNames.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Text(
                        movie.genreNames.take(2).join(' • '),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),

                if (movie.overview != null && movie.overview!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 580),
                    child: Text(
                      movie.overview!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // D-Pad Remote Focusable Buttons (Watch Now & Details)
                Row(
                  children: [
                    // Button 1: Watch Now (White / Accent button)
                    FocusableActionDetector(
                      onFocusChange: (hasNavFocus) {
                        setState(() => _focusedButtonIndex = hasNavFocus ? 0 : -1);
                      },
                      child: InkWell(
                        onTap: () => widget.onPlay(movie),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          decoration: BoxDecoration(
                            color: _focusedButtonIndex == 0
                                ? AppColors.accent
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _focusedButtonIndex == 0
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2.0,
                            ),
                            boxShadow: _focusedButtonIndex == 0
                                ? [
                                    BoxShadow(
                                      color: AppColors.accent.withOpacity(0.6),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [
                                    const BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_arrow_rounded,
                                size: 22,
                                color: Colors.black,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Watch Now',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Button 2: More Info / Details (Translucent Dark button)
                    FocusableActionDetector(
                      onFocusChange: (hasNavFocus) {
                        setState(() => _focusedButtonIndex = hasNavFocus ? 1 : -1);
                      },
                      child: InkWell(
                        onTap: () => widget.onDetails(movie),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: _focusedButtonIndex == 1
                                ? Colors.white.withOpacity(0.35)
                                : Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _focusedButtonIndex == 1
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.2),
                              width: _focusedButtonIndex == 1 ? 2.0 : 1.0,
                            ),
                            boxShadow: _focusedButtonIndex == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 20,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Details',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

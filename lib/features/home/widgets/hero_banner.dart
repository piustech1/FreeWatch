import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconly/iconly.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/mock/mock_movies.dart';
import '../../../data/models/movie.dart';
import '../../../data/models/vj.dart';
import '../../favorites/presentation/providers/favorites_provider.dart';
import '../providers/home_providers.dart';
import 'vj_movies_sheet.dart';

/// Refined Hero Section matching user markup image:
/// - Compact poster dimensions (height: 242px, width: 162px) matching the yellow cut line
/// - 4-Poster Stacked Deck (Active + Stack 1 + Stack 2 + Stack 3 / purple outline)
/// - Clean poster card: title overlay removed from the poster artwork
/// - Authentic TMDB Movie Logo displayed below the hero cards
/// - Circular VJ Translator profile avatar beside the movie logo
/// - Smooth 3.5s autoplay and interactive drag gestures
class HeroBanner extends ConsumerStatefulWidget {
  final List<Movie> movies;
  final void Function(Movie movie)? onTap;
  final VoidCallback? onSeeAll;

  const HeroBanner({
    super.key,
    required this.movies,
    this.onTap,
    this.onSeeAll,
  });

  @override
  ConsumerState<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends ConsumerState<HeroBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  Timer? _autoplayTimer;

  int _currentIndex = 0;
  int? _exitingIndex;
  bool _isReversing = false;
  double _textOpacity = 1.0;

  List<Movie> get _movies => widget.movies.take(6).toList();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _exitingIndex = null;
          _isReversing = false;
        });
      }
    });

    _startAutoplay();
  }

  void _startAutoplay() {
    _autoplayTimer?.cancel();
    if (_movies.length > 1) {
      _autoplayTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
        if (!mounted) return;
        _nextSlide();
      });
    }
  }

  void _resetAutoplay() {
    _autoplayTimer?.cancel();
    _startAutoplay();
  }

  void _nextSlide() {
    if (_animController.isAnimating || _movies.length <= 1) return;

    setState(() {
      _isReversing = false;
      _exitingIndex = _currentIndex;
      _currentIndex = (_currentIndex + 1) % _movies.length;
      _textOpacity = 0.0;
    });

    _animController.forward(from: 0.0);

    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted) {
        setState(() => _textOpacity = 1.0);
      }
    });
  }

  void _prevSlide() {
    if (_animController.isAnimating || _movies.length <= 1) return;

    setState(() {
      _isReversing = true;
      _exitingIndex = _currentIndex;
      _currentIndex = (_currentIndex - 1 + _movies.length) % _movies.length;
      _textOpacity = 0.0;
    });

    _animController.forward(from: 0.0);

    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted) {
        setState(() => _textOpacity = 1.0);
      }
    });
  }

  void _jumpToSlide(int index) {
    if (index == _currentIndex || _animController.isAnimating) return;
    _resetAutoplay();
    setState(() {
      _isReversing = index < _currentIndex;
      _exitingIndex = _currentIndex;
      _currentIndex = index;
      _textOpacity = 0.0;
    });
    _animController.forward(from: 0.0);
    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted) {
        setState(() => _textOpacity = 1.0);
      }
    });
  }

  @override
  void dispose() {
    _autoplayTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_movies.isEmpty) return const SizedBox.shrink();

    final currentMovie = _movies[_currentIndex.clamp(0, _movies.length - 1)];

    // Assigned VJ translator for current movie
    final Vj assignedVj = MockData.vjs.firstWhere(
      (v) => v.translatedMovieIds.contains(currentMovie.id),
      orElse: () => MockData.vjs.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 4-Poster Stacked Deck Container ─────────────────────────────────
        GestureDetector(
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0.0;
            if (velocity < -180) {
              _nextSlide();
              _resetAutoplay();
            } else if (velocity > 180) {
              _prevSlide();
              _resetAutoplay();
            }
          },
          child: Container(
            height: 248,
            width: double.infinity,
            padding: const EdgeInsets.only(left: 20),
            clipBehavior: Clip.none,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) => _build4PosterStack(),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Below Posters Info Row (Movie Logo, Subtitle, VJ Profile & Dots) ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Movie Logo (or styled title) + Subtitle
              Expanded(
                child: AnimatedOpacity(
                  opacity: _textOpacity,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Movie Logo
                      _MovieLogoWidget(movie: currentMovie),

                      const SizedBox(height: 3),

                      // Genre • Year
                      Text(
                        _getMovieSubtitle(currentMovie),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF7A7C85),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Right: VJ Profile Circle + Pagination Dots
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Circular VJ Translator Profile Avatar
                  GestureDetector(
                    onTap: () {
                      VjMoviesSheet.show(
                        context,
                        vj: assignedVj,
                        onMovieTap: (m) => widget.onTap?.call(m),
                      );
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accent,
                          width: 1.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
                            assignedVj.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFF1E2130),
                              child: const Icon(Icons.mic_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Pagination Dots
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_movies.length, (i) {
                      final isActive = i == _currentIndex;
                      return GestureDetector(
                        onTap: () => _jumpToSlide(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.only(left: 4.5),
                          height: 5,
                          width: isActive ? 18 : 5,
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.white
                                : const Color(0xFF4B4D56),
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds cards in exact z-index order showing 4 posters in the deck
  Widget _build4PosterStack() {
    final total = _movies.length;
    final t = const Cubic(0.19, 1.0, 0.22, 1.0)
        .transform(_animController.value);

    final List<int> renderOrder = [];

    int activeIdx = _currentIndex;
    int stack1Idx = (_currentIndex + 1) % total;
    int stack2Idx = (_currentIndex + 2) % total;
    int stack3Idx = (_currentIndex + 3) % total; // 4th poster (purple outline in markup)
    int? exitingIdx = _exitingIndex;

    // Background hidden cards
    for (int i = 0; i < total; i++) {
      if (i != activeIdx &&
          i != stack1Idx &&
          i != stack2Idx &&
          i != stack3Idx &&
          i != exitingIdx) {
        renderOrder.add(i);
      }
    }

    if (!renderOrder.contains(stack3Idx)) {
      renderOrder.add(stack3Idx);
    }
    if (!renderOrder.contains(stack2Idx)) {
      renderOrder.add(stack2Idx);
    }
    if (!renderOrder.contains(stack1Idx)) {
      renderOrder.add(stack1Idx);
    }
    if (!renderOrder.contains(activeIdx)) {
      renderOrder.add(activeIdx);
    }
    if (exitingIdx != null && !renderOrder.contains(exitingIdx)) {
      renderOrder.add(exitingIdx);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: renderOrder.map((index) {
        final movie = _movies[index];
        final state = _calculateCardState(index, total, t);

        if (state.opacity <= 0.01) {
          return const SizedBox.shrink();
        }

        return Positioned(
          left: state.x,
          top: 0,
          child: Opacity(
            opacity: state.opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: state.scale,
              alignment: Alignment.centerLeft,
              child: _CompactHeroPosterCard(
                movie: movie,
                isFront: index == _currentIndex && _exitingIndex == null,
                overlayColor: Colors.black
                    .withOpacity(state.overlayOpacity.clamp(0.0, 1.0)),
                playBtnOpacity: state.playBtnOpacity.clamp(0.0, 1.0),
                onTap: () {
                  if (index != _currentIndex) {
                    _jumpToSlide(index);
                  } else {
                    widget.onTap?.call(movie);
                  }
                },
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Calculates interpolation state for 4-card stack layout
  _CardAnimationState _calculateCardState(int index, int total, double t) {
    final bool isAnimating = _animController.isAnimating;

    // ── 1. EXITING CARD: slides smoothly off to the left ───────────────────
    if (isAnimating && index == _exitingIndex) {
      if (_isReversing) {
        return _CardAnimationState(
          x: lerpDouble(0.0, 52.0, t)!,
          scale: lerpDouble(1.0, 0.90, t)!,
          opacity: 1.0,
          overlayOpacity: lerpDouble(0.0, 0.35, t)!,
          playBtnOpacity: lerpDouble(1.0, 0.0, t)!,
        );
      } else {
        return _CardAnimationState(
          x: lerpDouble(0.0, -120.0, t)!,
          scale: lerpDouble(1.0, 0.90, t)!,
          opacity: lerpDouble(1.0, 0.0, t)!,
          overlayOpacity: 0.0,
          playBtnOpacity: lerpDouble(1.0, 0.0, t)!,
        );
      }
    }

    final int offset = (index - _currentIndex + total) % total;

    // ── 2. ANIMATING TRANSITIONS FOR 4 VISIBLE POSTERS ──────────────────────
    if (isAnimating) {
      if (!_isReversing) {
        // Forward: offset 0 was at offset 1 (52px -> 0px)
        if (offset == 0) {
          return _CardAnimationState(
            x: lerpDouble(52.0, 0.0, t)!,
            scale: lerpDouble(0.90, 1.0, t)!,
            opacity: 1.0,
            overlayOpacity: lerpDouble(0.35, 0.0, t)!,
            playBtnOpacity: lerpDouble(0.0, 1.0, t)!,
          );
        }
        // Forward: offset 1 was at offset 2 (100px -> 52px)
        if (offset == 1) {
          return _CardAnimationState(
            x: lerpDouble(100.0, 52.0, t)!,
            scale: lerpDouble(0.80, 0.90, t)!,
            opacity: 1.0,
            overlayOpacity: lerpDouble(0.55, 0.35, t)!,
            playBtnOpacity: 0.0,
          );
        }
        // Forward: offset 2 was at offset 3 (144px -> 100px)
        if (offset == 2) {
          return _CardAnimationState(
            x: lerpDouble(144.0, 100.0, t)!,
            scale: lerpDouble(0.70, 0.80, t)!,
            opacity: 1.0,
            overlayOpacity: lerpDouble(0.70, 0.55, t)!,
            playBtnOpacity: 0.0,
          );
        }
        // Forward: offset 3 was in hidden queue (190px -> 144px)
        if (offset == 3) {
          return _CardAnimationState(
            x: lerpDouble(190.0, 144.0, t)!,
            scale: lerpDouble(0.55, 0.70, t)!,
            opacity: lerpDouble(0.0, 1.0, t)!,
            overlayOpacity: lerpDouble(0.85, 0.70, t)!,
            playBtnOpacity: 0.0,
          );
        }
      } else {
        // Reverse transitions
        if (offset == 0) {
          return _CardAnimationState(
            x: lerpDouble(-120.0, 0.0, t)!,
            scale: lerpDouble(0.90, 1.0, t)!,
            opacity: lerpDouble(0.0, 1.0, t)!,
            overlayOpacity: 0.0,
            playBtnOpacity: lerpDouble(0.0, 1.0, t)!,
          );
        }
        if (offset == 1) {
          return _CardAnimationState(
            x: lerpDouble(0.0, 52.0, t)!,
            scale: lerpDouble(1.0, 0.90, t)!,
            opacity: 1.0,
            overlayOpacity: lerpDouble(0.0, 0.35, t)!,
            playBtnOpacity: lerpDouble(1.0, 0.0, t)!,
          );
        }
        if (offset == 2) {
          return _CardAnimationState(
            x: lerpDouble(52.0, 100.0, t)!,
            scale: lerpDouble(0.90, 0.80, t)!,
            opacity: 1.0,
            overlayOpacity: lerpDouble(0.35, 0.55, t)!,
            playBtnOpacity: 0.0,
          );
        }
        if (offset == 3) {
          return _CardAnimationState(
            x: lerpDouble(100.0, 144.0, t)!,
            scale: lerpDouble(0.80, 0.70, t)!,
            opacity: 1.0,
            overlayOpacity: lerpDouble(0.55, 0.70, t)!,
            playBtnOpacity: 0.0,
          );
        }
      }
    }

    // ── 3. STATIC / IDLE STATES FOR 4 POSTERS ───────────────────────────────
    if (offset == 0) {
      // 1. ACTIVE FRONT CARD
      return const _CardAnimationState(
        x: 0.0,
        scale: 1.0,
        opacity: 1.0,
        overlayOpacity: 0.0,
        playBtnOpacity: 1.0,
      );
    } else if (offset == 1) {
      // 2. FIRST CARD IN STACK
      return const _CardAnimationState(
        x: 52.0,
        scale: 0.90,
        opacity: 1.0,
        overlayOpacity: 0.35,
        playBtnOpacity: 0.0,
      );
    } else if (offset == 2) {
      // 3. SECOND CARD IN STACK
      return const _CardAnimationState(
        x: 100.0,
        scale: 0.80,
        opacity: 1.0,
        overlayOpacity: 0.55,
        playBtnOpacity: 0.0,
      );
    } else if (offset == 3) {
      // 4. THIRD CARD IN STACK (Purple outline in user markup)
      return const _CardAnimationState(
        x: 144.0,
        scale: 0.70,
        opacity: 1.0,
        overlayOpacity: 0.70,
        playBtnOpacity: 0.0,
      );
    } else {
      // 5. HIDDEN CARDS
      return const _CardAnimationState(
        x: 190.0,
        scale: 0.55,
        opacity: 0.0,
        overlayOpacity: 0.85,
        playBtnOpacity: 0.0,
      );
    }
  }

  String _getMovieSubtitle(Movie movie) {
    if (movie.title.toLowerCase().contains('oppenheimer') || movie.id == 872585) {
      return 'Biography • 180 mins';
    }
    if (movie.id == 693134 || movie.title.toLowerCase().contains('dune')) {
      return 'Sci-Fi • 166 mins';
    }
    if (movie.id == 603692 || movie.title.toLowerCase().contains('wick')) {
      return 'Action • 169 mins';
    }
    if (movie.id == 569094 || movie.title.toLowerCase().contains('spider')) {
      return 'Animation • 140 mins';
    }
    if (movie.id == 533535 || movie.title.toLowerCase().contains('deadpool')) {
      return 'Action • 128 mins';
    }
    final year = movie.year.isNotEmpty ? movie.year : '2026';
    return 'Action, Drama • $year';
  }
}

class _CardAnimationState {
  final double x;
  final double scale;
  final double opacity;
  final double overlayOpacity;
  final double playBtnOpacity;

  const _CardAnimationState({
    required this.x,
    required this.scale,
    required this.opacity,
    required this.overlayOpacity,
    required this.playBtnOpacity,
  });
}

/// Compact Hero Poster Card matching the yellow line height reduction (~242px)
/// and removing artificial text overlay on the poster artwork
class _CompactHeroPosterCard extends ConsumerWidget {
  final Movie movie;
  final bool isFront;
  final Color overlayColor;
  final double playBtnOpacity;
  final VoidCallback onTap;

  const _CompactHeroPosterCard({
    required this.movie,
    required this.isFront,
    required this.overlayColor,
    required this.playBtnOpacity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(favoritesProvider.notifier).isFavorite(movie.id);

    final posterUrl = movie.posterPath != null && movie.posterPath!.isNotEmpty
        ? (movie.posterPath!.startsWith('http')
            ? movie.posterPath!
            : '${ApiConstants.posterW500}${movie.posterPath}')
        : null;

    final ratingDisplay = movie.voteAverage > 0
        ? movie.voteAverage.toStringAsFixed(1)
        : '7.5';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 162,
        height: 242,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF111827),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.75),
              blurRadius: 22,
              spreadRadius: -6,
              offset: const Offset(-8, 0),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── 1. Clean Poster Image without text overlay ─────────────────
              posterUrl != null
                  ? CachedNetworkImage(
                      imageUrl: posterUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: const Color(0xFF111827),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFF111827),
                        child: const Icon(Icons.movie_rounded,
                            color: Colors.white24, size: 36),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF111827),
                      child: const Icon(Icons.movie_rounded,
                          color: Colors.white24, size: 36),
                    ),

              // ── 2. Dynamic Dimming Overlay based on Depth ─────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 750),
                curve: Curves.ease,
                color: overlayColor,
              ),

              // ── 3. Bookmark Button (Top Left) ─────────────────────────────
              Positioned(
                top: 10,
                left: 10,
                child: GestureDetector(
                  onTap: () {
                    ref.read(favoritesProvider.notifier).toggleFavorite(movie);
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                            width: 0.8,
                          ),
                        ),
                        child: Icon(
                          isFav ? IconlyBold.bookmark : IconlyLight.bookmark,
                          color: isFav ? const Color(0xFF34D399) : Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── 4. Rating Badge (Top Right) ───────────────────────────────
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34D399),
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF34D399).withOpacity(0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFF111827),
                        size: 11.5,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        ratingDisplay,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 5. Circular Play Button (Center) ──────────────────────────
              if (playBtnOpacity > 0.01)
                Positioned.fill(
                  child: Center(
                    child: Opacity(
                      opacity: playBtnOpacity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.25),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.30),
                                width: 1.2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 14,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Padding(
                                padding: EdgeInsets.only(left: 2),
                                child: Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Movie Logo widget: loads official transparent PNG logo from TMDB images endpoint
/// or falls back to bold stylized typography
class _MovieLogoWidget extends ConsumerWidget {
  final Movie movie;

  const _MovieLogoWidget({required this.movie});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logoAsync = ref.watch(movieLogoProvider(movie.id));

    return logoAsync.when(
      data: (logoUrl) {
        if (logoUrl != null && logoUrl.isNotEmpty) {
          return SizedBox(
            height: 34,
            child: CachedNetworkImage(
              imageUrl: logoUrl,
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
              errorWidget: (_, __, ___) => _buildTextTitle(),
            ),
          );
        }
        return _buildTextTitle();
      },
      loading: () => _buildTextTitle(),
      error: (_, __) => _buildTextTitle(),
    );
  }

  Widget _buildTextTitle() {
    return Text(
      movie.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 19,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.3,
      ),
    );
  }
}

import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconly/iconly.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/movie.dart';
import '../../favorites/presentation/providers/favorites_provider.dart';

/// Asymmetric Stacked Hero Banner Carousel built with exact math and layout
/// from the user's HTML/CSS specification:
/// - Active card aligned on the left at translateX(0px), scale(1.0), zIndex: 40
/// - First stack card on the right at translateX(85px), scale(0.88), overlay: 0.40, zIndex: 30
/// - Second stack card further right at translateX(155px), scale(0.76), overlay: 0.60, zIndex: 20
/// - Exiting card slides smoothly left to translateX(-150px), scale(0.90), fading to opacity 0, zIndex: 50
/// - Hidden queue cards wait at translateX(220px), scale(0.60), opacity: 0
/// - Autoplays every 3.5 seconds with cubic ease curve Cubic(0.19, 1.0, 0.22, 1.0)
/// - Left-aligned movie title + genre/duration and elongated white pill pagination dots
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

    // Sync Text Details with Fade effect matching HTML setTimeout 300ms
    Future.delayed(const Duration(milliseconds: 300), () {
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

    Future.delayed(const Duration(milliseconds: 300), () {
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
    Future.delayed(const Duration(milliseconds: 300), () {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Stacked Card Deck Container (HTML #slider-container) ───────────
        GestureDetector(
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0.0;
            if (velocity < -200) {
              _nextSlide();
              _resetAutoplay();
            } else if (velocity > 200) {
              _prevSlide();
              _resetAutoplay();
            }
          },
          child: Container(
            height: 395,
            width: double.infinity,
            padding: const EdgeInsets.only(left: 28),
            clipBehavior: Clip.none,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) => _buildStackedCards(),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Bottom Information Row (HTML text-wrapper & pagination-dots) ─────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title and Genre • Duration
              Expanded(
                child: AnimatedOpacity(
                  opacity: _textOpacity,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentMovie.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.4,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getMovieSubtitle(currentMovie),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF7A7C85),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Pagination Dots (HTML #pagination-dots)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_movies.length, (i) {
                  final isActive = i == _currentIndex;
                  return GestureDetector(
                    onTap: () => _jumpToSlide(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.only(left: 6),
                      height: 6,
                      width: isActive ? 24 : 6,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : const Color(0xFF4B4D56),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds cards in exact z-index order matching HTML animation model
  Widget _buildStackedCards() {
    final total = _movies.length;
    final t = const Cubic(0.19, 1.0, 0.22, 1.0)
        .transform(_animController.value);

    // List of card indices to render ordered by z-index (lowest to highest)
    // In Flutter Stack, later children render on top.
    // HTML zIndex order:
    // 10: Hidden cards
    // 20: Offset 2 card
    // 30: Offset 1 card
    // 40: Active front card (Offset 0)
    // 50: Exiting card (slides over front card)
    final List<int> renderOrder = [];

    // Find indices for each offset
    int? activeIdx = _currentIndex;
    int? stack1Idx = (_currentIndex + 1) % total;
    int? stack2Idx = (_currentIndex + 2) % total;
    int? exitingIdx = _exitingIndex;

    // Add other hidden background cards first
    for (int i = 0; i < total; i++) {
      if (i != activeIdx &&
          i != stack1Idx &&
          i != stack2Idx &&
          i != exitingIdx) {
        renderOrder.add(i);
      }
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
              child: _HtmlStyledMovieCard(
                movie: movie,
                isFront: index == _currentIndex && _exitingIndex == null,
                overlayColor: Colors.black.withOpacity(state.overlayOpacity.clamp(0.0, 1.0)),
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

  /// Calculates interpolation state based on HTML offsets
  _CardAnimationState _calculateCardState(int index, int total, double t) {
    final bool isAnimating = _animController.isAnimating;

    // ── 1. EXITING CARD: slides smoothly off to the left ───────────────────
    if (isAnimating && index == _exitingIndex) {
      if (_isReversing) {
        // Exiting when going backwards: slides from 0 to 85px
        return _CardAnimationState(
          x: lerpDouble(0.0, 85.0, t)!,
          scale: lerpDouble(1.0, 0.88, t)!,
          opacity: 1.0,
          overlayOpacity: lerpDouble(0.0, 0.40, t)!,
          playBtnOpacity: lerpDouble(1.0, 0.0, t)!,
        );
      } else {
        // Standard forward exit: slides from 0 to -150px, fades to 0
        return _CardAnimationState(
          x: lerpDouble(0.0, -150.0, t)!,
          scale: lerpDouble(1.0, 0.90, t)!,
          opacity: lerpDouble(1.0, 0.0, t)!,
          overlayOpacity: 0.0,
          playBtnOpacity: lerpDouble(1.0, 0.0, t)!,
        );
      }
    }

    // Offset relative to current active index in circular array
    final int offset = (index - _currentIndex + total) % total;

    // ── 2. ANIMATING TRANSITION FOR INCOMING/SHIFTING CARDS ────────────────
    if (isAnimating) {
      if (!_isReversing) {
        // Forward: index at offset 0 was at offset 1 (85px -> 0px)
        if (offset == 0) {
          return _CardAnimationState(
            x: lerpDouble(85.0, 0.0, t)!,
            scale: lerpDouble(0.88, 1.0, t)!,
            opacity: 1.0,
            overlayOpacity: lerpDouble(0.40, 0.0, t)!,
            playBtnOpacity: lerpDouble(0.0, 1.0, t)!,
          );
        }
        // Forward: index at offset 1 was at offset 2 (155px -> 85px)
        if (offset == 1) {
          return _CardAnimationState(
            x: lerpDouble(155.0, 85.0, t)!,
            scale: lerpDouble(0.76, 0.88, t)!,
            opacity: 1.0,
            overlayOpacity: lerpDouble(0.60, 0.40, t)!,
            playBtnOpacity: 0.0,
          );
        }
        // Forward: index at offset 2 was in hidden queue (220px -> 155px)
        if (offset == 2) {
          return _CardAnimationState(
            x: lerpDouble(220.0, 155.0, t)!,
            scale: lerpDouble(0.60, 0.76, t)!,
            opacity: lerpDouble(0.0, 1.0, t)!,
            overlayOpacity: lerpDouble(0.80, 0.60, t)!,
            playBtnOpacity: 0.0,
          );
        }
      } else {
        // Reverse: index at offset 0 was exiting left (-150px -> 0px)
        if (offset == 0) {
          return _CardAnimationState(
            x: lerpDouble(-150.0, 0.0, t)!,
            scale: lerpDouble(0.90, 1.0, t)!,
            opacity: lerpDouble(0.0, 1.0, t)!,
            overlayOpacity: 0.0,
            playBtnOpacity: lerpDouble(0.0, 1.0, t)!,
          );
        }
        // Reverse: index at offset 1 was at offset 0 (0px -> 85px)
        if (offset == 1) {
          return _CardAnimationState(
            x: lerpDouble(0.0, 85.0, t)!,
            scale: lerpDouble(1.0, 0.88, t)!,
            opacity: 1.0,
            overlayOpacity: lerpDouble(0.0, 0.40, t)!,
            playBtnOpacity: lerpDouble(1.0, 0.0, t)!,
          );
        }
        // Reverse: index at offset 2 was at offset 1 (85px -> 155px)
        if (offset == 2) {
          return _CardAnimationState(
            x: lerpDouble(85.0, 155.0, t)!,
            scale: lerpDouble(0.88, 0.76, t)!,
            opacity: 1.0,
            overlayOpacity: lerpDouble(0.40, 0.60, t)!,
            playBtnOpacity: 0.0,
          );
        }
      }
    }

    // ── 3. STATIC / IDLE STATES FROM USER'S HTML CODE ───────────────────────
    if (offset == 0) {
      // 1. ACTIVE FRONT CARD
      // card.style.transform = 'translateX(0px) scale(1)'; opacity = 1
      return const _CardAnimationState(
        x: 0.0,
        scale: 1.0,
        opacity: 1.0,
        overlayOpacity: 0.0,
        playBtnOpacity: 1.0,
      );
    } else if (offset == 1) {
      // 2. FIRST CARD IN STACK (Right)
      // card.style.transform = 'translateX(85px) scale(0.88)'; opacity = 1, overlay 0.4
      return const _CardAnimationState(
        x: 85.0,
        scale: 0.88,
        opacity: 1.0,
        overlayOpacity: 0.40,
        playBtnOpacity: 0.0,
      );
    } else if (offset == 2) {
      // 3. SECOND CARD IN STACK (Further Right)
      // card.style.transform = 'translateX(155px) scale(0.76)'; opacity = 1, overlay 0.6
      return const _CardAnimationState(
        x: 155.0,
        scale: 0.76,
        opacity: 1.0,
        overlayOpacity: 0.60,
        playBtnOpacity: 0.0,
      );
    } else {
      // 5. HIDDEN CARDS
      // card.style.transform = 'translateX(220px) scale(0.6)'; opacity = 0
      return const _CardAnimationState(
        x: 220.0,
        scale: 0.60,
        opacity: 0.0,
        overlayOpacity: 0.80,
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
    final year = movie.year.isNotEmpty ? movie.year : '2024';
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

/// Exact Card HTML & CSS representation:
/// w-[260px] h-[390px] rounded-[28px] overflow-hidden bg-gray-900 card-shadow
class _HtmlStyledMovieCard extends ConsumerWidget {
  final Movie movie;
  final bool isFront;
  final Color overlayColor;
  final double playBtnOpacity;
  final VoidCallback onTap;

  const _HtmlStyledMovieCard({
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
        : '9.2';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 260,
        height: 390,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: const Color(0xFF111827), // bg-gray-900
          boxShadow: [
            // Deep shadow from CSS: -15px 0 35px -10px rgba(0,0,0,0.8), 0 12px 24px rgba(0,0,0,0.6)
            BoxShadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 35,
              spreadRadius: -10,
              offset: const Offset(-15, 0),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── 1. Poster Image (background-image: url('${movie.image}')) ──
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
                            color: Colors.white24, size: 48),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF111827),
                      child: const Icon(Icons.movie_rounded,
                          color: Colors.white24, size: 48),
                    ),

              // ── 2. Dynamic Dimming Overlay based on Depth ─────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 750),
                curve: Curves.ease,
                color: overlayColor,
              ),

              // ── 3. Bookmark Icon (Top Left HTML) ──────────────────────────
              // w-9 h-9 bg-white/20 backdrop-blur-md rounded-xl border border-white/10
              Positioned(
                top: 16,
                left: 16,
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
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                            width: 1,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          isFav ? IconlyBold.bookmark : IconlyLight.bookmark,
                          color: isFav ? const Color(0xFF34D399) : Colors.white,
                          size: 17,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── 4. Rating Badge (Top Right HTML) ──────────────────────────
              // bg-emerald-400 text-gray-900 px-2.5 py-1.5 rounded-lg text-[13px] font-bold shadow-lg
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34D399), // Tailwind bg-emerald-400
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF34D399).withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFF111827), // text-gray-900
                        size: 15,
                      ),
                      const SizedBox(width: 3.5),
                      Text(
                        ratingDisplay,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 5. Play Button (Center HTML) ──────────────────────────────
              // w-16 h-16 bg-white/25 backdrop-blur-md rounded-full border border-white/30 shadow-xl
              if (playBtnOpacity > 0.01)
                Positioned.fill(
                  child: Center(
                    child: Opacity(
                      opacity: playBtnOpacity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.25),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.30),
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 20,
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
                  ),
                ),

              // ── 6. Superimposed Title at bottom of card ───────────────────
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Text(
                  movie.title.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 8,
                        offset: Offset(0, 2),
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
}

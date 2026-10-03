import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/shimmer_loading.dart';
import 'providers/home_providers.dart';
import 'widgets/hero_banner.dart';
import 'widgets/movie_section.dart';
import 'widgets/floating_nav_bar.dart';
import 'widgets/vj_section.dart';
import 'widgets/vj_movies_sheet.dart';
import '../../data/mock/mock_movies.dart';
import '../../data/models/movie.dart';
import '../movie_detail/presentation/screens/movie_detail_screen.dart';
import '../search/presentation/screens/search_screen.dart';
import '../favorites/presentation/screens/favorites_screen.dart';
import '../profile/presentation/screens/profile_screen.dart';
import '../notifications/presentation/screens/notifications_screen.dart';

/// Main Application Shell & Home Screen with persistent top bar across all tabs
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedNavIndex = 0;

  void _openMovieDetail(Movie movie) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MovieDetailScreen(movie: movie),
      ),
    );
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // ── Top Header / App Bar (Consistently visible across ALL pages) ─
                _FreeWatchTopAppBar(
                  onSearchTap: () => setState(() => _selectedNavIndex = 1),
                  onNotificationTap: _openNotifications,
                ),

                // ── Tab View ──────────────────────────────────────────
                Expanded(
                  child: IndexedStack(
                    index: _selectedNavIndex,
                    children: [
                      // Tab 0: Home Feed
                      _buildHomeFeed(context),

                      // Tab 1: Dedicated Search Screen
                      const SearchScreen(),

                      // Tab 2: Dedicated Favorites / Watchlist Screen
                      FavoritesScreen(
                        onExploreTap: () => setState(() => _selectedNavIndex = 0),
                      ),

                      // Tab 3: Dedicated Profile Screen
                      const ProfileScreen(),
                    ],
                  ),
                ),
              ],
            ),

            // ── Floating Bottom Navigation Pill ──────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingNavBar(
                selectedIndex: _selectedNavIndex,
                onItemSelected: (index) {
                  setState(() => _selectedNavIndex = index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 0: Home Feed ───────────────────────────────────────────────────────
  Widget _buildHomeFeed(BuildContext context) {
    final trendingAsync = ref.watch(trendingMoviesProvider);
    final latestToRewatchAsync = ref.watch(latestToRewatchProvider);
    final latestUploadsAsync = ref.watch(latestUploadsProvider);
    final seriesAsync = ref.watch(seriesProvider);
    final actionAsync = ref.watch(actionMoviesProvider);
    final sciFiAsync = ref.watch(sciFiMoviesProvider);
    final romanceAsync = ref.watch(romanceMoviesProvider);
    final horrorAsync = ref.watch(horrorMoviesProvider);
    final dramaAsync = ref.watch(dramaMoviesProvider);
    final animationAsync = ref.watch(animationMoviesProvider);
    final familyAsync = ref.watch(familyMoviesProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 6)),

        // ── Hero Banner Carousel ───────────────────────────────────
        SliverToBoxAdapter(
          child: trendingAsync.when(
            data: (movies) => HeroBanner(
              movies: movies,
              onTap: _openMovieDetail,
              onSeeAll: () => setState(() => _selectedNavIndex = 1),
            ),
            loading: () => const HeroBannerShimmer(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // ── "Available Vj's" Section (Directly Below Hero) ──────────
        SliverToBoxAdapter(
          child: VjSection(
            vjs: MockData.vjs,
            onVjTap: (vj) {
              VjMoviesSheet.show(
                context,
                vj: vj,
                onMovieTap: _openMovieDetail,
              );
            },
            onSeeAll: () {
              if (MockData.vjs.isNotEmpty) {
                VjMoviesSheet.show(
                  context,
                  vj: MockData.vjs.first,
                  onMovieTap: _openMovieDetail,
                );
              }
            },
          ),
        ),

        // ── Branded Section Titles with Taglines ─────────────────
        _buildMovieSection(
          context,
          title: 'Rewind & Relive',
          subtitle: 'Timeless fan favorites you can watch over and over',
          asyncValue: latestToRewatchAsync,
        ),

        _buildMovieSection(
          context,
          title: 'Fresh Drops',
          subtitle: 'Brand new releases hot off the studio reel',
          asyncValue: latestUploadsAsync,
        ),

        _buildMovieSection(
          context,
          title: 'Binge Central',
          subtitle: 'Full seasons & episodes ready to stream',
          asyncValue: seriesAsync,
        ),

        _buildMovieSection(
          context,
          title: 'High Octane',
          subtitle: 'Adrenaline-pumping blockbusters & combat sagas',
          asyncValue: actionAsync,
        ),

        _buildMovieSection(
          context,
          title: 'Beyond Reality',
          subtitle: 'Mind-bending futuristic thrillers & cosmic voyages',
          asyncValue: sciFiAsync,
        ),

        _buildMovieSection(
          context,
          title: 'Love Stories',
          subtitle: 'Touching romances & heartfelt emotional tales',
          asyncValue: romanceAsync,
        ),

        _buildMovieSection(
          context,
          title: 'Night Terrors',
          subtitle: 'Spine-chilling scares & supernatural suspense',
          asyncValue: horrorAsync,
        ),

        _buildMovieSection(
          context,
          title: 'Masterpiece Cinema',
          subtitle: 'Award-winning stories and profound human drama',
          asyncValue: dramaAsync,
        ),

        _buildMovieSection(
          context,
          title: 'Animated Realms',
          subtitle: 'Vibrant Disney & animated hits for everyone',
          asyncValue: animationAsync,
        ),

        _buildMovieSection(
          context,
          title: 'Family Magic',
          subtitle: 'Wholesome adventures crafted for all ages',
          asyncValue: familyAsync,
        ),

        // ── Space for Floating Nav Bar ────────────────────────────
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildMovieSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required AsyncValue<List<Movie>> asyncValue,
  }) {
    return SliverToBoxAdapter(
      child: asyncValue.when(
        data: (movies) {
          if (movies.isEmpty) return const SizedBox.shrink();
          return MovieSection(
            title: title,
            subtitle: subtitle,
            movies: movies,
            onMovieTap: _openMovieDetail,
            onSeeAll: () => setState(() => _selectedNavIndex = 1),
          );
        },
        loading: () => MovieSection(
          title: title,
          subtitle: subtitle,
          isLoading: true,
        ),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}

// ── Persistent Top App Bar ───────────────────────────────────────────────────

class _FreeWatchTopAppBar extends StatelessWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onNotificationTap;

  const _FreeWatchTopAppBar({
    required this.onSearchTap,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 12, 6),
      child: Row(
        children: [
          // ── Brand Logo ────────────────────────────────────────────────────
          Image.asset(
            'assets/images/logo_full.png',
            height: 48,
            fit: BoxFit.contain,
          ),

          const Spacer(),

          // ── Search Button ─────────────────────────────────────────────────
          IconButton(
            onPressed: onSearchTap,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            icon: const Icon(
              IconlyBold.search,
              color: AppColors.textPrimary,
              size: 24,
            ),
          ),

          const SizedBox(width: 14),

          // ── Notification Button with Badge ────────────────────────────────
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                onPressed: onNotificationTap,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                icon: const Icon(
                  IconlyBold.notification,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          // ── Cast Button ───────────────────────────────────────────────────
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  duration: Duration(milliseconds: 1000),
                  backgroundColor: Color(0xFF161922),
                  content: Text('Searching for Google Cast & AirPlay devices...',
                      style: TextStyle(color: Colors.white)),
                ),
              );
            },
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            icon: const Icon(
              Icons.cast_rounded,
              color: AppColors.textPrimary,
              size: 23,
            ),
          ),
        ],
      ),
    );
  }
}

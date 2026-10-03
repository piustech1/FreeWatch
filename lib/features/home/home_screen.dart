import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/shimmer_loading.dart';
import '../../shared/widgets/free_watch_top_app_bar.dart';
import 'providers/home_providers.dart';
import 'widgets/hero_banner.dart';
import 'widgets/movie_section.dart';
import 'widgets/floating_nav_bar.dart';
import 'widgets/vj_section.dart';
import '../../data/mock/mock_movies.dart';
import '../../data/models/movie.dart';
import '../movie_detail/presentation/screens/movie_detail_screen.dart';
import '../movie_grid/presentation/screens/movie_grid_screen.dart';
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
    final selectedNavIndex = ref.watch(bottomNavIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // ── Top Header / App Bar (Visible on Home Feed tab) ────────────────
                if (selectedNavIndex == 0)
                  FreeWatchTopAppBar(
                    onSearchTap: () => navigateToBottomNavTab(context, ref, 1),
                    onNotificationTap: _openNotifications,
                  ),

                // ── Tab View ──────────────────────────────────────────
                Expanded(
                  child: IndexedStack(
                    index: selectedNavIndex,
                    children: [
                      // Tab 0: Home Feed
                      _buildHomeFeed(context),

                      // Tab 1: Dedicated Search Screen
                      const SearchScreen(),

                      // Tab 2: Dedicated Favorites / Watchlist Screen
                      FavoritesScreen(
                        onExploreTap: () => navigateToBottomNavTab(context, ref, 0),
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
                selectedIndex: selectedNavIndex,
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
              onSeeAll: () {
                Navigator.of(context).push(
                  MovieGridScreen.routeForCategory(
                    title: 'Trending',
                    movies: movies,
                  ),
                );
              },
            ),
            loading: () => const HeroBannerShimmer(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        // ── "Available Vj's" Section (Directly Below Hero) ──────────
        SliverToBoxAdapter(
          child: VjSection(
            vjs: MockData.vjs,
            onVjTap: (vj) {
              Navigator.of(context).push(
                MovieGridScreen.routeForVj(vj: vj),
              );
            },
            onSeeAll: () {
              Navigator.of(context).push(
                MovieGridScreen.routeForCategory(
                  title: 'All VJ Movies',
                  movies: MockData.getAllMovies(),
                ),
              );
            },
          ),
        ),

        // ── Branded Section Titles with Taglines & View All ──────────
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
            onSeeAll: () {
              Navigator.of(context).push(
                MovieGridScreen.routeForCategory(
                  title: title,
                  movies: movies,
                ),
              );
            },
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

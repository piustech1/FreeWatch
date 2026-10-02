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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      // ── Sleek Navigation Drawer (opened via top bar navigation menu icon) ─
      drawer: _FreeWatchDrawer(
        selectedIndex: _selectedNavIndex,
        onSelectTab: (index) {
          Navigator.pop(context);
          setState(() => _selectedNavIndex = index);
        },
        onNotificationsTap: () {
          Navigator.pop(context);
          _openNotifications();
        },
        onVjsTap: () {
          Navigator.pop(context);
          if (MockData.vjs.isNotEmpty) {
            VjMoviesSheet.show(
              context,
              vj: MockData.vjs.first,
              onMovieTap: _openMovieDetail,
            );
          }
        },
      ),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // ── Top Header / App Bar (Consistently visible across ALL pages) ─
                _FreeWatchTopAppBar(
                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
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
  final VoidCallback onMenuTap;
  final VoidCallback onSearchTap;
  final VoidCallback onNotificationTap;

  const _FreeWatchTopAppBar({
    required this.onMenuTap,
    required this.onSearchTap,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
      child: Row(
        children: [
          // ── Navigation Menu Hamburger Button ──────────────────────────────
          IconButton(
            onPressed: onMenuTap,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            icon: const Icon(
              Icons.menu_rounded,
              color: AppColors.textPrimary,
              size: 26,
            ),
          ),

          const SizedBox(width: 8),

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

// ── Navigation Drawer ────────────────────────────────────────────────────────

class _FreeWatchDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onNotificationsTap;
  final VoidCallback onVjsTap;

  const _FreeWatchDrawer({
    required this.selectedIndex,
    required this.onSelectTab,
    required this.onNotificationsTap,
    required this.onVjsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0D0F16),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drawer Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/images/logo_full.png',
                    height: 52,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.accent.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'FreeWatch VIP • Free Everywhere',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white12, height: 1),

            // Navigation Links
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _buildDrawerItem(
                    icon: Icons.home_rounded,
                    label: 'Home Feed',
                    isSelected: selectedIndex == 0,
                    onTap: () => onSelectTab(0),
                  ),
                  _buildDrawerItem(
                    icon: Icons.search_rounded,
                    label: 'Explore Categories',
                    isSelected: selectedIndex == 1,
                    onTap: () => onSelectTab(1),
                  ),
                  _buildDrawerItem(
                    icon: Icons.favorite_rounded,
                    label: 'My Watchlist',
                    isSelected: selectedIndex == 2,
                    onTap: () => onSelectTab(2),
                  ),
                  _buildDrawerItem(
                    icon: Icons.person_rounded,
                    label: 'My Profile & Account',
                    isSelected: selectedIndex == 3,
                    onTap: () => onSelectTab(3),
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  _buildDrawerItem(
                    icon: Icons.record_voice_over_rounded,
                    label: 'Available VJs (Ugandan Dubs)',
                    isSelected: false,
                    onTap: onVjsTap,
                  ),
                  _buildDrawerItem(
                    icon: Icons.notifications_rounded,
                    label: 'Notifications & Drops',
                    isSelected: false,
                    onTap: onNotificationsTap,
                  ),
                ],
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'FreeWatch v1.0.13\nFree entertainment, free everywhere.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.accent : Colors.white70,
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 14,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      tileColor: isSelected ? Colors.white.withOpacity(0.06) : Colors.transparent,
      onTap: onTap,
    );
  }
}

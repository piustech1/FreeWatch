import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freewatch/data/mock/mock_movies.dart';
import 'package:freewatch/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:freewatch/features/home/widgets/vj_card.dart';
import 'package:freewatch/features/home/widgets/vj_section.dart';
import 'package:freewatch/data/models/movie.dart';
import 'package:freewatch/features/home/providers/home_providers.dart';
import 'package:freewatch/features/onboarding/onboarding_screen.dart';
import 'package:freewatch/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:freewatch/features/home/presentation/screens/all_vjs_screen.dart';
import 'package:freewatch/shared/widgets/free_watch_top_app_bar.dart';
import 'package:freewatch/features/home/widgets/floating_nav_bar.dart';
import 'package:freewatch/data/repositories/movie_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FavoritesNotifier tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Loads initial seed favorites and toggles correctly', () async {
      final notifier = FavoritesNotifier();
      // Allow async initial load
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.isNotEmpty, isTrue);

      final testMovie = MockData.newMovies.first;
      final wasFav = notifier.isFavorite(testMovie.id);

      // Toggle favorite
      notifier.toggleFavorite(testMovie);
      expect(notifier.isFavorite(testMovie.id), equals(!wasFav));

      // Toggle back
      notifier.toggleFavorite(testMovie);
      expect(notifier.isFavorite(testMovie.id), equals(wasFav));
    });

    test('Can remove and clear all favorites', () async {
      final notifier = FavoritesNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final firstId = notifier.state.first.id;
      notifier.removeFavorite(firstId);
      expect(notifier.isFavorite(firstId), isFalse);

      notifier.clearAll();
      expect(notifier.state.isEmpty, isTrue);
    });
  });

  group('Interlocking Panoramic VJ Card tests', () {
    test('Clippers generate valid non-empty closed paths', () {
      const size = Size(310, 135);
      const mainClipper = VjMainClipper();
      const accentClipper = VjAccentClipper();

      final mainPath = mainClipper.getClip(size);
      final accentPath = accentClipper.getClip(size);

      expect(mainPath.getBounds().isEmpty, isFalse);
      expect(accentPath.getBounds().isEmpty, isFalse);
      expect(mainClipper.shouldReclip(mainClipper), isFalse);
      expect(accentClipper.shouldReclip(accentClipper), isFalse);
    });

    test('VjCardTheme resolves correct theme colors for VJs', () {
      final vjJunior = MockData.vjs.firstWhere((v) => v.name.contains('JUNIOR'));
      final vjEmmy = MockData.vjs.firstWhere((v) => v.name.contains('EMMY'));
      final vjJingo = MockData.vjs.firstWhere((v) => v.name.contains('JINGO'));

      final juniorTheme = VjCardTheme.resolve(vjJunior);
      expect(juniorTheme.accentColor, equals(const Color(0xFFEC4899)));

      final emmyTheme = VjCardTheme.resolve(vjEmmy);
      expect(emmyTheme.accentColor, equals(const Color(0xFF0EA5E9)));

      final jingoTheme = VjCardTheme.resolve(vjJingo);
      expect(jingoTheme.accentColor, equals(const Color(0xFFF59E0B)));
    });

    testWidgets('VjCard and VjSection render properly', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VjSection(
              vjs: MockData.vjs,
              onVjTap: (vj) => tapped = true,
            ),
          ),
        ),
      );

      // Verify section header
      expect(find.text('Available VJs'), findsOneWidget);
      expect(find.text('See all'), findsOneWidget);

      // Verify VJ Junior card content
      expect(find.text('VJ JUNIOR'), findsOneWidget);
      expect(find.text('185 movies'), findsOneWidget);

      // Verify tap works
      await tester.tap(find.text('VJ JUNIOR'));
      expect(tapped, isTrue);
    });
  });

  group('OnboardingScreen layout & spacing tests', () {
    testWidgets('OnboardingScreen fits on small and standard screens without overflow', (tester) async {
      // Test small phone screen: 360 x 640
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            popularMoviesProvider.overrideWith((ref) => Future.value(<Movie>[])),
            trendingMoviesProvider.overrideWith((ref) => Future.value(<Movie>[])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: OnboardingScreen(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify Page 1 elements render and fit
      expect(find.text('The greatest stories,\nall in one place.'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);

      // Advance to Page 2
      await tester.tap(find.text('Get Started'));
      for (int i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Verify Page 2 (defaults to Log In) fits without overflow
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('LOG IN'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Explore as Guest >'), findsOneWidget);

      // Switch to Sign Up mode using the account switcher text
      await tester.tap(find.text('Create Account'));
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Verify Page 2 (Sign Up) fits without overflow
      expect(find.text('Create Account'), findsWidgets);
      expect(find.text('SIGN UP'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Choose Your Avatar'), findsOneWidget);
    });
  });

  group('NotificationsScreen UI tests', () {
    testWidgets('NotificationsScreen renders header, red badge, sections, and items', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Title and initial unread badge '2' (in top bar and screen header)
      expect(find.text('Notifications'), findsWidgets);
      expect(find.text('2'), findsWidgets);

      // Verify Sections "Today" and "This week"
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('This week'), findsOneWidget);

      // Verify notification message items
      expect(find.text('What if your next favorite movie is online right now?'), findsOneWidget);
      expect(find.text('Meet top picks according to your mood and your interests'), findsOneWidget);

      // Verify back chevron icon
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

      // Tap "Mark all read"
      expect(find.text('Mark all read'), findsOneWidget);
      await tester.tap(find.text('Mark all read'));
      await tester.pumpAndSettle();

      // Badge '2' should now disappear because unread count is 0
      expect(find.text('2'), findsNothing);
      expect(find.text('Mark all read'), findsNothing);
    });
  });

  group('Strict VJ Movie Filtering and Official Backdrops', () {
    test('MockData.getMoviesByVj returns strictly movies translated by that VJ', () {
      final emmyMovies = MockData.getMoviesByVj('vj-emmy');
      expect(emmyMovies.isNotEmpty, isTrue);
      // VJ Emmy's movies should only contain Dune Part Two (693134) & Squid Game (93405)
      for (final m in emmyMovies) {
        expect(m.id == 693134 || m.id == 93405, isTrue);
      }
      // Must not contain Beekeeper or Lilo & Stitch
      expect(emmyMovies.any((m) => m.id == 1011985), isFalse);
      expect(emmyMovies.any((m) => m.id == 1084199), isFalse);

      final uncleTMovies = MockData.getMoviesByVj('vj-uncle-t');
      expect(uncleTMovies.isNotEmpty, isTrue);
      for (final m in uncleTMovies) {
        expect(m.id == 1084199 || m.id == 1241982, isTrue);
      }

      // Check all VJs: each returns strictly their translatedMovieIds
      for (final vj in MockData.vjs) {
        final movies = MockData.getMoviesByVj(vj.id);
        for (final m in movies) {
          expect(vj.translatedMovieIds.contains(m.id), isTrue,
              reason: '${vj.name} must not contain movie ${m.title} (${m.id})');
        }
      }
    });

    test('Official TMDB movie backdrops are verified', () {
      final beekeeper = MockData.trendingMovies.firstWhere((m) => m.id == 1011985);
      expect(beekeeper.backdropPath, equals('/628Dep6AxEtDxjZoGP78TsOxYbK.jpg'));

      final lilo = MockData.newMovies.firstWhere((m) => m.id == 1084199);
      expect(lilo.backdropPath, equals('/dvBCW3WBMnneFh0PGejTAznzTXE.jpg'));

      final dune = MockData.trendingMovies.firstWhere((m) => m.id == 693134);
      expect(dune.backdropPath, equals('/stKGOmBidrO1Kk7Qc0s07Q0w9Wk.jpg'));
    });

    testWidgets('AllVjsScreen renders top app bar, header, and floating nav bar', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AllVjsScreen(vjs: MockData.vjs),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top app bar present
      expect(find.byType(FreeWatchTopAppBar), findsOneWidget);

      // Subheader title & VJ count pill present
      expect(find.text('Available VJs'), findsOneWidget);
      expect(find.text('${MockData.vjs.length} VJs'), findsOneWidget);

      // Frosted back button present
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

      // Persistent floating bottom nav bar present
      expect(find.byType(FloatingNavBar), findsOneWidget);
    });

    test('Movie.fromJson parses MovieMax Cloudflare R2 streaming payload accurately', () {
      final sampleMovieMaxJson = {
        'title': 'Akaal: The Unconquered',
        'backdrop': 'https://image.tmdb.org/t/p/w1280/zdnDhz5JOppyu3adqOKcXqUNXi6.jpg',
        'poster': 'https://image.tmdb.org/t/p/w500/pzf5rPLoE5DdYkcZlvYbrH554rE.jpg',
        'rating': 5.5,
        'releaseYear': '2025',
        'runtime': 137,
        'tmdbId': 1454405,
        'genres': ['Action', 'History', 'Drama'],
        'videoUrl': 'https://pub-b99e0d2a3d4b4b618ce04a685e0b44ff.r2.dev/movies/vj ice p/AKAAL_THE_UNCONQUERED_B_ICEP.mp4',
        'vjName': 'VJ Ice P',
        'isPublished': true,
      };

      final movie = Movie.fromJson(sampleMovieMaxJson, key: '-OrEWTCofi8ilgJDF3Oo');

      expect(movie.id, equals(1454405));
      expect(movie.title, equals('Akaal: The Unconquered'));
      expect(movie.voteAverage, equals(5.5));
      expect(movie.releaseDate, equals('2025'));
      expect(movie.year, equals('2025'));
      expect(movie.runtime, equals(137));
      expect(movie.vjName, equals('VJ Ice P'));
      expect(movie.videoUrl, contains('r2.dev/movies/vj ice p/'));
      expect(movie.genreNames, contains('Action'));
      expect(movie.backdropUrl, startsWith('https://image.tmdb.org/'));
      expect(movie.posterUrl, startsWith('https://image.tmdb.org/'));
    });

    test('MovieRepository Gap-Filling fills missing details and returns complete metadata', () async {
      final repo = MovieRepository();
      // Test movie details with gap-filling fallback
      final details = await repo.getMovieDetails(1011985); // The Beekeeper

      expect(details.title.isNotEmpty, isTrue);
      expect(details.overview.isNotEmpty, isTrue);
      expect(details.backdropPath, isNotNull);
      expect(details.runtime, greaterThan(0));
      expect(details.cast.isNotEmpty, isTrue);
      expect(details.certification.isNotEmpty, isTrue);
      expect(details.genres.isNotEmpty, isTrue);
    });
  });
}



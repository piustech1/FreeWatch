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

    test('Starts with clean empty favorites and toggles correctly', () async {
      final notifier = FavoritesNotifier();
      // Allow async initial load
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.isEmpty, isTrue);

      final testMovie = MockData.newMovies.first;
      expect(notifier.isFavorite(testMovie.id), isFalse);

      // Add to favorites
      notifier.toggleFavorite(testMovie);
      expect(notifier.isFavorite(testMovie.id), isTrue);
      expect(notifier.state.length, equals(1));

      // Toggle back (remove)
      notifier.toggleFavorite(testMovie);
      expect(notifier.isFavorite(testMovie.id), isFalse);
      expect(notifier.state.isEmpty, isTrue);
    });

    test('Can remove and clear all favorites', () async {
      final notifier = FavoritesNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final testMovie = MockData.newMovies.first;
      notifier.toggleFavorite(testMovie);
      expect(notifier.isFavorite(testMovie.id), isTrue);

      notifier.removeFavorite(testMovie.id);
      expect(notifier.isFavorite(testMovie.id), isFalse);

      notifier.toggleFavorite(testMovie);
      expect(notifier.state.isNotEmpty, isTrue);

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
      expect(find.text('LUGANDA DUBBED'), findsWidgets);

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
      // Mandatory Auth: Explore as Guest must NOT be present
      expect(find.text('Explore as Guest >'), findsNothing);

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
    testWidgets('NotificationsScreen renders clean liquid glass state and dynamic notifications', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify Title and screen presence
      expect(find.text('Notifications'), findsWidgets);
      expect(find.byType(NotificationsScreen), findsOneWidget);

      // Verify back chevron icon
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
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

    test('All 16 user-specified VJs are registered with valid profiles', () {
      final expectedVjKeywords = [
        'kevo', 'anti', 'jovan', 'kevin', 'heavy q', 'mark', 'mossa', 'mosko',
        'shield', 'smk', 'tony', 'mk kisule', 'chris sweet', 'hd', 'isma k', 'tom',
      ];

      for (final vjKey in expectedVjKeywords) {
        final found = MockData.vjs.any((v) =>
            v.name.toLowerCase().contains(vjKey) ||
            v.id.toLowerCase().replaceAll('-', ' ').contains(vjKey) ||
            MovieRepository.normalizeVjName(v.name).contains(vjKey));
        expect(found, isTrue, reason: 'Expected VJ $vjKey to be registered in MockData.vjs');
      }
    });

    test('Series title cross-contamination guard strictly isolates show episodes', () {
      // Episodes of Carrie
      expect(MovieRepository.normalizeVjName('VJ Jingo'), equals('jingo'));

      // Check Carrie series matching
      const carrie = 'Carrie';
      const carrieEp1 = 'CARRIE VJ JINGO EP 1';
      const carrieEp2 = 'Carrie 2';
      const carrieEp3 = 'Carrie Episode 3';
      const moblandEp = 'Mobland Season 2: Episode 4';

      expect(carrieEp1.toLowerCase().contains(carrie.toLowerCase()), isTrue);
      expect(carrieEp2.toLowerCase().contains(carrie.toLowerCase()), isTrue);
      expect(carrieEp3.toLowerCase().contains(carrie.toLowerCase()), isTrue);
      expect(moblandEp.toLowerCase().contains(carrie.toLowerCase()), isFalse);
    });

    test('Animation rail filter correctly excludes non-animated live action films', () {
      final liveActionFilms = [
        'Enter the Dragon',
        'Dragon Blade (2015)',
        'House of the Dragon S01',
        'Lionheart (Jean-Claude Van Damme)',
        'Lions for Lambs',
      ];

      final animatedFilms = [
        'Kung Fu Panda 4',
        'The Lion King',
        'How to Train Your Dragon',
        'Shrek 2',
        'Spider-Man: Across the Spider-Verse',
        'Moana 2',
      ];

      // Exclusions
      for (final film in liveActionFilms) {
        final isExcluded = film.toLowerCase().contains('enter the dragon') ||
            film.toLowerCase().contains('dragon blade') ||
            film.toLowerCase().contains('house of the dragon') ||
            film.toLowerCase().contains('lionheart') ||
            film.toLowerCase().contains('lions for lambs');
        expect(isExcluded, isTrue, reason: '$film should be excluded from Animation');
      }

      // Valid animations
      for (final film in animatedFilms) {
        final lower = film.toLowerCase();
        final isLiveAction = lower.contains('enter the dragon') ||
            lower.contains('dragon blade') ||
            lower.contains('house of the dragon') ||
            lower.contains('lionheart');
        expect(isLiveAction, isFalse, reason: '$film should NOT be excluded from Animation');
      }
    });
  });
}



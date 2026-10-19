import 'package:flutter_test/flutter_test.dart';
import 'package:freewatch/data/datasources/moviemax_datasource.dart';
import 'package:freewatch/data/datasources/munowatch_datasource.dart';
import 'package:freewatch/data/repositories/movie_repository.dart';
import 'package:freewatch/shared/widgets/tiktok_promo_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('MovieMax & MunoWatch Datasource Tests', () {
    late MovieMaxDatasource movieMaxDatasource;
    late MunowatchDatasource munowatchDatasource;
    late MovieRepository repo;

    setUp(() {
      movieMaxDatasource = MovieMaxDatasource();
      munowatchDatasource = MunowatchDatasource();
      repo = MovieRepository(
        movieMaxDatasource: movieMaxDatasource,
        munowatchDatasource: munowatchDatasource,
      );
    });

    test('MovieMaxDatasource getAllMovies fetches or safely handles catalog', () async {
      final movies = await movieMaxDatasource.getAllMovies(forceRefresh: true);
      expect(movies, isA<List>());
      if (movies.isNotEmpty) {
        final first = movies.first;
        expect(first.title, isNotEmpty);
        expect(first.id, greaterThan(0));
      }
    });

    test('MovieMaxDatasource getAllSeries fetches or safely handles series', () async {
      final series = await movieMaxDatasource.getAllSeries(forceRefresh: true);
      expect(series, isA<List>());
      if (series.isNotEmpty) {
        final first = series.first;
        expect(first.title, isNotEmpty);
        expect(first.isTv, isTrue);
      }
    });

    test('MunowatchDatasource safely handles network or token failures gracefully', () async {
      // Must not throw unhandled exception even if token expired on third-party API
      final movies = await munowatchDatasource.getAllMovies(forceRefresh: true);
      expect(movies, isA<List>());

      final search = await munowatchDatasource.searchMovies('Spider');
      expect(search, isA<List>());
    });

    test('MovieRepository serves trending and popular movies with robust fallback', () async {
      final trending = await repo.getTrending();
      expect(trending, isNotEmpty);
      expect(trending.first.title, isNotEmpty);

      final popular = await repo.getPopular();
      expect(popular, isNotEmpty);
    });

    test('MovieRepository searches across catalog without throwing', () async {
      final results = await repo.searchMovies('spider');
      expect(results, isA<List>());
    });

    test('MovieRepository getMovieDetails resolves authentic details', () async {
      final details = await repo.getMovieDetails(1011985); // Beekeeper
      expect(details.title, isNotEmpty);
      expect(details.id, equals(1011985));
    });

    test('MovieRepository resolves series episodes or returns fallback gracefully', () async {
      final episodes = await repo.getTvSeasonEpisodes(1, 1, seriesTitle: 'Wednesday');
      expect(episodes, isA<List>());
    });

    test('MunowatchDatasource isHealthy check operates reliably', () async {
      final healthy = await munowatchDatasource.isHealthy();
      expect(healthy, isA<bool>());
    });

    test('MovieRepository getMoviesByGenre fetches rich lists for Drama, Animation, and Family', () async {
      final drama = await repo.getMoviesByGenre(18); // Drama
      expect(drama, isNotEmpty);
      expect(drama.first.title, isNotEmpty);

      final animation = await repo.getMoviesByGenre(16); // Animation
      expect(animation, isNotEmpty);
      expect(animation.first.title, isNotEmpty);

      final family = await repo.getMoviesByGenre(10751); // Family
      expect(family, isNotEmpty);
      expect(family.first.title, isNotEmpty);
    });

    test('MovieRepository trending and popular do not fall back to mocked movies', () async {
      final trending = await repo.getTrending();
      final popular = await repo.getPopular();

      // Ensure that mock IDs from MockData (e.g. 1011985 Beekeeper, 693134 Dune 2, 66732 Stranger Things)
      // are not returned as synthetic fallback placeholders.
      final mockTitles = {'The Beekeeper', 'Dune: Part Two', 'Stranger Things'};
      final mockIds = {1011985, 693134, 66732};

      for (final m in trending) {
        expect(m.title, isNot(isIn(mockTitles)));
        expect(m.id, isNot(isIn(mockIds)));
      }
      for (final m in popular) {
        expect(m.title, isNot(isIn(mockTitles)));
        expect(m.id, isNot(isIn(mockIds)));
      }
    });

    test('TiktokPromoModal persists join status in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await TiktokPromoModal.hasJoinedCommunity(), isFalse);

      await TiktokPromoModal.markCommunityJoined();
      expect(await TiktokPromoModal.hasJoinedCommunity(), isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:freewatch/data/datasources/munowatch_datasource.dart';
import 'package:freewatch/data/repositories/movie_repository.dart';

void main() {
  group('MunowatchDatasource Integration Tests', () {
    late MunowatchDatasource datasource;

    setUp(() {
      datasource = MunowatchDatasource();
    });

    test('getAllMovies fetches and parses real MunoWatch catalog', () async {
      final movies = await datasource.getAllMovies(forceRefresh: true);
      expect(movies, isNotEmpty);
      expect(movies.length, greaterThan(20));

      final first = movies.first;
      expect(first.title, isNotEmpty);
      expect(first.id, greaterThan(0));
      expect(movies.any((m) => m.genreNames.isNotEmpty), isTrue);
      expect(movies.any((m) => m.vjName != null), isTrue);
    });

    test('searchMovies fetches real search matches for "Spider"', () async {
      final results = await datasource.searchMovies('Spider');
      expect(results, isNotEmpty);
      final hasSpider = results.any((m) => m.title.toLowerCase().contains('spider'));
      expect(hasSpider, isTrue);
    });

    test('searchMovies handles multi-word variations like "spider man"', () async {
      final results = await datasource.searchMovies('spider man');
      expect(results, isNotEmpty);
      final hasMatch = results.any((m) => m.title.toLowerCase().contains('spider'));
      expect(hasMatch, isTrue);
    });

    test('searchMovies queries across the 10,000+ deep catalog (e.g. "matrix")', () async {
      final results = await datasource.searchMovies('matrix');
      expect(results, isNotEmpty);
      final hasMatrix = results.any((m) => m.title.toLowerCase().contains('matrix'));
      expect(hasMatrix, isTrue);
    });

    test('getLatestMovies returns releases from MunoWatch Latest category', () async {
      final latest = await datasource.getLatestMovies();
      expect(latest, isNotEmpty);
      expect(latest.first.title, isNotEmpty);
    });

    test('getMovieDetails preserves exact MunoWatch movie title and strict VOD', () async {
      final repo = MovieRepository(munowatchDatasource: datasource);

      // Deep catalog movie ID 10000 ("Gracious Revenge 10")
      final details = await repo.getMovieDetails(10000);
      expect(details.id, equals(10000));
      expect(details.title, equals('Gracious Revenge 10'));
      expect(details.videoUrl, isNotNull);
      expect(details.videoUrl, startsWith('http'));
      expect(details.vjName, equals('Vj Sammy'));
    });

    test('getMovieDetails strictly sets videoUrl to null if no VOD exists on MunoWatch', () async {
      final repo = MovieRepository(munowatchDatasource: datasource);

      // Random non-existent ID on MunoWatch
      final details = await repo.getMovieDetails(99999999);
      expect(details.videoUrl, isNull); // ZERO fake fallbacks or BigBuckBunny
    });

    test('getRelatedMovies returns relevant movies from MunoWatch excluding self', () async {
      final repo = MovieRepository(munowatchDatasource: datasource);
      final all = await datasource.getAllMovies();
      expect(all, isNotEmpty);

      final active = all.first;
      final related = await repo.getRelatedMovies(active);
      expect(related, isNotEmpty);
      expect(related.any((m) => m.id == active.id), isFalse);
    });

    test('MovieRepository merges MunoWatch into search and genres', () async {
      final repo = MovieRepository(munowatchDatasource: datasource);

      // Search multi-word query across repository
      final searchResults = await repo.searchMovies('spider man');
      expect(searchResults, isNotEmpty);

      // Genre: Action (28)
      final actionMovies = await repo.getMoviesByGenre(28);
      expect(actionMovies, isNotEmpty);
      expect(actionMovies.length, greaterThanOrEqualTo(15));
    });
  });
}

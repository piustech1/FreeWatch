import 'package:flutter_test/flutter_test.dart';
import 'package:freewatch/core/router/app_router.dart';
import 'package:freewatch/data/datasources/munowatch_datasource.dart';

void main() {
  group('MunoWatch Web Routing & Deep-Linking Tests', () {
    test('GoRouter configuration matches all MunoWatch URL endpoints', () {
      final router = createAppRouter();

      // 1. /dashboard
      final dashboardMatch = router.configuration.findMatch(Uri.parse('/dashboard'));
      expect(dashboardMatch.isNotEmpty, isTrue);
      expect(dashboardMatch.uri.path, equals('/dashboard'));

      // 2. /movie/:id
      final movieMatch = router.configuration.findMatch(Uri.parse('/movie/10000'));
      expect(movieMatch.isNotEmpty, isTrue);
      expect(movieMatch.pathParameters['id'], equals('10000'));

      // 3. /movie/:id/play
      final moviePlayMatch = router.configuration.findMatch(Uri.parse('/movie/10000/play'));
      expect(moviePlayMatch.isNotEmpty, isTrue);
      expect(moviePlayMatch.pathParameters['id'], equals('10000'));

      // 4. /movie/play?id=10000
      final generalPlayMatch = router.configuration.findMatch(Uri.parse('/movie/play?id=10000'));
      expect(generalPlayMatch.isNotEmpty, isTrue);
      expect(generalPlayMatch.uri.path, equals('/movie/play'));
      expect(generalPlayMatch.uri.queryParameters['id'], equals('10000'));

      // 5. /series/:series_code
      final seriesMatch = router.configuration.findMatch(Uri.parse('/series/SR_EP_50'));
      expect(seriesMatch.isNotEmpty, isTrue);
      expect(seriesMatch.pathParameters['series_code'], equals('SR_EP_50'));
    });

    test('MunowatchDatasource helper methods construct valid MunoWatch URLs', () {
      expect(
        MunowatchDatasource.dashboardWebUrl(),
        equals('https://munowatch.ai.studio/dashboard'),
      );
      expect(
        MunowatchDatasource.movieWebUrl(10000),
        equals('https://munowatch.ai.studio/movie/10000'),
      );
      expect(
        MunowatchDatasource.moviePlayWebUrl(10000),
        equals('https://munowatch.ai.studio/movie/10000/play'),
      );
      expect(
        MunowatchDatasource.moviePlayQueryWebUrl(id: 10000),
        equals('https://munowatch.ai.studio/movie/play?id=10000'),
      );
      expect(
        MunowatchDatasource.seriesWebUrl('SR_EP_50'),
        equals('https://munowatch.ai.studio/series/SR_EP_50'),
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:freewatch/data/mock/mock_movies.dart';
import 'package:freewatch/features/favorites/presentation/providers/favorites_provider.dart';

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
}

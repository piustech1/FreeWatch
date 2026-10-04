import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:freewatch/data/mock/mock_movies.dart';
import 'package:freewatch/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:freewatch/features/home/widgets/vj_card.dart';
import 'package:freewatch/features/home/widgets/vj_section.dart';

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
}

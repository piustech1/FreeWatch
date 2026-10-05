import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/movie.dart';
import '../../../home/providers/home_providers.dart';

/// Parameter object identifying which category and search query to fetch from TMDB
class SearchCategoryParam {
  final String category;
  final String query;

  const SearchCategoryParam({
    required this.category,
    required this.query,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchCategoryParam &&
          runtimeType == other.runtimeType &&
          category.trim().toLowerCase() == other.category.trim().toLowerCase() &&
          query.trim().toLowerCase() == other.query.trim().toLowerCase();

  @override
  int get hashCode =>
      category.trim().toLowerCase().hashCode ^ query.trim().toLowerCase().hashCode;
}

/// Dynamic Riverpod provider fetching real TMDB movies for categories and searches
final categoryOrSearchMoviesProvider =
    FutureProvider.family<List<Movie>, SearchCategoryParam>((ref, param) async {
  final repo = ref.watch(movieRepositoryProvider);
  final cleanQuery = param.query.trim();
  final cleanCat = param.category.trim();

  // If a specific text query was entered (different from category pill):
  if (cleanQuery.isNotEmpty &&
      cleanQuery.toLowerCase() != cleanCat.toLowerCase()) {
    final searchResults = await repo.searchMovies(cleanQuery);
    return searchResults;
  }

  // Otherwise, fetch real movies by category from TMDB
  final catLower = cleanCat.toLowerCase();

  if (catLower == 'movies' || catLower == 'popular') {
    return repo.getPopular();
  } else if (catLower.contains('tv') ||
      catLower.contains('series') ||
      catLower.contains('show')) {
    return repo.getSeries();
  } else if (catLower.contains('music')) {
    return repo.getMoviesByGenre(10402); // Music
  } else if (catLower.contains('game') || catLower.contains('gaming')) {
    final list = await repo.searchMovies('Game');
    if (list.isNotEmpty) return list;
    return repo.getMoviesByGenre(14); // Fantasy/Adventure fallback
  } else if (catLower.contains('anime') || catLower.contains('animation')) {
    return repo.getMoviesByGenre(16); // Animation
  } else if (catLower.contains('action')) {
    return repo.getMoviesByGenre(28); // Action
  } else if (catLower.contains('adventure')) {
    return repo.getMoviesByGenre(12); // Adventure
  } else if (catLower.contains('sci-fi') || catLower.contains('science')) {
    return repo.getMoviesByGenre(878); // Sci-Fi
  } else if (catLower.contains('comedy')) {
    return repo.getMoviesByGenre(35); // Comedy
  } else if (catLower.contains('docu')) {
    return repo.getMoviesByGenre(99); // Documentary
  } else if (catLower.contains('drama')) {
    return repo.getMoviesByGenre(18); // Drama
  } else if (catLower.contains('horror')) {
    return repo.getMoviesByGenre(27); // Horror
  } else if (catLower.contains('romance')) {
    return repo.getMoviesByGenre(10749); // Romance
  } else if (catLower.contains('fantasy')) {
    return repo.getMoviesByGenre(14); // Fantasy
  } else if (catLower.contains('crime')) {
    return repo.getMoviesByGenre(80); // Crime
  } else if (catLower.contains('thriller')) {
    return repo.getMoviesByGenre(53); // Thriller
  } else if (catLower.contains('family')) {
    return repo.getMoviesByGenre(10751); // Family
  } else if (catLower.contains('mystery')) {
    return repo.getMoviesByGenre(9648); // Mystery
  } else if (catLower.contains('teen')) {
    final list = await repo.searchMovies('Teen');
    if (list.isNotEmpty) return list;
    return repo.getMoviesByGenre(10751); // Family/Teen fallback
  }

  // Fallback to searching category name on TMDB
  final fallback = await repo.searchMovies(cleanCat);
  if (fallback.isNotEmpty) return fallback;

  return repo.getPopular();
});

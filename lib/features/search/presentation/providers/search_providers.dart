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

  // Otherwise, fetch real movies by category from MunoWatch catalog
  final catLower = cleanCat.toLowerCase();
  if (catLower == 'movies' || catLower == 'popular') {
    return repo.getAllUploads();
  }

  return repo.getMoviesByGenreName(cleanCat);
});

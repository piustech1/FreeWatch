import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/movie_details_data.dart';
import '../../../home/providers/home_providers.dart';

/// Provider for detailed movie data (runtime, real genres, certifications, cast, related movies)
final movieDetailsProvider =
    FutureProvider.family<MovieDetailsData, int>((ref, movieId) async {
  final repository = ref.watch(movieRepositoryProvider);
  return repository.getMovieDetails(movieId);
});

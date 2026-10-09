import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/movie_details_data.dart';
import '../../../home/providers/home_providers.dart';

/// Provider for detailed movie data (runtime, real genres, certifications, cast, related movies)
final movieDetailsProvider =
    FutureProvider.family<MovieDetailsData, int>((ref, movieId) async {
  final repository = ref.watch(movieRepositoryProvider);
  return repository.getMovieDetails(movieId);
});

/// Parameter object for fetching TV season episodes
class TvSeasonParam {
  final int tvId;
  final int seasonNumber;

  const TvSeasonParam({required this.tvId, required this.seasonNumber});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TvSeasonParam &&
          runtimeType == other.runtimeType &&
          tvId == other.tvId &&
          seasonNumber == other.seasonNumber;

  @override
  int get hashCode => tvId.hashCode ^ seasonNumber.hashCode;
}

final tvSeasonEpisodesProvider =
    FutureProvider.family<List<TvEpisodeData>, TvSeasonParam>((ref, param) async {
  final repository = ref.watch(movieRepositoryProvider);
  return repository.getTvSeasonEpisodes(param.tvId, param.seasonNumber);
});


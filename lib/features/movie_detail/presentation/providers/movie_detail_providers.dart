import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/movie_details_data.dart';
import '../../../home/providers/home_providers.dart';

import '../../../../data/models/movie.dart';

/// Parameter object for fetching movie or TV details
class MovieDetailsParam {
  final int movieId;
  final bool isTv;
  final Movie? initialMovie;

  const MovieDetailsParam({
    required this.movieId,
    this.isTv = false,
    this.initialMovie,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MovieDetailsParam &&
          runtimeType == other.runtimeType &&
          movieId == other.movieId &&
          isTv == other.isTv;

  @override
  int get hashCode => movieId.hashCode ^ isTv.hashCode;
}

/// Provider for detailed movie data (runtime, real genres, certifications, cast, related movies)
final movieDetailsProvider =
    FutureProvider.family<MovieDetailsData, MovieDetailsParam>((ref, param) async {
  final repository = ref.watch(movieRepositoryProvider);
  return repository.getMovieDetails(
    param.movieId,
    initialMovie: param.initialMovie,
    isTv: param.isTv,
  );
});

/// Parameter object for fetching TV season episodes
class TvSeasonParam {
  final int tvId;
  final int seasonNumber;
  final String? seriesTitle;
  final String? seriesCode;

  const TvSeasonParam({
    required this.tvId,
    required this.seasonNumber,
    this.seriesTitle,
    this.seriesCode,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TvSeasonParam &&
          runtimeType == other.runtimeType &&
          tvId == other.tvId &&
          seasonNumber == other.seasonNumber &&
          seriesTitle == other.seriesTitle &&
          seriesCode == other.seriesCode;

  @override
  int get hashCode =>
      tvId.hashCode ^
      seasonNumber.hashCode ^
      (seriesTitle?.hashCode ?? 0) ^
      (seriesCode?.hashCode ?? 0);
}

final tvSeasonEpisodesProvider =
    FutureProvider.family<List<TvEpisodeData>, TvSeasonParam>((ref, param) async {
  final repository = ref.watch(movieRepositoryProvider);
  return repository.getTvSeasonEpisodes(
    param.tvId,
    param.seasonNumber,
    seriesTitle: param.seriesTitle,
    seriesCode: param.seriesCode,
  );
});


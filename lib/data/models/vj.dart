class Vj {
  final String id;
  final String name;
  final String nickname;
  final String specialty;
  final String imageUrl;
  final int movieCount;
  final List<int> translatedMovieIds;

  const Vj({
    required this.id,
    required this.name,
    required this.nickname,
    required this.specialty,
    required this.imageUrl,
    required this.movieCount,
    required this.translatedMovieIds,
  });

  Vj copyWith({
    String? id,
    String? name,
    String? nickname,
    String? specialty,
    String? imageUrl,
    int? movieCount,
    List<int>? translatedMovieIds,
  }) {
    return Vj(
      id: id ?? this.id,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      specialty: specialty ?? this.specialty,
      imageUrl: imageUrl ?? this.imageUrl,
      movieCount: movieCount ?? this.movieCount,
      translatedMovieIds: translatedMovieIds ?? this.translatedMovieIds,
    );
  }
}

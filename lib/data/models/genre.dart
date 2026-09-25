/// Movie genre model from TMDB
class Genre {
  final int id;
  final String name;

  const Genre({required this.id, required this.name});

  factory Genre.fromJson(Map<String, dynamic> json) => Genre(
        id: json['id'] as int,
        name: json['name'] as String,
      );

  static List<Genre> fromJsonList(Map<String, dynamic> json) {
    final list = json['genres'] as List<dynamic>? ?? [];
    return list.map((e) => Genre.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  bool operator ==(Object other) => other is Genre && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

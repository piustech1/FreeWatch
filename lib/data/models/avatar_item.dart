class AvatarItem {
  final String id;
  final String name;
  final String category;
  final String assetPath;

  const AvatarItem({
    required this.id,
    required this.name,
    required this.category,
    required this.assetPath,
  });

  static const String categoryFeatured = 'Featured';
  static const String categoryDisney = 'Disney';

  static const defaultAvatar = AvatarItem(
    id: 'mirabel',
    name: 'Mirabel',
    category: categoryFeatured,
    assetPath: 'assets/avatars/avatar_mirabel.png',
  );

  static const List<AvatarItem> featuredAvatars = [
    AvatarItem(
      id: 'moon_knight',
      name: 'Moon Knight',
      category: categoryFeatured,
      assetPath: 'assets/avatars/avatar_moon_knight.png',
    ),
    AvatarItem(
      id: 'mei_panda',
      name: 'Mei Lee',
      category: categoryFeatured,
      assetPath: 'assets/avatars/avatar_mei.png',
    ),
    AvatarItem(
      id: 'penny_proud',
      name: 'Penny Proud',
      category: categoryFeatured,
      assetPath: 'assets/avatars/avatar_penny_proud.png',
    ),
    AvatarItem(
      id: 'mirabel',
      name: 'Mirabel',
      category: categoryFeatured,
      assetPath: 'assets/avatars/avatar_mirabel.png',
    ),
    AvatarItem(
      id: 'grogu',
      name: 'Grogu',
      category: categoryFeatured,
      assetPath: 'assets/avatars/avatar_grogu.png',
    ),
    AvatarItem(
      id: 'boba_fett',
      name: 'Boba Fett',
      category: categoryFeatured,
      assetPath: 'assets/avatars/avatar_boba_fett.png',
    ),
  ];

  static const List<AvatarItem> disneyAvatars = [
    AvatarItem(
      id: 'minnie',
      name: 'Minnie Mouse',
      category: categoryDisney,
      assetPath: 'assets/avatars/avatar_minnie.png',
    ),
    AvatarItem(
      id: 'raya',
      name: 'Raya',
      category: categoryDisney,
      assetPath: 'assets/avatars/avatar_raya.png',
    ),
    AvatarItem(
      id: 'tiana',
      name: 'Tiana',
      category: categoryDisney,
      assetPath: 'assets/avatars/avatar_tiana.png',
    ),
    AvatarItem(
      id: 'baymax',
      name: 'Baymax',
      category: categoryDisney,
      assetPath: 'assets/avatars/avatar_baymax.png',
    ),
    AvatarItem(
      id: 'anna',
      name: 'Anna',
      category: categoryDisney,
      assetPath: 'assets/avatars/avatar_anna.png',
    ),
    AvatarItem(
      id: 'mickey',
      name: 'Mickey Mouse',
      category: categoryDisney,
      assetPath: 'assets/avatars/avatar_mickey.png',
    ),
  ];

  static List<AvatarItem> get allAvatars => [
        ...featuredAvatars,
        ...disneyAvatars,
      ];

  static AvatarItem fromAsset(String? path) {
    if (path == null || path.isEmpty) return defaultAvatar;
    return allAvatars.firstWhere(
      (a) => a.assetPath == path,
      orElse: () => defaultAvatar,
    );
  }
}

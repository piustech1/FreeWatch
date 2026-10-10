import '../models/movie.dart';
import '../models/genre.dart';
import '../models/vj.dart';

class MockData {
  MockData._();

  static const List<Genre> genres = [
    Genre(id: 28, name: 'Action'),
    Genre(id: 12, name: 'Adventure'),
    Genre(id: 35, name: 'Comedy'),
    Genre(id: 14, name: 'Fantasy'),
    Genre(id: 80, name: 'Crime'),
    Genre(id: 18, name: 'Drama'),
    Genre(id: 27, name: 'Horror'),
    Genre(id: 878, name: 'Sci-Fi'),
    Genre(id: 16, name: 'Animation'),
    Genre(id: 53, name: 'Thriller'),
  ];

  static const List<Movie> trendingMovies = [
    Movie(
      id: 1011985,
      title: 'The Beekeeper',
      overview:
          'One man\'s brutal campaign for vengeance takes on national stakes after he is revealed to be a former operative of a powerful and clandestine organization known as Beekeepers.',
      posterPath: '/A7EByudX0eOzlkQ2FIbogzyazm2.jpg',
      backdropPath: '/628Dep6AxEtDxjZoGP78TsOxYbK.jpg',
      releaseDate: '2024-01-10',
      voteAverage: 7.4,
      voteCount: 2900,
      genreIds: [28, 53, 18],
    ),
    Movie(
      id: 693134,
      title: 'Dune: Part Two',
      overview:
          'Follow the mythic journey of Paul Atreides as he unites with Chani and the Fremen while on a path of revenge against the conspirators who destroyed his family.',
      posterPath: '/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg',
      backdropPath: '/stKGOmBidrO1Kk7Qc0s07Q0w9Wk.jpg',
      releaseDate: '2024-02-27',
      voteAverage: 8.2,
      voteCount: 5200,
      genreIds: [878, 12],
    ),
    Movie(
      id: 533535,
      title: 'Deadpool & Wolverine',
      overview:
          'A listless Wade Wilson toils away in civilian life with his days as the morally flexible mercenary, Deadpool, behind him. But when his homeworld faces an existential threat, Wade must reluctantly suit-up again with an even more reluctant Wolverine.',
      posterPath: '/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg',
      backdropPath: '/x2RS3uTcsJJ9Ifj2mjyYbgx0Wh8.jpg',
      releaseDate: '2024-07-24',
      voteAverage: 7.7,
      voteCount: 4600,
      genreIds: [28, 35, 878],
    ),
  ];

  static const List<Movie> newMovies = [
    Movie(
      id: 1084199,
      title: 'Lilo & Stitch',
      overview:
          'Live-action remake of Disney\'s animated classic following a lonely Hawaiian girl who adopts an extraterrestrial pet dog.',
      posterPath: '/m20yt7Ul7hJBLv0S8j7Hn6Zk2iV.jpg',
      backdropPath: '/dvBCW3WBMnneFh0PGejTAznzTXE.jpg',
      releaseDate: '2025-05-23',
      voteAverage: 7.2,
      voteCount: 340,
      genreIds: [12, 35, 10751],
    ),
    Movie(
      id: 1125510,
      title: 'House of David',
      overview:
          'Follows the biblical story of David, tracking his rise from an unassuming shepherd to become the most renowned king in Israel\'s history.',
      posterPath: '/kSpsYjG80eL4qQ3R3n9k6rLqC9p.jpg',
      backdropPath: '/euYIwmqkmz95mnXvufEmbL6ovhZ.jpg',
      releaseDate: '2025-03-14',
      voteAverage: 7.8,
      voteCount: 410,
      genreIds: [18, 36],
    ),
    Movie(
      id: 974950,
      title: 'Mickey 17',
      overview:
          'Mickey 17, an "expendable", is an employee on a human expedition sent to colonize the ice world Niflheim. When one iteration dies, a new body is regenerated with most of his memories intact.',
      posterPath: '/lrkudNqmG39w62M4t4o6kQ7gV0r.jpg',
      backdropPath: '/xOMo8BRK7PfcJv9JCnx7s520DRq.jpg',
      releaseDate: '2025-04-18',
      voteAverage: 6.5,
      voteCount: 220,
      genreIds: [878, 12, 35],
    ),
    Movie(
      id: 558449,
      title: 'Gladiator II',
      overview:
          'Years after witnessing the death of Maximus at the hands of his uncle, Lucius must enter the Colosseum after the emperors of Rome conquer his home.',
      posterPath: '/2cxhvwyEwRlysAmRH4iodkvo0z5.jpg',
      backdropPath: '/euYIwmqkmz95mnXvufEmbL6ovhZ.jpg',
      releaseDate: '2024-11-13',
      voteAverage: 6.8,
      voteCount: 2500,
      genreIds: [28, 12, 18],
    ),
  ];

  static const List<Movie> popularMovies = [
    Movie(
      id: 1241982,
      title: 'Moana 2',
      overview:
          'After receiving an unexpected call from her wayfinding ancestors, Moana journeys alongside Maui and a new crew to the far seas of Oceania.',
      posterPath: '/aLVkiINNOgr1lYzZCrjWBsEV9um.jpg',
      backdropPath: '/v9acaWVxToYxIjIKT3Wffy8tP2F.jpg',
      releaseDate: '2024-11-27',
      voteAverage: 7.1,
      voteCount: 1600,
      genreIds: [16, 12, 10751],
    ),
    Movie(
      id: 533535,
      title: 'Deadpool & Wolverine',
      overview: 'Wade Wilson and Wolverine must team up to save the universe.',
      posterPath: '/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg',
      backdropPath: '/x2RS3uTcsJJ9Ifj2mjyYbgx0Wh8.jpg',
      releaseDate: '2024-07-24',
      voteAverage: 7.7,
      voteCount: 4600,
      genreIds: [28, 35, 878],
    ),
    Movie(
      id: 1011985,
      title: 'The Beekeeper',
      overview: 'One man\'s brutal campaign for vengeance.',
      posterPath: '/A7EByudX0eOzlkQ2FIbogzyazm2.jpg',
      backdropPath: '/628Dep6AxEtDxjZoGP78TsOxYbK.jpg',
      releaseDate: '2024-01-10',
      voteAverage: 7.4,
      voteCount: 2900,
      genreIds: [28, 53, 18],
    ),
    Movie(
      id: 693134,
      title: 'Dune: Part Two',
      overview: 'Paul Atreides unites with Chani and the Fremen.',
      posterPath: '/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg',
      backdropPath: '/stKGOmBidrO1Kk7Qc0s07Q0w9Wk.jpg',
      releaseDate: '2024-02-27',
      voteAverage: 8.2,
      voteCount: 5200,
      genreIds: [878, 12],
    ),
  ];

  static const List<Movie> popularTv = [
    Movie(
      id: 66732,
      title: 'Stranger Things',
      overview:
          'When a young boy vanishes, a small town uncovers a mystery involving secret experiments, terrifying supernatural forces and one strange little girl.',
      posterPath: '/49WJfeN0moxb9IPfGn8AIqMGskD.jpg',
      backdropPath: '/56v2KjBlU4XaOv9rVYEQypROD7P.jpg',
      releaseDate: '2016-07-15',
      voteAverage: 8.6,
      voteCount: 16800,
      genreIds: [18, 878, 9648],
      isTv: true,
    ),
    Movie(
      id: 93405,
      title: 'Squid Game',
      overview:
          'Hundreds of cash-strapped players accept a strange invitation to compete in children\'s games. Inside, a tempting prize awaits with deadly high stakes.',
      posterPath: '/dDlEmu3EZ0Pgg93K2SVNLCjCSvE.jpg',
      backdropPath: '/2meX1nMdScFOoV4370rqHWFDxZ.jpg',
      releaseDate: '2021-09-17',
      voteAverage: 8.5,
      voteCount: 13500,
      genreIds: [18, 9648, 10759],
      isTv: true,
    ),
    Movie(
      id: 119051,
      title: 'Wednesday',
      overview:
          'A sleuthing, supernaturally infused mystery charting Wednesday Addams\' years as a student at Nevermore Academy.',
      posterPath: '/9PFonB99nm1VTvgsl2z22oxOpF2.jpg',
      backdropPath: '/iHSwvRVsRyxpX7FE7GbviaDvgGZ.jpg',
      releaseDate: '2022-11-23',
      voteAverage: 8.4,
      voteCount: 8200,
      genreIds: [18, 9648, 35],
      isTv: true,
    ),
    Movie(
      id: 71446,
      title: 'Money Heist',
      overview:
          'To carry out the biggest heist in history, a mysterious man called The Professor recruits a band of eight robbers who have a single characteristic: none of them has anything to lose.',
      posterPath: '/reEMJA1uzscCbk5rUhGnyRYEvtV.jpg',
      backdropPath: '/gFZriCkpJYsApPwyQ9qhKeLzFv3.jpg',
      releaseDate: '2017-05-02',
      voteAverage: 8.3,
      voteCount: 18200,
      genreIds: [80, 18],
      isTv: true,
    ),
  ];

  static const List<Vj> vjs = [
    Vj(
      id: 'vj-junior',
      name: 'VJ JUNIOR',
      nickname: 'The Pioneer',
      specialty: 'Action, Thrillers & Blockbusters',
      imageUrl: 'assets/vjs/vj junior.png',
      movieCount: 185,
      translatedMovieIds: [1011985, 558449],
    ),
    Vj(
      id: 'vj-emmy',
      name: 'VJ EMMY',
      nickname: 'Action Sensation',
      specialty: 'Drama, Sci-Fi & Action',
      imageUrl: 'assets/vjs/vj emmy.png',
      movieCount: 128,
      translatedMovieIds: [693134, 93405],
    ),
    Vj(
      id: 'vj-ice-p',
      name: 'VJ ICE P',
      nickname: 'Sci-Fi Wizard',
      specialty: 'Sci-Fi, Cyberpunk & Blockbusters',
      imageUrl: 'assets/vjs/vj iceP.jpeg',
      movieCount: 142,
      translatedMovieIds: [693134, 974950, 66732],
    ),
    Vj(
      id: 'vj-jingo',
      name: 'VJ JINGO',
      nickname: 'The Grandmaster',
      specialty: 'Martial Arts, Drama & Crime',
      imageUrl: 'assets/vjs/vj jingo.jpg',
      movieCount: 156,
      translatedMovieIds: [71446, 1125510],
    ),
    Vj(
      id: 'vj-uncle-t',
      name: 'VJ UNCLE T',
      nickname: 'The Great Narrator',
      specialty: 'Family, Comedy & Adventure',
      imageUrl: 'assets/vjs/vj uncle T.jpeg',
      movieCount: 85,
      translatedMovieIds: [1084199, 1241982],
    ),
    Vj(
      id: 'vj-heavy-q',
      name: 'VJ HEAVY Q',
      nickname: 'Action Maestro',
      specialty: 'Action, War & Crime Thrillers',
      imageUrl: 'assets/vjs/Vj Heavy Q.jpeg',
      movieCount: 115,
      translatedMovieIds: [1011985, 71446],
    ),
    Vj(
      id: 'vj-musa',
      name: 'VJ MUSA',
      nickname: 'The Narrator',
      specialty: 'Drama, Action & Martial Arts',
      imageUrl: 'assets/vjs/Vj Musa.jpeg',
      movieCount: 88,
      translatedMovieIds: [558449, 1125510],
    ),
    Vj(
      id: 'vj-shield',
      name: 'VJ SHIELD',
      nickname: 'Blockbuster Specialist',
      specialty: 'Superhero, Sci-Fi & Action',
      imageUrl: 'assets/vjs/Vj shield.png',
      movieCount: 94,
      translatedMovieIds: [533535, 693134],
    ),
    Vj(
      id: 'vj-neil',
      name: 'VJ NEIL',
      nickname: 'The Voice',
      specialty: 'Hollywood Blockbusters & Series',
      imageUrl: 'assets/vjs/vj Neil.jpeg',
      movieCount: 76,
      translatedMovieIds: [533535, 93405],
    ),
    Vj(
      id: 'vj-nelly',
      name: 'VJ NELLY',
      nickname: 'The Hype Master',
      specialty: 'High-Octane Action & Thrillers',
      imageUrl: 'assets/vjs/vj Nelly.jpeg',
      movieCount: 68,
      translatedMovieIds: [1011985, 533535],
    ),
    Vj(
      id: 'vj-ham',
      name: 'VJ HAM',
      nickname: 'Cinema Guru',
      specialty: 'Classics, Action & Crime',
      imageUrl: 'assets/vjs/vj ham.jpeg',
      movieCount: 82,
      translatedMovieIds: [558449, 71446],
    ),
    Vj(
      id: 'vj-hd',
      name: 'VJ HD',
      nickname: 'Clarity King',
      specialty: 'Action, Mystery & Drama',
      imageUrl: 'assets/vjs/vj hd.jpeg',
      movieCount: 64,
      translatedMovieIds: [66732, 93405],
    ),
    Vj(
      id: 'vj-isma-k',
      name: 'VJ ISMA K',
      nickname: 'The Dynamic Voice',
      specialty: 'Action, Thrillers & Suspense',
      imageUrl: 'assets/vjs/vj isma k.jpeg',
      movieCount: 91,
      translatedMovieIds: [1011985, 558449],
    ),
    Vj(
      id: 'vj-isma-pro',
      name: 'VJ ISMA PRO',
      nickname: 'The Professional',
      specialty: 'Epic Battles & Adventure',
      imageUrl: 'assets/vjs/vj isma pro.jpeg',
      movieCount: 104,
      translatedMovieIds: [558449, 1084199],
    ),
    Vj(
      id: 'vj-jovan',
      name: 'VJ JOVAN',
      nickname: 'The Storyteller',
      specialty: 'Sci-Fi, Mystery & Thrillers',
      imageUrl: 'assets/vjs/vj jovan.jpeg',
      movieCount: 59,
      translatedMovieIds: [693134, 66732],
    ),
    Vj(
      id: 'vj-kevin',
      name: 'VJ KEVIN',
      nickname: 'The Explosive',
      specialty: 'Military, Spy & Action',
      imageUrl: 'assets/vjs/vj kevin.jpeg',
      movieCount: 73,
      translatedMovieIds: [1011985, 71446],
    ),
    Vj(
      id: 'vj-kevo',
      name: 'VJ KEVO',
      nickname: 'Action Fire',
      specialty: 'Fast Action & Car Chases',
      imageUrl: 'assets/vjs/vj kevo.jpeg',
      movieCount: 65,
      translatedMovieIds: [533535, 1011985],
    ),
    Vj(
      id: 'vj-kk',
      name: 'VJ KK',
      nickname: 'The Legend',
      specialty: 'Martial Arts & Action',
      imageUrl: 'assets/vjs/vj kk.jpeg',
      movieCount: 120,
      translatedMovieIds: [558449, 1011985],
    ),
    Vj(
      id: 'vj-lance',
      name: 'VJ LANCE',
      nickname: 'Precision Voice',
      specialty: 'Detective, Crime & Thrillers',
      imageUrl: 'assets/vjs/vj lance.jpeg',
      movieCount: 84,
      translatedMovieIds: [71446, 119051],
    ),
    Vj(
      id: 'vj-mark',
      name: 'VJ MARK',
      nickname: 'Thriller Specialist',
      specialty: 'Dark Thrillers & Mystery',
      imageUrl: 'assets/vjs/vj mark.jpeg',
      movieCount: 97,
      translatedMovieIds: [119051, 66732],
    ),
    Vj(
      id: 'vj-martin-k',
      name: 'VJ MARTIN K',
      nickname: 'The Master Voice',
      specialty: 'Drama, Romance & Adventure',
      imageUrl: 'assets/vjs/vj martin k.jpeg',
      movieCount: 71,
      translatedMovieIds: [1125510, 1241982],
    ),
    Vj(
      id: 'vj-mk-kisule',
      name: 'VJ MK KISULE',
      nickname: 'The Heavyweight',
      specialty: 'Epic Wars & Action Spectacles',
      imageUrl: 'assets/vjs/vj mk kisule.png',
      movieCount: 110,
      translatedMovieIds: [558449, 1011985],
    ),
    Vj(
      id: 'vj-mosco',
      name: 'VJ MOSCO',
      nickname: 'Speed Master',
      specialty: 'Action, Heist & Suspense',
      imageUrl: 'assets/vjs/vj mosco.jpeg',
      movieCount: 79,
      translatedMovieIds: [71446, 533535],
    ),
    Vj(
      id: 'vj-muba',
      name: 'VJ MUBA',
      nickname: 'The Maestro',
      specialty: 'Adventure, Sci-Fi & Action',
      imageUrl: 'assets/vjs/vj muba.jpeg',
      movieCount: 62,
      translatedMovieIds: [693134, 1241982],
    ),
    Vj(
      id: 'vj-smk',
      name: 'VJ SMK',
      nickname: 'The Sharp Voice',
      specialty: 'Kung Fu, Martial Arts & Action',
      imageUrl: 'assets/vjs/vj smk.jpeg',
      movieCount: 89,
      translatedMovieIds: [558449, 93405],
    ),
    Vj(
      id: 'vj-tom',
      name: 'VJ TOM',
      nickname: 'The Veteran',
      specialty: 'Classics, Action & Drama',
      imageUrl: 'assets/vjs/vj tom.png',
      movieCount: 102,
      translatedMovieIds: [1125510, 558449],
    ),
    Vj(
      id: 'vj-tonny',
      name: 'VJ TONNY',
      nickname: 'The Flow Master',
      specialty: 'Action, Comedy & Series',
      imageUrl: 'assets/vjs/vj tonny.png',
      movieCount: 93,
      translatedMovieIds: [533535, 93405],
    ),
    Vj(
      id: 'vj-ulio',
      name: 'VJ ULIO',
      nickname: 'The Thrill Voice',
      specialty: 'Horror, Supernatural & Thrillers',
      imageUrl: 'assets/vjs/vj ulio.jpeg',
      movieCount: 57,
      translatedMovieIds: [66732, 119051],
    ),
    Vj(
      id: 'vj-soul',
      name: 'VJ SOUL',
      nickname: 'Soulful Narrator',
      specialty: 'Romance, Drama & Emotional Epics',
      imageUrl: 'assets/vjs/vjsoul.jpeg',
      movieCount: 78,
      translatedMovieIds: [1125510, 93405],
    ),
  ];

  static List<Movie> getAllMovies() {
    final seen = <int>{};
    final all = <Movie>[];
    for (final m in [...trendingMovies, ...newMovies, ...popularMovies, ...popularTv]) {
      if (seen.add(m.id)) {
        all.add(m);
      }
    }
    return all;
  }

  /// Strictly returns only movies translated by the specified VJ.
  static List<Movie> getMoviesByVj(String vjId) {
    final vj = vjs.firstWhere((v) => v.id == vjId, orElse: () => vjs.first);
    final all = getAllMovies();
    return all.where((m) => vj.translatedMovieIds.contains(m.id)).toList();
  }
}

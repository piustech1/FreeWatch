import '../models/movie.dart';
import '../models/genre.dart';

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
      backdropPath: '/4woSOUD0equAYzvwhWBHIJDCM88.jpg',
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
      backdropPath: '/xOMo8BRK7PfcJv9JCnx7s520DRq.jpg',
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
      backdropPath: '/yDHYTfA3R0jFYba16jBB1ef8oIt.jpg',
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
      backdropPath: '/4woSOUD0equAYzvwhWBHIJDCM88.jpg',
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
      backdropPath: '/yDHYTfA3R0jFYba16jBB1ef8oIt.jpg',
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
      backdropPath: '/4woSOUD0equAYzvwhWBHIJDCM88.jpg',
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
      backdropPath: '/xOMo8BRK7PfcJv9JCnx7s520DRq.jpg',
      releaseDate: '2024-02-27',
      voteAverage: 8.2,
      voteCount: 5200,
      genreIds: [878, 12],
    ),
  ];
}

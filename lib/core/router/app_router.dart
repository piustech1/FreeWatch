import 'package:go_router/go_router.dart';
import '../../features/home/home_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/presentation/screens/choose_avatar_screen.dart';
import '../../features/movie_detail/presentation/screens/movie_detail_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../data/models/movie.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: '/',
      redirect: (_, __) => '/splash',
    ),
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/choose-avatar',
      name: 'choose-avatar',
      builder: (context, state) => const ChooseAvatarScreen(),
    ),
    GoRoute(
      path: '/notifications',
      name: 'notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/movie-detail',
      name: 'movie-detail',
      builder: (context, state) {
        final movie = state.extra as Movie;
        return MovieDetailScreen(movie: movie);
      },
    ),
  ],
);

import 'package:go_router/go_router.dart';
import '../../features/home/home_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/presentation/screens/choose_avatar_screen.dart';
import '../../features/auth/presentation/screens/banned_account_screen.dart';
import '../../features/auth/presentation/screens/banned_review_screen.dart';
import '../../features/movie_detail/presentation/screens/movie_detail_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/chat/presentation/screens/developer_chat_screen.dart';
import '../../data/models/movie.dart';
import '../services/app_update_service.dart';
import '../../shared/widgets/full_screen_update_dialog.dart';

GoRouter createAppRouter({String initialLocation = '/splash'}) => GoRouter(
  initialLocation: initialLocation,
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
      path: '/banned',
      name: 'banned',
      builder: (context, state) {
        final reason = state.uri.queryParameters['reason'];
        return BannedAccountScreen(initialReason: reason);
      },
      routes: [
        GoRoute(
          path: 'review',
          name: 'banned-review',
          builder: (context, state) {
            final reason = state.uri.queryParameters['reason'];
            return BannedReviewScreen(banReason: reason);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/update',
      name: 'update',
      builder: (context, state) {
        final updateInfo = state.extra is AppUpdateInfo
            ? state.extra as AppUpdateInfo
            : const AppUpdateInfo(hasUpdate: true);
        return FullScreenUpdateDialog(updateInfo: updateInfo);
      },
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    // ── MunoWatch Core Web & Deep Link Routes ────────────────────────────────
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
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
      path: '/developer-chat',
      name: 'developer-chat',
      builder: (context, state) => const DeveloperChatScreen(),
    ),
    GoRoute(
      path: '/chat',
      name: 'chat',
      builder: (context, state) => const DeveloperChatScreen(),
    ),
    // /movie/:id and /movie/:id/play
    GoRoute(
      path: '/movie/:id',
      name: 'movie',
      builder: (context, state) {
        final idStr = state.pathParameters['id'] ?? '';
        final id = int.tryParse(idStr) ?? 0;
        final movie = state.extra is Movie
            ? state.extra as Movie
            : Movie(
                id: id,
                title: '',
                voteAverage: 0,
              );
        return MovieDetailScreen(movie: movie);
      },
      routes: [
        GoRoute(
          path: 'play',
          name: 'movie-id-play',
          builder: (context, state) {
            final idStr = state.pathParameters['id'] ?? '';
            final id = int.tryParse(idStr) ?? 0;
            final movie = state.extra is Movie
                ? state.extra as Movie
                : Movie(
                    id: id,
                    title: '',
                    voteAverage: 0,
                  );
            return MovieDetailScreen(movie: movie, autoPlay: true);
          },
        ),
      ],
    ),
    // /movie/play?id=<id>
    GoRoute(
      path: '/movie/play',
      name: 'movie-play',
      builder: (context, state) {
        final idStr = state.uri.queryParameters['id'] ?? '';
        final id = int.tryParse(idStr) ??
            (state.extra is Movie ? (state.extra as Movie).id : 0);
        final movie = state.extra is Movie
            ? state.extra as Movie
            : Movie(
                id: id,
                title: '',
                voteAverage: 0,
              );
        return MovieDetailScreen(movie: movie, autoPlay: true);
      },
    ),
    // /series/<series_code>
    GoRoute(
      path: '/series/:series_code',
      name: 'series',
      builder: (context, state) {
        final code = state.pathParameters['series_code'] ?? '';
        final id = int.tryParse(code) ?? code.hashCode.abs();
        final movie = state.extra is Movie
            ? state.extra as Movie
            : Movie(
                id: id,
                title: 'Series $code',
                voteAverage: 0,
                isTv: true,
              );
        return MovieDetailScreen(movie: movie);
      },
    ),
    // Backward-compatible alias
    GoRoute(
      path: '/movie-detail',
      name: 'movie-detail',
      builder: (context, state) {
        final movie = state.extra as Movie?;
        if (movie != null) {
          return MovieDetailScreen(movie: movie);
        }
        return const HomeScreen();
      },
    ),
  ],
);

final appRouter = createAppRouter();

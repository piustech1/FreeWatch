import 'package:go_router/go_router.dart';
import '../../features/home/home_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    // More routes will be added as we build each page
  ],
);

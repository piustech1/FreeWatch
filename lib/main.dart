import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/services/notification_service.dart';
import 'core/services/movie_notification_tracker.dart';
import 'features/favorites/presentation/providers/favorites_provider.dart';
import 'features/profile/presentation/providers/watch_history_provider.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with FreeWatch project configuration
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Register background messaging handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  // Initialize device OS notifications service
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Notification service initialization notice: $e');
  }

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Riverpod root container
  final container = ProviderContainer();

  // Listen to Firebase Auth state to synchronize user-scoped favorites and watch history
  try {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      container.read(favoritesProvider.notifier).syncWithUser(user?.uid);
      container.read(watchHistoryProvider.notifier).syncWithUser(user?.uid);
    });
  } catch (e) {
    debugPrint('Auth state sync listener notice: $e');
  }

  // Start background monitoring of MumoWatch database for new uploads
  try {
    MovieNotificationTracker(container).startTracking();
  } catch (e) {
    debugPrint('Movie notification tracker start notice: $e');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FreeWatchApp(),
    ),
  );
}

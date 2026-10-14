import 'package:flutter/material.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/widgets/user_ban_watcher.dart';

class FreeWatchApp extends StatelessWidget {
  const FreeWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FreeWatch',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
      builder: (context, child) => UserBanWatcher(child: child ?? const SizedBox.shrink()),
    );
  }
}

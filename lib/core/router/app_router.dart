import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/auth_state.dart';
import '../../presentation/screens/auth/legacy_migration_screen.dart';
import '../../presentation/screens/auth/setup_screen.dart';
import '../../presentation/screens/auth/unlock_screen.dart';
import '../../presentation/screens/home/dashboard_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/widgets/auto_logout_listener.dart';

/// Zentrale Route-Definitionen.
class AppRoutes {
  AppRoutes._();
  static const String splash = '/';
  static const String setup = '/setup';
  static const String unlock = '/unlock';
  static const String legacyMigration = '/legacy-migration';
  static const String home = '/home';
}

/// Baut den Router. Ein `redirect` reagiert auf Auth-Aenderungen,
/// damit Nutzer nicht ohne Anmeldung zur Home-Seite kommen und
/// nach Unlock automatisch dorthin weitergeleitet werden.
GoRouter buildAppRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: _AuthRouterListenable(ref),
    redirect: (BuildContext context, GoRouterState state) {
      final authAsync = ref.read(authStateProvider);
      // Solange wir den Auth-Status nicht kennen, bleiben wir am Splash.
      if (authAsync.isLoading || !authAsync.hasValue) {
        return state.matchedLocation == AppRoutes.splash
            ? null
            : AppRoutes.splash;
      }
      final auth = authAsync.value!;
      final loc = state.matchedLocation;

      switch (auth.status) {
        case AuthStatus.unknown:
          return AppRoutes.splash;
        case AuthStatus.needsSetup:
          return loc == AppRoutes.setup ? null : AppRoutes.setup;
        case AuthStatus.needsLegacyMigration:
          return loc == AppRoutes.legacyMigration
              ? null
              : AppRoutes.legacyMigration;
        case AuthStatus.locked:
        case AuthStatus.unlocking:
          return loc == AppRoutes.unlock ? null : AppRoutes.unlock;
        case AuthStatus.unlocked:
          if (loc == AppRoutes.setup ||
              loc == AppRoutes.unlock ||
              loc == AppRoutes.legacyMigration ||
              loc == AppRoutes.splash) {
            return AppRoutes.home;
          }
          return null;
      }
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (BuildContext context, GoRouterState state) =>
            const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.setup,
        name: 'setup',
        builder: (BuildContext context, GoRouterState state) =>
            const SetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.unlock,
        name: 'unlock',
        builder: (BuildContext context, GoRouterState state) =>
            const UnlockScreen(),
      ),
      GoRoute(
        path: AppRoutes.legacyMigration,
        name: 'legacy-migration',
        builder: (BuildContext context, GoRouterState state) =>
            const LegacyMigrationScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (BuildContext context, GoRouterState state) =>
            const AutoLogoutListener(child: DashboardScreen()),
      ),
    ],
  );
}

/// Bridges einen Riverpod-Provider zum [Listenable], das `go_router`
/// als `refreshListenable` erwartet. Sorgt dafuer, dass eine
/// Aenderung am AuthState ein Re-Evaluieren der Redirects ausloest.
class _AuthRouterListenable extends ChangeNotifier {
  _AuthRouterListenable(WidgetRef ref) {
    _sub = ref.listenManual<AsyncValue<AuthState>>(
      authStateProvider,
      (_, __) => notifyListeners(),
    );
  }

  late final ProviderSubscription<AsyncValue<AuthState>> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

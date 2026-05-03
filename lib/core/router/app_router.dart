import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/auth_state.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/home/home_placeholder_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/widgets/auto_logout_listener.dart';

/// Zentrale Route-Definitionen.
class AppRoutes {
  AppRoutes._();
  static const String splash = '/';
  static const String register = '/register';
  static const String login = '/login';
  static const String home = '/home';
}

/// Baut den Router. Ein `redirect` reagiert auf Auth-Aenderungen,
/// damit Nutzer nicht ohne Anmeldung zur Home-Seite kommen und
/// nach Login automatisch dorthin weitergeleitet werden.
GoRouter buildAppRouter(Ref ref) {
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
        case AuthStatus.noAccount:
          return loc == AppRoutes.register ? null : AppRoutes.register;
        case AuthStatus.loggedOut:
        case AuthStatus.authenticating:
          return loc == AppRoutes.login ? null : AppRoutes.login;
        case AuthStatus.authenticated:
          return (loc == AppRoutes.login ||
                  loc == AppRoutes.register ||
                  loc == AppRoutes.splash)
              ? AppRoutes.home
              : null;
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
        path: AppRoutes.register,
        name: 'register',
        builder: (BuildContext context, GoRouterState state) =>
            const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (BuildContext context, GoRouterState state) =>
            const AutoLogoutListener(child: HomePlaceholderScreen()),
      ),
    ],
  );
}

/// Bridges einen Riverpod-Provider zum [Listenable], das `go_router`
/// als `refreshListenable` erwartet. Sorgt dafuer, dass eine
/// Aenderung am AuthState ein Re-Evaluieren der Redirects ausloest.
class _AuthRouterListenable extends ChangeNotifier {
  _AuthRouterListenable(this._ref) {
    _sub = _ref.listen<AsyncValue<AuthState>>(
      authStateProvider,
      (_, __) => notifyListeners(),
      fireImmediately: false,
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AsyncValue<AuthState>> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

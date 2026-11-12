import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app_routes.dart';
import 'auth/login_page.dart';

/// Signed-out users always land on /login, signed-in users never see it.
final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  refreshListenable: _AuthStateListenable(
    Supabase.instance.client.auth.onAuthStateChange,
  ),
  redirect: (context, state) {
    final signedIn = Supabase.instance.client.auth.currentSession != null;
    final onLogin = state.matchedLocation == '/login';

    if (!signedIn && !onLogin) return '/login';
    if (signedIn && onLogin) return '/overview';
    return null;
  },
  routes: [
    ...appRoutes,
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginPage(
        sessionExpired: state.uri.queryParameters.containsKey('expired'),
      ),
    ),
  ],
);

/// Re-runs the router's redirect whenever the user signs in or out.
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Stream<AuthState> authStates) {
    _subscription = authStates.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Called on a 401 from the backend: sign out, then show the login page with an explanation.
Future<void> signOutExpiredSession() async {
  await Supabase.instance.client.auth.signOut();
  router.go('/login?expired');
}

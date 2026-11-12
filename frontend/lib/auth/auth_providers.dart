import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Email of the signed-in user, overridden in widget tests where Supabase is not initialized.
final signedInEmailProvider = Provider<String?>(
  (ref) => Supabase.instance.client.auth.currentUser?.email,
);

/// Signs the user out; the router then redirects to /login.
final signOutProvider = Provider<Future<void> Function()>(
  (ref) =>
      () => Supabase.instance.client.auth.signOut(),
);

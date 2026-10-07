/// Build-time configuration, passed with `--dart-define-from-file=env.json`.
///
/// All values are public (they end up in the browser bundle); secrets never belong here.
class Config {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080');

  static void ensureComplete() {
    if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
      throw StateError('Missing SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY. Run with --dart-define-from-file=env.json');
    }
  }
}

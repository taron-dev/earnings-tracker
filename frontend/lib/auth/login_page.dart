import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  bool _sending = false;
  String? _message;

  /// Supabase redirects back here after sign-in; must be listed in Supabase Redirect URLs.
  /// Keeps the base path, because on GitHub Pages the app lives under /earnings-tracker/.
  String get _redirectTo {
    final base = Uri.base;
    return Uri(scheme: base.scheme, host: base.host, port: base.port, path: base.path).toString();
  }

  Future<void> _signInWithGoogle() async {
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _redirectTo,
    );
  }

  Future<void> _sendMagicLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _sending = true;
      _message = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithOtp(email: email, emailRedirectTo: _redirectTo);
      setState(() => _message = 'Odkaz na prihlásenie sme poslali na $email.');
    } on AuthException catch (e) {
      setState(() => _message = 'Odkaz sa nepodarilo poslať: ${e.message}');
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Earnings Tracker', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                const SizedBox(height: 32),
                FilledButton(onPressed: _signInWithGoogle, child: const Text('Prihlásiť sa cez Google')),
                const SizedBox(height: 24),
                const Text('alebo', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  onSubmitted: (_) => _sendMagicLink(),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _sending ? null : _sendMagicLink,
                  child: const Text('Poslať prihlasovací odkaz'),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 16),
                  Text(_message!, textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

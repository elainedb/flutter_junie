import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'config/authorized_emails.dart';
import 'main_screen.dart';

/// Simple placeholder screen to navigate to on successful login
class NextScreen extends StatelessWidget {
  const NextScreen({super.key, required this.email});
  final String email;

  Future<void> _logout(BuildContext context) async {
    final googleSignIn = GoogleSignIn(scopes: const <String>['email', 'profile']);
    try {
      // Disconnect to clear the account so the chooser appears next time
      await googleSignIn.disconnect();
    } catch (_) {
      // Fallback to signOut if disconnect throws (e.g., if not connected)
      try { await googleSignIn.signOut(); } catch (_) {}
    }
    // Navigate back to the login screen and clear the stack
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<Widget>(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: <Widget>[
          TextButton(
            onPressed: () => _logout(context),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Welcome, $email'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _logout(context),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? _error;
  bool _loading = false;


  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email', 'profile'],
  );

  Future<void> _handleSignIn() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      // Disconnect any previous session to ensure fresh account selection if needed
      try {
        await _googleSignIn.disconnect();
      } catch (_) {}

      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        // User cancelled the sign-in flow
        setState(() {
          _loading = false;
        });
        return;
      }
      final String email = account.email;

      if (authorizedEmails.contains(email)) {
        // Success: print message and navigate
        // ignore: avoid_print
        print('Access granted to $email');
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<Widget>(
            builder: (_) => const MainScreen(),
          ),
        );
      } else {
        setState(() {
          _error = 'Access denied. Your email is not authorized.';
        });
      }
    } catch (e) {
      String friendly = 'Sign-in failed. Please try again.';
      if (e is PlatformException) {
        final msg = e.message ?? '';
        // Google Sign-In status code 10 = DEVELOPER_ERROR (configuration)
        if (e.code == 'sign_in_failed' && msg.contains('10')) {
          friendly = 'Sign-in failed due to configuration (status 10). Please ensure:\n'
              '- Android: Add your SHA-1 and SHA-256 debug/release fingerprints to Firebase, download updated google-services.json, and rebuild.\n'
              '- iOS/macOS: URL scheme with REVERSED_CLIENT_ID is set (already updated in project).\n'
              'Then try again.';
        }
      }
      setState(() {
        _error = friendly;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'Login with Google',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _handleSignIn,
              child: const Text('Sign in with Google'),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            if (_loading) const Padding(
              padding: EdgeInsets.only(top: 12),
              child: CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}

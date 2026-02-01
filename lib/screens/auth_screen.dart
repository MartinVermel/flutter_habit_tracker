import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/habit_service.dart';
import '../services/firestore_sync_service.dart';

/// Handles sign-in, sign-up, and anonymous → permanent account upgrade.
/// The screen is shown when no Firebase user is detected.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isSignUp = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      if (_isSignUp) {
        await _auth.createAccount(_emailCtrl.text.trim(), _passwordCtrl.text);
        // Push all local data to Firestore for the new account
        await HabitService().uploadToFirestore();
      } else {
        await _auth.signInWithEmail(_emailCtrl.text.trim(), _passwordCtrl.text);
        // Pull remote data into Hive on sign-in to an existing account
        final result = await FirestoreSyncService().downloadAll();
        await HabitService().applyRemoteSync(result);
      }
    } on FirebaseAuthException catch (e) {
      setState(() { _error = _friendlyError(e.code); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _continueAnonymously() async {
    setState(() { _loading = true; _error = null; });
    try {
      await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      setState(() { _error = _friendlyError(e.code); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found': return 'No account found with this email.';
      case 'wrong-password': return 'Incorrect password.';
      case 'email-already-in-use': return 'An account with this email already exists.';
      case 'weak-password': return 'Password must be at least 6 characters.';
      case 'invalid-email': return 'Please enter a valid email address.';
      default: return 'Something went wrong. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Icon(Icons.track_changes_rounded,
                      size: 56, color: cs.primary),
                  const SizedBox(height: 16),
                  Text(
                    _isSignUp ? 'Create account' : 'Welcome back',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSignUp
                        ? 'Your habits will sync across devices.'
                        : 'Sign in to sync your habits.',
                    style: TextStyle(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              (v == null || !v.contains('@'))
                                  ? 'Enter a valid email'
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              (v == null || v.length < 6)
                                  ? 'Minimum 6 characters'
                                  : null,
                        ),
                      ],
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_error!,
                          style: TextStyle(color: cs.onErrorContainer)),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Primary action
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 18, width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_isSignUp ? 'Create account' : 'Sign in'),
                  ),
                  const SizedBox(height: 12),

                  // Toggle sign-in / sign-up
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() {
                              _isSignUp = !_isSignUp;
                              _error = null;
                            }),
                    child: Text(_isSignUp
                        ? 'Already have an account? Sign in'
                        : 'No account? Create one'),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(),
                  ),

                  // Anonymous fallback
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _continueAnonymously,
                    icon: const Icon(Icons.person_outline),
                    label: const Text('Continue without account'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your data stays on this device. You can create an account later.',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

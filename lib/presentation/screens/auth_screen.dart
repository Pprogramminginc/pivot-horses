import 'package:flutter/material.dart';

import '../../app/backend/app_bootstrap.dart';
import '../../app/theme/app_theme.dart';
import '../widgets/section_card.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.onSignIn,
    required this.onSignUp,
    required this.onResetLocalPassword,
    required this.backendMode,
  });

  final Future<String?> Function(String email, String password) onSignIn;
  final Future<String?> Function(
    String email,
    String displayName,
    String password,
  )
  onSignUp;
  final Future<String?> Function(String email, String password)
  onResetLocalPassword;
  final BackendMode backendMode;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignIn = true;
  bool _isSubmitting = false;
  String? _error;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canResetLocalPassword =
        widget.backendMode == BackendMode.local && _isSignIn;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.scaffoldGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppTheme.heroGradient,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: AppTheme.outline),
                        boxShadow: const [
                          BoxShadow(
                            color: AppTheme.shadow,
                            blurRadius: 28,
                            offset: Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pivot Horses',
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Create your own horse-breeding profile or sign back in to keep building your stable.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppTheme.mutedInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SectionCard(
                      title: _isSignIn ? 'Sign In' : 'Create Account',
                      subtitle: _isSignIn
                          ? 'Open your saved stable'
                          : 'Start a personal player profile',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.tonal(
                                  onPressed: _isSubmitting
                                      ? null
                                      : () {
                                          setState(() {
                                            _isSignIn = true;
                                            _error = null;
                                          });
                                        },
                                  child: const Text('Sign In'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.tonal(
                                  onPressed: _isSubmitting
                                      ? null
                                      : () {
                                          setState(() {
                                            _isSignIn = false;
                                            _error = null;
                                          });
                                        },
                                  child: const Text('Create'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (!_isSignIn) ...[
                            TextField(
                              controller: _displayNameController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Display name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            textInputAction: _isSignIn
                                ? TextInputAction.done
                                : TextInputAction.next,
                            onSubmitted: _isSignIn ? (_) => _submit() : null,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          if (!_isSignIn) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: _confirmPasswordController,
                              obscureText: true,
                              onSubmitted: (_) => _submit(),
                              decoration: const InputDecoration(
                                labelText: 'Confirm password',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _isSubmitting ? null : _submit,
                              child: Text(
                                _isSubmitting
                                    ? 'Please wait...'
                                    : _isSignIn
                                    ? 'Sign In'
                                    : 'Create Account',
                              ),
                            ),
                          ),
                          if (canResetLocalPassword) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : _resetLocalPassword,
                                child: const Text('Reset local password'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: widget.backendMode == BackendMode.supabaseReady
                            ? AppTheme.secondary.withValues(alpha: 0.12)
                            : AppTheme.surfaceRaised.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: widget.backendMode == BackendMode.supabaseReady
                              ? AppTheme.secondary.withValues(alpha: 0.44)
                              : AppTheme.outline,
                        ),
                      ),
                      child: Text(
                        widget.backendMode == BackendMode.supabaseReady
                            ? 'Supabase bootstrap is connected. The app is ready for backend migration and live auth rollout.'
                            : 'Running in local mode for now. Add `SUPABASE_URL` and `SUPABASE_ANON_KEY` as Dart defines when you are ready to connect the app to Supabase.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final displayName = _displayNameController.text.trim();

    if (!_isSignIn && password != _confirmPasswordController.text) {
      setState(() {
        _isSubmitting = false;
        _error = 'Passwords do not match.';
      });
      return;
    }

    final error = _isSignIn
        ? await widget.onSignIn(email, password)
        : await widget.onSignUp(email, displayName, password);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
      _error = error;
    });
  }

  Future<void> _resetLocalPassword() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (password.length < 4) {
      setState(() {
        _error = 'Enter the account email and a new password first.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final error = await widget.onResetLocalPassword(email, password);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
      _error = error;
    });
  }
}

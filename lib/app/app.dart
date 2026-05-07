import 'package:flutter/material.dart';

import 'backend/app_bootstrap.dart';
import '../data/repositories/auth_repository.dart';
import '../domain/models/local_account.dart';
import '../presentation/screens/auth_screen.dart';
import '../presentation/screens/app_shell.dart';
import 'theme/app_theme.dart';

class PivotHorsesApp extends StatefulWidget {
  const PivotHorsesApp({super.key, required this.bootstrap});

  final AppBootstrap bootstrap;

  @override
  State<PivotHorsesApp> createState() => _PivotHorsesAppState();
}

class _PivotHorsesAppState extends State<PivotHorsesApp> {
  final AuthRepository _authRepository = const AuthRepository();
  LocalAccount? _activeAccount;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pivot Horses',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: _isLoading
          ? const Scaffold(
              body: DecoratedBox(
                decoration: BoxDecoration(gradient: AppTheme.scaffoldGradient),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.secondary),
                ),
              ),
            )
          : _activeAccount == null
          ? AuthScreen(
              onSignIn: _handleSignIn,
              onSignUp: _handleSignUp,
              onResetLocalPassword: _handleResetLocalPassword,
              backendMode: widget.bootstrap.mode,
            )
          : AppShell(account: _activeAccount!, onSignOut: _handleSignOut),
    );
  }

  Future<void> _restoreSession() async {
    final account = await _authRepository.loadActiveAccount();
    if (!mounted) {
      return;
    }
    setState(() {
      _activeAccount = account;
      _isLoading = false;
    });
  }

  Future<String?> _handleSignIn(String email, String password) async {
    final result = await _authRepository.signIn(
      email: email,
      password: password,
    );
    if (!mounted) {
      return result.error;
    }
    if (result.account != null) {
      setState(() {
        _activeAccount = result.account;
      });
    }
    return result.error;
  }

  Future<String?> _handleSignUp(
    String email,
    String displayName,
    String password,
  ) async {
    final result = await _authRepository.signUp(
      email: email,
      displayName: displayName,
      password: password,
    );
    if (!mounted) {
      return result.error;
    }
    if (result.account != null) {
      setState(() {
        _activeAccount = result.account;
      });
    }
    return result.error;
  }

  Future<String?> _handleResetLocalPassword(
    String email,
    String password,
  ) async {
    final result = await _authRepository.resetLocalPassword(
      email: email,
      password: password,
    );
    if (!mounted) {
      return result.error;
    }
    if (result.account != null) {
      setState(() {
        _activeAccount = result.account;
      });
    }
    return result.error;
  }

  Future<void> _handleSignOut() async {
    await _authRepository.signOut();
    if (!mounted) {
      return;
    }
    setState(() {
      _activeAccount = null;
    });
  }
}

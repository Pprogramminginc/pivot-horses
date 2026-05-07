import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/local_account.dart';

class AuthResult {
  const AuthResult({required this.account, this.error});

  final LocalAccount? account;
  final String? error;

  bool get isSuccess => account != null && error == null;
}

class AuthRepository {
  const AuthRepository();

  static const String _accountsKey = 'pivot_horses.auth.accounts.v1';
  static const String _activeAccountIdKey =
      'pivot_horses.auth.active_account.v1';

  Future<LocalAccount?> loadActiveAccount() async {
    final supabase = _supabaseClient;
    if (supabase != null) {
      final user = supabase.auth.currentUser;
      if (user == null) {
        return null;
      }
      return _loadSupabaseAccount(user);
    }

    final prefs = await SharedPreferences.getInstance();
    final activeId = prefs.getString(_activeAccountIdKey);
    if (activeId == null) {
      return null;
    }
    final accounts = await loadAccounts();
    for (final account in accounts) {
      if (account.id == activeId) {
        return account;
      }
    }
    return null;
  }

  Future<List<LocalAccount>> loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountsKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        return const [];
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_accountFromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<AuthResult> signUp({
    required String email,
    required String displayName,
    required String password,
  }) async {
    final supabase = _supabaseClient;
    if (supabase != null) {
      final normalizedEmail = email.trim().toLowerCase();
      final trimmedName = displayName.trim();
      if (normalizedEmail.isEmpty || trimmedName.isEmpty || password.isEmpty) {
        return const AuthResult(
          account: null,
          error: 'Fill in email, display name, and password.',
        );
      }

      try {
        final response = await supabase.auth.signUp(
          email: normalizedEmail,
          password: password,
          data: {'display_name': trimmedName},
        );
        if (response.session == null) {
          return const AuthResult(
            account: null,
            error:
                'Account created. Check your email to confirm it, then sign in.',
          );
        }
        final user = response.user;
        if (user == null) {
          return const AuthResult(
            account: null,
            error: 'Unable to create that account right now.',
          );
        }
        await _upsertSupabaseProfile(user, displayName: trimmedName);
        return AuthResult(account: await _loadSupabaseAccount(user));
      } on AuthException catch (error) {
        return AuthResult(account: null, error: error.message);
      } catch (_) {
        return const AuthResult(
          account: null,
          error: 'Unable to create that account right now.',
        );
      }
    }

    final normalizedEmail = email.trim().toLowerCase();
    final trimmedName = displayName.trim();
    if (normalizedEmail.isEmpty || trimmedName.isEmpty || password.isEmpty) {
      return const AuthResult(
        account: null,
        error: 'Fill in email, display name, and password.',
      );
    }

    final accounts = await loadAccounts();
    final exists = accounts.any((account) => account.email == normalizedEmail);
    if (exists) {
      return const AuthResult(
        account: null,
        error: 'That email already has an account.',
      );
    }

    final now = DateTime.now();
    final account = LocalAccount(
      id: 'acct_${now.microsecondsSinceEpoch}',
      email: normalizedEmail,
      displayName: trimmedName,
      passwordHash: _hashPassword(password),
      createdAt: now,
      lastSignedInAt: now,
    );

    await _saveAccounts([...accounts, account]);
    await _setActiveAccountId(account.id);
    return AuthResult(account: account);
  }

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final supabase = _supabaseClient;
    if (supabase != null) {
      try {
        final response = await supabase.auth.signInWithPassword(
          email: email.trim().toLowerCase(),
          password: password,
        );
        final user = response.user;
        if (user == null) {
          return const AuthResult(
            account: null,
            error: 'Incorrect email or password.',
          );
        }
        return AuthResult(account: await _loadSupabaseAccount(user));
      } on AuthException catch (error) {
        return AuthResult(account: null, error: error.message);
      } catch (_) {
        return const AuthResult(
          account: null,
          error: 'Incorrect email or password.',
        );
      }
    }

    final normalizedEmail = email.trim().toLowerCase();
    final passwordHash = _hashPassword(password);
    final accounts = await loadAccounts();

    for (final account in accounts) {
      if (account.email == normalizedEmail &&
          account.passwordHash == passwordHash) {
        final updated = account.copyWith(lastSignedInAt: DateTime.now());
        final updatedAccounts = accounts
            .map((entry) => entry.id == updated.id ? updated : entry)
            .toList();
        await _saveAccounts(updatedAccounts);
        await _setActiveAccountId(updated.id);
        return AuthResult(account: updated);
      }
    }

    return const AuthResult(
      account: null,
      error: 'Incorrect email or password.',
    );
  }

  Future<AuthResult> resetLocalPassword({
    required String email,
    required String password,
  }) async {
    if (_supabaseClient != null) {
      return const AuthResult(
        account: null,
        error: 'Use the Supabase password reset flow for live accounts.',
      );
    }

    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      return const AuthResult(
        account: null,
        error: 'Enter the email and a new password.',
      );
    }

    final accounts = await loadAccounts();
    for (final account in accounts) {
      if (account.email != normalizedEmail) {
        continue;
      }

      final updated = account.copyWith(
        passwordHash: _hashPassword(password),
        lastSignedInAt: DateTime.now(),
      );
      final updatedAccounts = accounts
          .map((entry) => entry.id == updated.id ? updated : entry)
          .toList();
      await _saveAccounts(updatedAccounts);
      await _setActiveAccountId(updated.id);
      return AuthResult(account: updated);
    }

    return const AuthResult(
      account: null,
      error: 'No local account exists for that email.',
    );
  }

  Future<void> signOut() async {
    final supabase = _supabaseClient;
    if (supabase != null) {
      await supabase.auth.signOut();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeAccountIdKey);
  }

  SupabaseClient? get _supabaseClient {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> _setActiveAccountId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeAccountIdKey, id);
  }

  Future<void> _saveAccounts(List<LocalAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(accounts.map(_accountToJson).toList());
    await prefs.setString(_accountsKey, encoded);
  }

  LocalAccount _accountFromJson(Map<String, dynamic> json) {
    return LocalAccount(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      passwordHash: json['passwordHash'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastSignedInAt: DateTime.parse(json['lastSignedInAt'] as String),
      handle: json['handle'] as String?,
      stableName: json['stableName'] as String?,
      favoriteBreed: json['favoriteBreed'] as String?,
      accentValue: (json['accentValue'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> _accountToJson(LocalAccount account) {
    return {
      'id': account.id,
      'email': account.email,
      'displayName': account.displayName,
      'passwordHash': account.passwordHash,
      'createdAt': account.createdAt.toIso8601String(),
      'lastSignedInAt': account.lastSignedInAt.toIso8601String(),
      'handle': account.handle,
      'stableName': account.stableName,
      'favoriteBreed': account.favoriteBreed,
      'accentValue': account.accentValue,
    };
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  LocalAccount _localAccountFromSupabaseUser(User user) {
    final metadata = user.userMetadata ?? const {};
    final displayName =
        (metadata['display_name'] as String?)?.trim().isNotEmpty == true
        ? (metadata['display_name'] as String).trim()
        : (user.email?.split('@').first ?? 'Player');
    final createdAt = DateTime.tryParse(user.createdAt) ?? DateTime.now();
    final lastSignedInAt =
        DateTime.tryParse(user.lastSignInAt ?? user.createdAt) ?? createdAt;

    return LocalAccount(
      id: user.id,
      email: user.email ?? '',
      displayName: displayName,
      passwordHash: '',
      createdAt: createdAt,
      lastSignedInAt: lastSignedInAt,
    );
  }

  Future<LocalAccount> _loadSupabaseAccount(User user) async {
    final baseAccount = _localAccountFromSupabaseUser(user);
    final supabase = _supabaseClient;
    if (supabase == null) {
      return baseAccount;
    }

    try {
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (profile == null) {
        return baseAccount;
      }

      return baseAccount.copyWith(
        email: (profile['email'] as String?) ?? baseAccount.email,
        displayName:
            (profile['display_name'] as String?) ?? baseAccount.displayName,
        createdAt:
            DateTime.tryParse((profile['created_at'] as String?) ?? '') ??
            baseAccount.createdAt,
        handle: profile['handle'] as String?,
        stableName: profile['stable_name'] as String?,
        favoriteBreed: profile['favorite_breed'] as String?,
        accentValue: (profile['accent_value'] as num?)?.toInt(),
      );
    } catch (_) {
      return baseAccount;
    }
  }

  Future<void> _upsertSupabaseProfile(
    User user, {
    required String displayName,
  }) async {
    final supabase = _supabaseClient;
    if (supabase == null) {
      return;
    }

    final normalizedDisplayName = displayName.trim().isEmpty
        ? (user.email?.split('@').first ?? 'Player')
        : displayName.trim();
    final handle =
        '@${normalizedDisplayName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '')}';

    try {
      await supabase.from('profiles').upsert({
        'id': user.id,
        'email': user.email,
        'display_name': normalizedDisplayName,
        'handle': handle == '@' ? '@player' : handle,
        'stable_name': '$normalizedDisplayName Stable',
      });
    } catch (_) {
      // The auth trigger should create the row. This upsert is only a safety net.
    }
  }
}

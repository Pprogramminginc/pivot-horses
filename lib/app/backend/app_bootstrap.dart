import 'package:supabase_flutter/supabase_flutter.dart';

enum BackendMode { local, supabaseReady }

class AppBootstrap {
  const AppBootstrap({
    required this.mode,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  final BackendMode mode;
  final String supabaseUrl;
  final String supabaseAnonKey;

  bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static Future<AppBootstrap> initialize() async {
    final url = const String.fromEnvironment('SUPABASE_URL');
    final anonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');

    if (url.isNotEmpty && anonKey.isNotEmpty) {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      return AppBootstrap(
        mode: BackendMode.supabaseReady,
        supabaseUrl: url,
        supabaseAnonKey: anonKey,
      );
    }

    return const AppBootstrap(
      mode: BackendMode.local,
      supabaseUrl: '',
      supabaseAnonKey: '',
    );
  }
}

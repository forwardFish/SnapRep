import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

class SupabaseService {
  static SupabaseService? _instance;
  late SupabaseClient _client;

  SupabaseService._internal();

  static SupabaseService get instance {
    _instance ??= SupabaseService._internal();
    return _instance!;
  }

  Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  SupabaseClient get client => _client;

  // Authentication methods
  Future<AuthResponse> signInAnonymously() async {
    return await _client.auth.signInAnonymously();
  }

  /// Sign in with Google OAuth
  /// Opens a web browser for Google authentication
  Future<bool> signInWithGoogle() async {
    try {
      debugPrint('🔐 Starting Supabase Google OAuth...');

      final result = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'snaprep://auth-callback',
      );

      debugPrint('✅ Google OAuth initiated: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Supabase Google OAuth error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  bool get isAuthenticated => _client.auth.currentUser != null;

  /// Get current user's access token (for backend API calls)
  String? get accessToken => _client.auth.currentSession?.accessToken;
}
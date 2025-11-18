import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

/// Google Authentication Service
/// Handles Google OAuth and backend integration
class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  GoogleSignIn? _googleSignIn;

  /// Initialize Google Sign-In
  void initialize() {
    try {
      _googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'profile',
        ],
        // Add your Google OAuth client ID here
        // You'll need to configure this in Firebase/Google Cloud Console
      );
      debugPrint('✅ Google Sign-In initialized successfully');
    } catch (e) {
      debugPrint('❌ Google Sign-In initialization failed: $e');
      // For development/testing, we'll continue without crashing
    }
  }

  /// Sign in with Google and authenticate with backend
  Future<GoogleSignInResult> signInWithGoogle() async {
    try {
      debugPrint('🔐 Starting Google Sign-In process...');

      // Check if GoogleSignIn is properly initialized
      if (_googleSignIn == null) {
        debugPrint('❌ GoogleSignIn not initialized');
        return GoogleSignInResult(
          success: false,
          error: 'Google Sign-In not properly configured',
        );
      }

      // Step 1: Google OAuth
      final GoogleSignInAccount? googleUser = await _googleSignIn?.signIn();

      if (googleUser == null) {
        debugPrint('❌ Google Sign-In cancelled by user');
        return GoogleSignInResult(
          success: false,
          error: 'Sign-in cancelled by user',
        );
      }

      debugPrint('✅ Google Sign-In successful: ${googleUser.email}');

      // Step 2: Get Google authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        debugPrint('❌ Failed to get Google authentication tokens');
        return GoogleSignInResult(
          success: false,
          error: 'Failed to get authentication tokens',
        );
      }

      debugPrint('✅ Google auth tokens retrieved successfully');

      // Step 3: Call backend login API
      final backendResult = await _authenticateWithBackend(
        email: googleUser.email,
        name: googleUser.displayName ?? '',
        photoUrl: googleUser.photoUrl,
        googleAccessToken: googleAuth.accessToken!,
        googleIdToken: googleAuth.idToken!,
      );

      if (!backendResult.success) {
        // If backend fails, sign out from Google
        await _googleSignIn?.signOut();
        return GoogleSignInResult(
          success: false,
          error: backendResult.error ?? 'Backend authentication failed',
        );
      }

      debugPrint('🎉 Complete Google Sign-In flow successful');

      return GoogleSignInResult(
        success: true,
        user: GoogleUserData(
          email: googleUser.email,
          name: googleUser.displayName ?? '',
          photoUrl: googleUser.photoUrl,
          accessToken: backendResult.accessToken,
          refreshToken: backendResult.refreshToken,
        ),
      );

    } on PlatformException catch (e) {
      debugPrint('❌ Platform exception during Google Sign-In: ${e.message}');

      // Handle specific plugin missing error
      if (e.code == 'MissingPluginException' || e.message?.contains('No implementation found') == true) {
        return GoogleSignInResult(
          success: false,
          error: 'Google Sign-In is not properly configured for this platform. Please configure Google Services.',
        );
      }

      return GoogleSignInResult(
        success: false,
        error: 'Platform error: ${e.message}',
      );
    } catch (e) {
      debugPrint('❌ Google Sign-In error: $e');
      return GoogleSignInResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Authenticate with backend using Google credentials
  Future<BackendAuthResult> _authenticateWithBackend({
    required String email,
    required String name,
    required String? photoUrl,
    required String googleAccessToken,
    required String googleIdToken,
  }) async {
    try {
      debugPrint('🌐 Calling backend login API...');

      final response = await http.post(
        Uri.parse('${AppConstants.nestJsApiUrl}/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': googleIdToken, // Use Google ID token as password
          'provider': 'google',
          'providerData': {
            'name': name,
            'photoUrl': photoUrl,
            'accessToken': googleAccessToken,
            'idToken': googleIdToken,
          },
        }),
      );

      debugPrint('📊 Backend response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        debugPrint('✅ Backend authentication successful');

        return BackendAuthResult(
          success: true,
          accessToken: data['access_token'] ?? data['accessToken'],
          refreshToken: data['refresh_token'] ?? data['refreshToken'],
          user: data['user'],
        );
      } else {
        debugPrint('❌ Backend authentication failed: ${response.statusCode}');
        debugPrint('📄 Error response: ${response.body}');

        return BackendAuthResult(
          success: false,
          error: 'Backend authentication failed: ${response.statusCode}',
        );
      }

    } catch (e) {
      debugPrint('❌ Backend API error: $e');
      return BackendAuthResult(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  /// Sign out from Google and clear local session
  Future<void> signOut() async {
    try {
      debugPrint('🔐 Signing out from Google...');
      await _googleSignIn?.signOut();
      debugPrint('✅ Google sign-out successful');
    } catch (e) {
      debugPrint('❌ Google sign-out error: $e');
    }
  }

  /// Check if user is currently signed in
  Future<bool> isSignedIn() async {
    return await _googleSignIn?.isSignedIn() ?? false;
  }

  /// Get current Google user (if signed in)
  GoogleSignInAccount? getCurrentUser() {
    return _googleSignIn?.currentUser;
  }
}

/// Google Sign-In Result
class GoogleSignInResult {
  final bool success;
  final String? error;
  final GoogleUserData? user;

  GoogleSignInResult({
    required this.success,
    this.error,
    this.user,
  });
}

/// Backend Authentication Result
class BackendAuthResult {
  final bool success;
  final String? error;
  final String? accessToken;
  final String? refreshToken;
  final Map<String, dynamic>? user;

  BackendAuthResult({
    required this.success,
    this.error,
    this.accessToken,
    this.refreshToken,
    this.user,
  });
}

/// Google User Data
class GoogleUserData {
  final String email;
  final String name;
  final String? photoUrl;
  final String? accessToken;
  final String? refreshToken;

  GoogleUserData({
    required this.email,
    required this.name,
    this.photoUrl,
    this.accessToken,
    this.refreshToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }
}
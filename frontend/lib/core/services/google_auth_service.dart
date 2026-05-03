import 'package:flutter/foundation.dart';
// import 'package:google_sign_in/google_sign_in.dart'; // TEMPORARILY DISABLED

/// Google Authentication Service
/// Handles Google OAuth and backend integration
/// NOTE: Currently disabled due to Google Play Services dependency issues
class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  // GoogleSignIn? _googleSignIn; // TEMPORARILY DISABLED

  /// Initialize Google Sign-In
  void initialize() {
    debugPrint('⚠️ Google Sign-In is temporarily disabled');
    // Feature temporarily disabled to avoid Google Play Services network issues
  }

  /// Sign in with Google and authenticate with backend
  Future<GoogleSignInResult> signInWithGoogle() async {
    debugPrint('⚠️ Google Sign-In feature is temporarily disabled');
    return GoogleSignInResult(
      success: false,
      error: 'Google Sign-In is temporarily unavailable. Please use email/password login.',
    );
  }

  /// Sign out from Google and clear local session
  Future<void> signOut() async {
    debugPrint('⚠️ Google Sign-Out: Feature is temporarily disabled');
  }

  /// Check if user is currently signed in
  Future<bool> isSignedIn() async {
    return false;
  }

  /// Get current Google user (if signed in)
  dynamic getCurrentUser() {
    return null;
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

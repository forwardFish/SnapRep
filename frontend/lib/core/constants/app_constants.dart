// Core constants for the SnapRep app
class AppConstants {
  // Environment configuration
  static const bool isProduction = bool.fromEnvironment('IS_PRODUCTION', defaultValue: false);

  // API URLs - Environment specific
  // Using 127.0.0.1 instead of localhost for better Windows compatibility
  static const String _developmentApiUrl = 'http://127.0.0.1:3000';
  static const String _productionApiUrl = 'https://your-production-domain.com'; // TODO: Replace with actual production URL

  static String get nestJsApiUrl => isProduction ? _productionApiUrl : _developmentApiUrl;

  // Supabase configuration - Environment specific
  static const String _developmentSupabaseUrl = 'https://tvjcmleckqovnieuexgu.supabase.co';
  static const String _productionSupabaseUrl = 'https://your-production-supabase.supabase.co'; // TODO: Replace with production Supabase URL

  static String get supabaseUrl => isProduction ? _productionSupabaseUrl : _developmentSupabaseUrl;

  // Note: In production, use different keys for dev/prod
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR2amNtbGVja3Fvdm5pZXVleGd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA1NzQ3NjksImV4cCI6MjA0NjE1MDc2OX0.vYCz8wUhMT0CPRQ68r4pYoQB4i6Y8cVEFAG23l0C0hY';

  // App colors (based on HTML design)
  static const String yellowCta = '#FFD700';
  static const String premiumBlack = '#1A1A1A';
  static const String textSecondary = '#64748B';

  // Performance targets
  static const int timeToValueTargetMs = 30000; // 30 seconds
  static const int cardGenerationTargetMs = 800; // 800ms
  static const int quickRecommendationTargetMs = 5000; // 5 seconds
}
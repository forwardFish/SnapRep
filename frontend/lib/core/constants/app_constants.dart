// Core constants for the SnapRep app
class AppConstants {
  // API URLs
  static const String supabaseUrl = 'https://tvjcmleckqovnieuexgu.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR2amNtbGVja3Fvdm5pZXVleGd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA1NzQ3NjksImV4cCI6MjA0NjE1MDc2OX0.vYCz8wUhMT0CPRQ68r4pYoQB4i6Y8cVEFAG23l0C0hY';
  static const String nestJsApiUrl = 'http://localhost:3000/api/v1';

  // App colors (based on HTML design)
  static const String yellowCta = '#FFD700';
  static const String premiumBlack = '#1A1A1A';
  static const String textSecondary = '#64748B';

  // Performance targets
  static const int timeToValueTargetMs = 30000; // 30 seconds
  static const int cardGenerationTargetMs = 800; // 800ms
  static const int quickRecommendationTargetMs = 5000; // 5 seconds
}
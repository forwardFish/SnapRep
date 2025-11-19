/// API configuration constants for SnapRep application
class ApiConfig {
  /// Base URL for the API endpoints
  ///
  /// For development:
  /// - Local backend: 'http://localhost:3000/api'
  /// - Local Supabase Edge Functions: 'http://localhost:54321/functions/v1'
  ///
  /// For production:
  /// - Production backend: 'https://api.snaprep.com'
  /// - Supabase Edge Functions: 'https://your-project.supabase.co/functions/v1'
  static const String baseUrl = 'http://localhost:3000/api';

  /// Supabase configuration
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key-here';

  /// API endpoints
  static const String equipmentEndpoint = '/equipment';
  static const String scenariosEndpoint = '/scenarios';
  static const String exercisesEndpoint = '/exercises';
  static const String workoutSessionsEndpoint = '/workout-sessions';
  static const String challengesEndpoint = '/challenges';
  static const String usersEndpoint = '/users';
  static const String authEndpoint = '/auth';

  /// Timeout configurations (in milliseconds)
  static const int connectTimeout = 5000;
  static const int receiveTimeout = 10000;

  /// Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// API versioning
  static const String apiVersion = 'v1';

  /// Environment check
  static bool get isDevelopment => baseUrl.contains('localhost');
  static bool get isProduction => !isDevelopment;
}
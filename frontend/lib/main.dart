import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/supabase_service.dart';
import 'core/services/google_auth_service.dart';
import 'core/providers/home_provider.dart';
import 'core/providers/workout_guide_provider.dart';
import 'core/providers/workout_result_provider.dart';
import 'core/providers/result_card_provider.dart';
import 'core/providers/my_page_provider.dart';
import 'features/home/screens/home_page.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    await SupabaseService.instance.initialize();
    debugPrint('✅ Supabase initialized successfully');
  } catch (e) {
    debugPrint('❌ Supabase initialization failed: $e');
  }

  // Initialize Google Auth Service
  try {
    GoogleAuthService().initialize();
    debugPrint('✅ Google Auth Service initialized successfully');
  } catch (e) {
    debugPrint('❌ Google Auth Service initialization failed: $e');
    // Continue anyway - Google Sign-In will show appropriate error
  }

  runApp(const SnapRepApp());
}

class SnapRepApp extends StatelessWidget {
  const SnapRepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutGuideProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutResultProvider()),
        ChangeNotifierProvider(create: (_) => ResultCardProvider()),
        ChangeNotifierProvider(create: (_) => MyPageProvider()),
      ],
      child: MaterialApp(
        title: 'SnapRep',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFD700)),
          useMaterial3: true,
          fontFamily: 'SF Pro Display',
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.getRoutes(),
        navigatorObservers: [AppRouteObserver()],
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      final supabaseService = SupabaseService.instance;

      // Check if user is already authenticated
      if (!supabaseService.isAuthenticated) {
        debugPrint('🔐 No existing session, signing in anonymously...');
        final response = await supabaseService.signInAnonymously();

        if (response.user != null) {
          debugPrint('✅ Anonymous authentication successful');
        } else {
          throw Exception('Anonymous authentication failed');
        }
      } else {
        debugPrint('✅ Existing session found');
      }

      setState(() {
        _isInitializing = false;
      });

    } catch (e) {
      debugPrint('❌ Authentication error: $e');
      // 对于启动页后的认证，如果失败就跳过认证直接进入主页
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
              ),
              SizedBox(height: 16),
              Text(
                'Initializing SnapRep...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const HomePage();
  }
}
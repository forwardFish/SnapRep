import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';

/// SnapRep Simple Splash Screen
/// Clean English design inspired by reference UI
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startNavigationTimer();
  }

  void _setupAnimations() {
    // Simple fade animation (2 seconds)
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Start fade animation
    _fadeController.forward();
  }

  void _startNavigationTimer() {
    // Navigate to home after 3 seconds
    Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        _navigateToHome();
      }
    });
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          // Purple gradient background like reference image
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667eea), // Light purple
              Color(0xFF764ba2), // Medium purple
              Color(0xFF5a4fcf), // Deep purple
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Column(
                children: [
                  // Main content area
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // App logo/title
                          _buildAppTitle(),

                          const SizedBox(height: 24),

                          // Tagline
                          _buildTagline(),
                        ],
                      ),
                    ),
                  ),

                  // Bottom branding
                  _buildBottomBranding(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppTitle() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          Color(0xFFFFFFFF), // White
          Color(0xFFF0F8FF), // Alice blue
        ],
      ).createShader(bounds),
      child: const Text(
        'SnapRep',
        style: TextStyle(
          fontSize: 64, // Large title like reference
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: -2.0, // Tight spacing for modern look
          shadows: [
            Shadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagline() {
    return const Text(
      'Fitness Anywhere',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: Colors.white,
        letterSpacing: 2.0,
        shadows: [
          Shadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBranding() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        children: [
          // Professional SVG logo that represents SnapRep's core concept
          SvgPicture.asset(
            'assets/images/snaprep_icon.svg',
            width: 64,
            height: 64,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
    );
  }
}

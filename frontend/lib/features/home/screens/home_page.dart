import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/home_provider.dart';
import '../../../core/models/scenario.dart';
import '../../../core/models/equipment.dart';
import '../widgets/hero_section.dart';
import '../widgets/horizontal_scroll_section.dart';
import '../widgets/theme_week_section.dart';
import '../../../shared/widgets/bottom_navigation_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load homepage data when the page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().loadHomeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<HomeProvider>().refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Consumer<HomeProvider>(
              builder: (context, homeProvider, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: HeroSection(
                        onCtaPressed: _onQuickStartPressed,
                      ),
                    ),

                    // Choose Your Space (Scenarios)
                    HorizontalScrollSection<Scenario>(
                      title: 'Choose Your Space',
                      items: homeProvider.scenarios,
                      getTitle: (scenario) => scenario.name,
                      getImageUrl: (scenario) => _getScenarioImageUrl(scenario.code),
                      onItemTap: (scenario) => () => _onScenarioPressed(scenario),
                      isLoading: homeProvider.isLoadingScenarios,
                      error: homeProvider.scenariosError,
                      onRetry: () => homeProvider.loadScenarios(),
                    ),

                    // Equipment
                    HorizontalScrollSection<Equipment>(
                      title: 'Equipment',
                      items: homeProvider.equipment,
                      getTitle: (equipment) => equipment.name,
                      getImageUrl: (equipment) => _getEquipmentImageUrl(equipment.code),
                      onItemTap: (equipment) => () => _onEquipmentPressed(equipment),
                      isLoading: homeProvider.isLoadingEquipment,
                      error: homeProvider.equipmentError,
                      onRetry: () => homeProvider.loadEquipment(),
                    ),

                    // Theme Week
                    ThemeWeekSection(
                      currentThemeWeek: homeProvider.currentThemeWeek,
                      isLoading: homeProvider.isLoadingThemeWeek,
                      isJoining: homeProvider.isJoiningThemeWeek,
                      error: homeProvider.themeWeekError,
                      onJoinPressed: _onJoinThemeWeek,
                      onStartPressed: _onStartThemeWeekWorkout,
                      onRetry: () => homeProvider.loadCurrentThemeWeek(),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }

  // Event Handlers

  void _onQuickStartPressed() {
    // Navigate to workout result page with quick recommendation
    debugPrint('Quick start pressed - navigating to workout result');
    // TODO: Implement navigation to workout result page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Quick start - generating workout recommendations...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onScenarioPressed(Scenario scenario) {
    debugPrint('Scenario pressed: ${scenario.name}');
    // TODO: Navigate to workout guide page with pre-selected scenario
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected scenario: ${scenario.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onEquipmentPressed(Equipment equipment) {
    debugPrint('Equipment pressed: ${equipment.name}');
    // TODO: Navigate to workout guide page with pre-selected equipment
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected equipment: ${equipment.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _onJoinThemeWeek() async {
    final homeProvider = context.read<HomeProvider>();
    final success = await homeProvider.joinThemeWeek();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Successfully joined theme week!'
                : 'Failed to join theme week',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onStartThemeWeekWorkout() {
    final themeWeek = context.read<HomeProvider>().currentThemeWeek;
    if (themeWeek != null) {
      debugPrint('Starting theme week workout: ${themeWeek.title}');
      // TODO: Navigate to workout result page with theme week equipment
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Starting ${themeWeek.title} workout...'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });

    switch (index) {
      case 0:
        // Already on home page
        break;
      case 1:
        // Navigate to camera page
        debugPrint('Navigate to camera page');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera feature - AI equipment recognition'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
      case 2:
        // Navigate to profile page
        debugPrint('Navigate to profile page');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile page - cards & history'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
    }
  }

  // Helper Methods

  String? _getScenarioImageUrl(String scenarioCode) {
    // Map scenario codes to appropriate Unsplash images
    switch (scenarioCode.toLowerCase()) {
      case 'office':
        return 'https://images.unsplash.com/photo-1497366216548-37526070297c?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80';
      case 'home':
      case 'living_room':
        return 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80';
      case 'gym':
        return 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80';
      case 'park':
        return 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80';
      default:
        return null;
    }
  }

  String? _getEquipmentImageUrl(String equipmentCode) {
    // Map equipment codes to appropriate Unsplash images
    switch (equipmentCode.toLowerCase()) {
      case 'bodyweight':
      case 'hands_free':
        return 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80';
      case 'chair':
        return 'https://images.unsplash.com/photo-1506439773649-6e0eb8cfb237?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80';
      case 'wall':
        return 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80';
      case 'bottle':
      case 'water_bottle':
        return 'https://images.unsplash.com/photo-1523362628745-0c100150b504?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80';
      case 'backpack':
        return 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80';
      case 'book':
        return 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80';
      case 'broom':
        return 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80';
      case 'luggage':
        return 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80';
      case 'ai_scan':
        return 'https://images.unsplash.com/photo-1620712943543-bcc4688e7485?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80';
      default:
        return null;
    }
  }
}
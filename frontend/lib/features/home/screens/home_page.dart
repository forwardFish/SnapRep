import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/home_provider.dart';
import '../../../core/models/scenario.dart';
import '../../../core/models/equipment.dart';
import '../widgets/hero_section.dart';
import '../widgets/horizontal_scroll_section.dart';
import '../widgets/challenge_hero_section.dart';
import '../../../shared/widgets/bottom_navigation_bar.dart';
import '../../../routes/app_routes.dart';
import '../../challenges/screens/item_challenge_list_page.dart';

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
                      title: 'Scenarios',
                      items: homeProvider.scenarios,
                      getTitle: (scenario) => scenario.name,
                      getImageUrl: (scenario) => scenario.fullIconUrl,
                      onItemTap: (scenario) =>
                          () => _onScenarioPressed(scenario),
                      isLoading: homeProvider.isLoadingScenarios,
                      error: homeProvider.scenariosError,
                      onRetry: () => homeProvider.loadScenarios(),
                    ),

                    // Equipment
/*                     HorizontalScrollSection<Equipment>(
                      title: 'Equipments',
                      items: homeProvider.equipment,
                      getTitle: (equipment) => equipment.name,
                      getImageUrl: (equipment) => equipment.fullIconUrl,
                      onItemTap: (equipment) =>
                          () => _onEquipmentPressed(equipment),
                      isLoading: homeProvider.isLoadingEquipment,
                      error: homeProvider.equipmentError,
                      onRetry: () => homeProvider.loadEquipment(),
                    ), */

                    // Item Challenge Section Title
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Item Challenge',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Item Challenge Hero Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ChallengeHeroSection(
                        onPressed: _onChallengesPressed,
                        // Local image for challenge hero section
                        imageUrl: 'assets/images/backpack_workout.jpg',
                      ),
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
    debugPrint('🔄 Quick start pressed - navigating to popular exercises page');
    debugPrint('📍 Route: ${AppRoutes.recommendedExercises}');

    debugPrint('🎯 Navigating to popular exercises page');

    // 直接导航到热门推荐动作页面，不需要用户ID
    try {
      AppRoutes.navigateTo(context, AppRoutes.recommendedExercises);
      debugPrint('✅ Navigation call completed');
    } catch (e) {
      debugPrint('❌ Navigation failed: $e');
      // 如果导航失败，先尝试直接使用Navigator
      Navigator.of(context).pushNamed(AppRoutes.recommendedExercises);
    }
  }

  void _onScenarioPressed(Scenario scenario) {
    debugPrint('Scenario pressed: ${scenario.name}');
    // Navigate to equipment selection with pre-selected scenario
    AppRoutes.navigateToEquipmentSelection(
      context,
      scenarioCode: scenario.code,
    );
  }

  void _onEquipmentPressed(Equipment equipment) {
    debugPrint('Equipment pressed: ${equipment.name}');
    // Navigate to scenario selection page (Step 1a)
    AppRoutes.navigateTo(context, AppRoutes.scenarioSelection);
  }

  void _onChallengesPressed() {
    debugPrint('Navigate to item challenge list page');
    // 导航到物品挑战列表页面
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ItemChallengeListPage(),
      ),
    );
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
        // Navigate to scenario selection page (new Step 1a)
        debugPrint('Navigate to scenario selection page');
        AppRoutes.navigateTo(context, AppRoutes.scenarioSelection);
        break;
      case 2:
        // Navigate to profile page
        debugPrint('Navigate to profile page');
        AppRoutes.navigateToMyPage(context);
        break;
    }
  }
}

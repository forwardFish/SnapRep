import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/home_provider.dart';
import '../../../core/models/scenario.dart';
import '../../../core/models/equipment.dart';
import '../../../core/models/exercise.dart';
import '../../../core/models/target_muscle.dart';
import '../../../core/models/workout_intent.dart';
import '../widgets/hero_section.dart';
import '../widgets/horizontal_scroll_section.dart';
import '../widgets/challenge_hero_section.dart';
import '../../../shared/widgets/bottom_navigation_bar.dart';
import '../../../routes/app_routes.dart';

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
                      getImageUrl: (scenario) => _getScenarioImageUrl(scenario.code),
                      onItemTap: (scenario) => () => _onScenarioPressed(scenario),
                      isLoading: homeProvider.isLoadingScenarios,
                      error: homeProvider.scenariosError,
                      onRetry: () => homeProvider.loadScenarios(),
                    ),

                    // Equipment
                    HorizontalScrollSection<Equipment>(
                      title: 'Equipments',
                      items: homeProvider.equipment,
                      getTitle: (equipment) => equipment.name,
                      getImageUrl: (equipment) => _getEquipmentImageUrl(equipment.code),
                      onItemTap: (equipment) => () => _onEquipmentPressed(equipment),
                      isLoading: homeProvider.isLoadingEquipment,
                      error: homeProvider.equipmentError,
                      onRetry: () => homeProvider.loadEquipment(),
                    ),

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
    // Navigate to workout result page with quick recommendation
    debugPrint('Quick start pressed - navigating to workout result');
    AppRoutes.quickStartWorkout(context);
  }

  void _onScenarioPressed(Scenario scenario) {
    debugPrint('Scenario pressed: ${scenario.name}');
    AppRoutes.scenarioQuickSelect(
      context,
      scenarioCode: scenario.code,
    );
  }

  void _onEquipmentPressed(Equipment equipment) {
    debugPrint('Equipment pressed: ${equipment.name}');

    // 为每个器材创建模拟的动作训练数据
    final exercises = _createMockExercisesForEquipment(equipment);

    if (exercises.isNotEmpty) {
      // 直接跳转到动作训练页面
      AppRoutes.navigateToProfessionalWorkoutVideo(
        context,
        exercise: exercises.first,
        exercises: exercises,
        currentExerciseIndex: 0,
      );
    } else {
      // 如果没有找到对应的动作，显示提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${equipment.name} 的训练动作正在开发中'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }


  void _onChallengesPressed() {
    debugPrint('Navigate to challenges page');
    AppRoutes.navigateTo(context, AppRoutes.challenges);
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
        // Navigate to camera page (AI scene detection)
        debugPrint('Navigate to AI camera detection page');
        AppRoutes.navigateTo(context, AppRoutes.cameraDetection);
        break;
      case 2:
        // Navigate to profile page
        debugPrint('Navigate to profile page');
        AppRoutes.navigateToMyPage(context);
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

  // 为器材创建模拟动作数据
  List<Exercise> _createMockExercisesForEquipment(Equipment equipment) {
    final exerciseTemplates = {
      '5kg Dumbbell': [
        {
          'name': 'Dumbbell Bicep Curls',
          'description': 'Classic exercise to build arm bicep muscles',
          'videoUrl': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
          'duration': 60,
          'reps': 12,
        },
        {
          'name': 'Dumbbell Shoulder Press',
          'description': 'Essential exercise for shoulder muscle development',
          'videoUrl': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_2mb.mp4',
          'duration': 45,
          'reps': 10,
        },
        {
          'name': 'Dumbbell Squats',
          'description': 'Full-body strength training with dumbbell support',
          'videoUrl': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_5mb.mp4',
          'duration': 50,
          'reps': 15,
        },
      ],
      'Yoga Mat': [
        {
          'name': 'Plank Hold',
          'description': 'Core muscle group foundation training exercise',
          'videoUrl': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
          'duration': 60,
          'reps': 1,
        },
        {
          'name': 'Crunches',
          'description': 'Classic abdominal muscle strengthening exercise',
          'videoUrl': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_2mb.mp4',
          'duration': 45,
          'reps': 20,
        },
        {
          'name': 'Russian Twists',
          'description': 'Exercise for obliques and core stability',
          'videoUrl': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_5mb.mp4',
          'duration': 40,
          'reps': 16,
        },
      ],
      'Resistance Band': [
        {
          'name': 'Resistance Band Rows',
          'description': 'Effective exercise for back muscle development',
          'videoUrl': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
          'duration': 50,
          'reps': 12,
        },
        {
          'name': 'Resistance Band Squats',
          'description': 'Enhanced leg training with added resistance',
          'videoUrl': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_2mb.mp4',
          'duration': 60,
          'reps': 15,
        },
      ],
    };

    final templates = exerciseTemplates[equipment.name] ?? [
      {
        'name': '${equipment.name} Basic Training',
        'description': 'Basic fitness exercise using ${equipment.name}',
        'videoUrl': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
        'duration': 45,
        'reps': 10,
      }
    ];

    return templates.asMap().entries.map<Exercise>((entry) {
      final index = entry.key;
      final template = entry.value;
      return Exercise(
        id: '${equipment.id}_exercise_$index',
        code: '${equipment.code}_ex_$index',
        name: template['name'] as String,
        description: template['description'] as String,
        primaryMuscle: TargetMuscle.fullBody,
        secondaryMuscles: const [TargetMuscle.core],
        intentType: WorkoutIntent.strength,
        difficulty: ExerciseDifficulty.intermediate,
        durationSeconds: template['duration'] as int,
        sets: 3,
        repetitions: template['reps'] as int,
        demoVideoUrl: template['videoUrl'] as String,
        thumbnailUrl: 'https://via.placeholder.com/400x300/4CAF50/FFFFFF?text=${Uri.encodeComponent(template['name'] as String)}',
        keyPoints: ['Prepare your ${equipment.name}', 'Maintain proper posture', 'Control movement tempo', 'Focus on breathing rhythm'],
        safetyWarnings: const ['Ensure equipment is stable', 'Be mindful of range of motion', 'Stop immediately if you feel discomfort'],
        benefits: 'Effective training using ${equipment.name} to improve muscle strength and endurance',
        tags: const [ExerciseTag.strength],
      );
    }).toList();
  }
}
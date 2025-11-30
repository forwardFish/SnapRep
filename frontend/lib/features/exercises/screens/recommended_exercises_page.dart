import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/popular_exercise_dto.dart';
import '../../../core/models/exercise.dart';
import '../../../core/models/target_muscle.dart';
import '../../../core/models/workout_intent.dart';
import '../../../core/services/popular_exercises_service.dart';
import '../../workout_result/screens/modern_workout_result_page.dart';

/// Recommended Exercises Page - Modern Premium Design
/// Displays popular exercises in beautiful cards matching reference UI
/// Features: Hero images, gradient overlays, badges, smooth animations
class RecommendedExercisesPage extends StatefulWidget {
  const RecommendedExercisesPage({super.key});

  @override
  State<RecommendedExercisesPage> createState() =>
      _RecommendedExercisesPageState();
}

class _RecommendedExercisesPageState extends State<RecommendedExercisesPage>
    with SingleTickerProviderStateMixin {
  List<PopularExerciseDto> exercises = [];
  bool isLoading = false;
  String? error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadPopularExercises();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();
  }

  Future<void> _loadPopularExercises() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final service = PopularExercisesService();
      final exerciseList = await service.getPopularExercises();

      setState(() {
        exercises = exerciseList;
        isLoading = false;
      });

      debugPrint(
          '✅ Popular exercises loaded from API: ${exerciseList.length} items');
    } catch (e) {
      debugPrint('❌ Failed to load popular exercises from API: $e');
      setState(() {
        error = 'Failed to load exercises: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? _buildLoadingState()
          : error != null
              ? _buildErrorState()
              : exercises.isEmpty
                  ? _buildEmptyState()
                  : _buildExerciseContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFD4A574), Color(0xFFE5A000)],
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading Popular Exercises',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Finding the best workouts for you...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return SafeArea(
      child: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Oops! Something went wrong',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _loadPopularExercises,
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text(
                        'Try Again',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4A574),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SafeArea(
      child: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFD4A574).withOpacity(0.2),
                            const Color(0xFFE5A000).withOpacity(0.2),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fitness_center_outlined,
                        size: 64,
                        color: Color(0xFFD4A574),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'No Training History Yet',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Complete some workouts and your\nmost practiced exercises will appear here',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/home',
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.play_arrow, size: 20),
                      label: const Text(
                        'Start First Workout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4A574),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseContent() {
    return SafeArea(
      child: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildExerciseGrid(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF2C3E50),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Title section
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Popular Exercises',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C3E50),
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Trending workouts worldwide',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          // Filter button (future enhancement)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.tune,
              color: Color(0xFF2C3E50),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseGrid() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 20,
        ),
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          return _buildExerciseCard(exercises[index], index);
        },
      ),
    );
  }

  Widget _buildExerciseCard(PopularExerciseDto exercise, int index) {
    // Stagger animation based on index
    final delay = index * 50;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _navigateToExercise(exercise),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Image Section
              Expanded(
                flex: 5,
                child: _buildCardImage(exercise),
              ),

              // Content Section
              Expanded(
                flex: 4,
                child: _buildCardContent(exercise),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardImage(PopularExerciseDto exercise) {
    // 获取本地fallback图片路径 - 根据肌肉群选择
    String getFallbackImagePath() {
      // final muscle = exercise.primaryMuscle.toLowerCase();

      // 根据肌肉群返回对应的本地图片
      // if (muscle.contains('chest') || muscle.contains('胸')) {
      //   return 'assets/images/fallbacks/exercise_default_chest.jpg';
      // } else if (muscle.contains('back') || muscle.contains('背')) {
      //   return 'assets/images/fallbacks/exercise_default_back.jpg';
      // } else if (muscle.contains('leg') || muscle.contains('腿')) {
      //   return 'assets/images/fallbacks/exercise_default_legs.jpg';
      // } else if (muscle.contains('arm') || muscle.contains('手臂')) {
      //   return 'assets/images/fallbacks/exercise_default_arms.jpg';
      // } else if (muscle.contains('core') || muscle.contains('腹') || muscle.contains('核心')) {
      //   return 'assets/images/fallbacks/exercise_default_core.jpg';
      // } else if (muscle.contains('shoulder') || muscle.contains('肩')) {
      //   return 'assets/images/fallbacks/exercise_default_shoulders.jpg';
      // }

      // 默认通用健身图片
      return 'assets/images/fallbacks/exercise_default_general.jpg';
    }

    // 获取图片URL - 使用 Exercise 模型的 displayImageUrl getter
    String? getImageUrl() {
      // 使用 Exercise 模型提供的完整图片 URL（会自动转换为后端 API URL）
      return exercise.displayImageUrl;
    }

    final imageUrl = getImageUrl();
    final fallbackPath = getFallbackImagePath();

    return Stack(
      children: [
        // Main image
        Positioned.fill(
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: const Color(0xFFF8F8F8),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFD4A574),
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) {
                      // 如果后端图片加载失败,使用本地asset图片
                      return Image.asset(
                        fallbackPath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // 如果本地图片也失败,显示深色渐变背景
                          return Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF374151),
                                  Color(0xFF1F2937),
                                ],
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.fitness_center,
                                size: 48,
                                color: Color(0xFFD4A574),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  )
                : // 如果后端没有图片URL,直接使用本地asset
                Image.asset(
                    fallbackPath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // 如果本地图片加载失败,显示渐变背景
                      return Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF374151),
                              Color(0xFF1F2937),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.fitness_center,
                            size: 48,
                            color: Color(0xFFD4A574),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),

        // Gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.3),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
          ),
        ),

        // Top badges
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Difficulty badge
              _buildDifficultyBadge(exercise.difficulty),
              // Duration badge
              _buildDurationBadge(exercise.durationSeconds),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color badgeColor;
    String label;

    switch (difficulty.toLowerCase()) {
      case 'beginner':
      case 'easy':
      case 'green':
        badgeColor = const Color(0xFF10B981);
        label = 'Easy';
        break;
      case 'intermediate':
      case 'medium':
      case 'yellow':
        badgeColor = const Color(0xFFF59E0B);
        label = 'Medium';
        break;
      case 'advanced':
      case 'hard':
      case 'red':
        badgeColor = const Color(0xFFEF4444);
        label = 'Hard';
        break;
      default:
        badgeColor = const Color(0xFF6B7280);
        label = 'Medium';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDurationBadge(int seconds) {
    final minutes = (seconds / 60).ceil();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            '${minutes}min',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContent(PopularExerciseDto exercise) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Exercise name
          Text(
            exercise.name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C3E50),
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          // Muscle tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFD4A574).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              exercise.muscleDisplayName,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFFD4A574),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Bottom row - Popularity
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  size: 14,
                  color: Color(0xFFE5A000),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  exercise.popularityText,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Arrow icon
              const Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Color(0xFFD4A574),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToExercise(PopularExerciseDto popularExercise) {
    debugPrint(
        '📍 Navigating to exercise detail: ${popularExercise.name} (ID: ${popularExercise.id})');

    // Convert PopularExerciseDto to Exercise object
    TargetMuscle primaryMuscle;
    try {
      primaryMuscle = TargetMuscle.values.firstWhere(
        (m) =>
            m.name.toLowerCase() ==
                popularExercise.primaryMuscle.toLowerCase() ||
            m.code.toLowerCase() == popularExercise.primaryMuscle.toLowerCase(),
        orElse: () => TargetMuscle.fullBody,
      );
    } catch (e) {
      primaryMuscle = TargetMuscle.fullBody;
    }

    WorkoutIntent intentType;
    try {
      final firstIntent = popularExercise.intentType.isNotEmpty
          ? popularExercise.intentType.first
          : 'STRETCH';

      intentType = WorkoutIntent.values.firstWhere(
        (i) =>
            i.name.toLowerCase() == firstIntent.toLowerCase() ||
            i.code.toLowerCase() == firstIntent.toLowerCase(),
        orElse: () => WorkoutIntent.stretch,
      );
    } catch (e) {
      intentType = WorkoutIntent.stretch;
    }

    ExerciseDifficulty difficulty;
    try {
      difficulty = ExerciseDifficulty.values.firstWhere(
        (d) => d.name.toLowerCase() == popularExercise.difficulty.toLowerCase(),
        orElse: () => ExerciseDifficulty.intermediate,
      );
    } catch (e) {
      difficulty = ExerciseDifficulty.intermediate;
    }

    List<ExerciseTag> parsedTags = popularExercise.tags.map((tag) {
      try {
        return ExerciseTag.values.firstWhere(
          (t) => t.name.toLowerCase() == tag.toLowerCase(),
          orElse: () => ExerciseTag.handsFreee,
        );
      } catch (e) {
        return ExerciseTag.handsFreee;
      }
    }).toList();

    if (parsedTags.isEmpty) {
      parsedTags = [ExerciseTag.handsFreee];
    }

    final exercise = Exercise(
      id: popularExercise.id,
      code: popularExercise.code,
      name: popularExercise.name,
      description: popularExercise.description.isNotEmpty
          ? popularExercise.description
          : 'An effective training exercise that helps improve your fitness',
      primaryMuscle: primaryMuscle,
      secondaryMuscles: popularExercise.secondaryMuscles.map((muscle) {
        try {
          return TargetMuscle.values.firstWhere(
            (m) => m.name.toLowerCase() == muscle.toLowerCase(),
            orElse: () => TargetMuscle.fullBody,
          );
        } catch (e) {
          return TargetMuscle.fullBody;
        }
      }).toList(),
      intentType: intentType,
      difficulty: difficulty,
      durationSeconds: popularExercise.durationSeconds,
      sets: popularExercise.sets,
      repetitions: popularExercise.sets * 10,
      thumbnailUrl:
          popularExercise.thumbnailUrl ?? popularExercise.demoImageUrl,
      demoImageUrl: popularExercise.demoImageUrl,
      demoVideoUrl: popularExercise.demoVideoUrl,
      keyPoints: popularExercise.keyPoints.isNotEmpty
          ? popularExercise.keyPoints
          : [
              'Maintain proper posture throughout the exercise',
              'Breathe evenly and avoid holding your breath',
              'Focus on form rather than speed',
              'Progress gradually and listen to your body',
            ],
      safetyWarnings: popularExercise.safetyWarnings.isNotEmpty
          ? popularExercise.safetyWarnings
          : [
              'Stop immediately if you feel any discomfort or pain',
              'Protect your joints by avoiding hyperextension',
              'Avoid overtraining - rest is important for recovery',
              'Warm up properly before starting the exercise',
            ],
      benefits: popularExercise.benefits,
      tags: parsedTags,
    );

    // Navigate to ModernWorkoutResultPage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModernWorkoutResultPage(
          exercise: exercise,
          exercises: [exercise],
          currentExerciseIndex: 0,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/popular_exercise_dto.dart';
import '../../../core/models/exercise.dart';
import '../../../core/models/target_muscle.dart';
import '../../../core/models/workout_intent.dart';
import '../../../core/services/popular_exercises_service.dart';
import '../../workout_result/screens/modern_workout_result_page.dart';
// import '../../workout_execution/screens/modern_workout_page_fixed.dart';

class RecommendedExercisesPage extends StatefulWidget {
  // 不再需要userId参数，因为这是通用推荐
  const RecommendedExercisesPage({super.key});

  @override
  State<RecommendedExercisesPage> createState() =>
      _RecommendedExercisesPageState();
}

class _RecommendedExercisesPageState extends State<RecommendedExercisesPage> {
  List<PopularExerciseDto> exercises = [];
  bool isLoading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadPopularExercises();
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _buildErrorState()
              : exercises.isEmpty
                  ? _buildEmptyState()
                  : _buildExerciseContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            error!,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadPopularExercises,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Stack(
      children: [
        // Background Image
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
              ),
            ),
          ),
        ),
        // Content
        SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.fitness_center_outlined,
                        size: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'No Training History',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Complete some workouts and your\nmost practiced exercises will appear here',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to home page to start training
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/home',
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start First Workout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF6C5CE7),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseContent() {
    return Stack(
      children: [
        // Background - Use gradient (no asset needed)
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
              ),
            ),
          ),
        ),
        // Dark overlay
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.4),
          ),
        ),
        // Content
        SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: _buildExerciseList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommended Exercises',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Based on your training history',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
        ),
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final exercise = exercises[index];
          return _buildExerciseCard(exercise);
        },
      ),
    );
  }

  Widget _buildExerciseCard(PopularExerciseDto exercise) {
    return GestureDetector(
      onTap: () => _navigateToExercise(exercise),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  color: Colors.grey,
                ),
                child: exercise.demoImageUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        child: CachedNetworkImage(
                          imageUrl: exercise.demoImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(
                                Icons.fitness_center,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.fitness_center,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      ),
              ),
            ),
            // Exercise info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // 改为 min，让 Column 只占用所需空间
                  children: [
                    // Exercise name
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Muscle group and difficulty
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C5CE7).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              exercise.muscleDisplayName,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF6C5CE7),
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Training count
                    Row(
                      children: [
                        const Icon(
                          Icons.repeat,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          exercise.popularityText,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToExercise(PopularExerciseDto popularExercise) {
    debugPrint(
        '📍 Navigating to reference workout page for: ${popularExercise.name} (ID: ${popularExercise.id})');

    // Convert PopularExerciseDto to Exercise object using REAL DATA from backend
    // Parse primaryMuscle and intentType
    TargetMuscle primaryMuscle;
    try {
      primaryMuscle = TargetMuscle.values.firstWhere(
        (m) => m.name.toLowerCase() == popularExercise.primaryMuscle.toLowerCase() ||
               m.code.toLowerCase() == popularExercise.primaryMuscle.toLowerCase(),
        orElse: () => TargetMuscle.fullBody,
      );
    } catch (e) {
      primaryMuscle = TargetMuscle.fullBody;
    }

    WorkoutIntent intentType;
    try {
      // intentType 现在是 List<String>，取第一个元素
      final firstIntent = popularExercise.intentType.isNotEmpty
          ? popularExercise.intentType.first
          : 'STRETCH';

      intentType = WorkoutIntent.values.firstWhere(
        (i) => i.name.toLowerCase() == firstIntent.toLowerCase() ||
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

    // Parse tags
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
      repetitions: popularExercise.sets * 10, // Estimate based on sets
      thumbnailUrl: popularExercise.thumbnailUrl ?? popularExercise.demoImageUrl,
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

    // Navigate to ModernWorkoutResultPage with real exercise data
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

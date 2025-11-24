import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/workout_session.dart';
import '../../../core/models/exercise.dart';
import '../../../core/models/target_muscle.dart';
import '../../../core/models/workout_intent.dart';
import '../../../core/providers/workout_execution_provider.dart';
import '../../../core/providers/workout_result_provider.dart';
import '../../workout_execution/screens/workout_execution_page.dart';

/// 动作结果页 - 显示推荐的动作
/// 对应 HTML: 05-workout-result.html
class WorkoutResultPage extends StatefulWidget {
  final Map<String, dynamic>? recommendationParams;

  const WorkoutResultPage({
    super.key,
    this.recommendationParams,
  });

  @override
  State<WorkoutResultPage> createState() => _WorkoutResultPageState();
}

class _WorkoutResultPageState extends State<WorkoutResultPage> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<WorkoutResultProvider>(context, listen: false);

      // Get arguments from route
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final recommendationParams = args?['recommendationParams'] as Map<String, dynamic>?;
      final sessionId = args?['sessionId'] as String?;

      provider.initializeRecommendation(
        recommendationParams: widget.recommendationParams ?? recommendationParams,
        sessionId: sessionId,
      );
    });
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutResultProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading workout recommendation...'),
                ],
              ),
            ),
          );
        }

        if (provider.error != null) {
          return Scaffold(
            appBar: AppBar(title: Text('Workout Result')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error: ${provider.error}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        if (!provider.hasExercises) {
          return Scaffold(
            appBar: AppBar(title: Text('Workout Result')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No exercises available'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Hero Section with Background
              _buildHeroSection(provider),

              // Content Section
              SliverToBoxAdapter(
                child: _buildContentSection(provider),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建Hero区域
  Widget _buildHeroSection(WorkoutResultProvider provider) {
    final session = provider.currentSession;
    final exercises = provider.exercises;
    final plannedMinutes = session != null
        ? (session.plannedDurationSec / 60).round()
        : (exercises.length * 1); // Fallback: 1 min per exercise

    return SliverAppBar(
      expandedHeight: 400,
      pinned: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
              ],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 80),

                // Workout Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _getWorkoutTitle(provider),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 40),

                // Stats
                _buildWorkoutStats(plannedMinutes, session?.estimatedCalories ?? 100),

                const SizedBox(height: 40),

                // Start Button
                _buildStartWorkoutButton(provider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 获取训练标题
  String _getWorkoutTitle(WorkoutResultProvider provider) {
    final session = provider.currentSession;
    final exercises = provider.exercises;

    if (session != null) {
      final intent = session.intent;
      final muscleNames = session.targetMuscles
          .map((m) => m.displayName)
          .join(' & ');
      return '${intent.displayName} Training\n$muscleNames';
    } else {
      // Fallback when no session available
      return 'Workout Recommendation\n${exercises.length} Exercises';
    }
  }

  /// 构建训练数据统计
  Widget _buildWorkoutStats(int minutes, int calories) {
    // Get difficulty from provider context
    final difficulty = context.read<WorkoutResultProvider>().currentSession?.overallDifficulty.displayName ?? 'Beginner';

    return Container(
      width: 280,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('📊', 'Level', difficulty),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          _buildStatItem('⏱', 'Time', '$minutes min'),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          _buildStatItem('🔥', 'Calories', '$calories kcal'),
        ],
      ),
    );
  }

  /// 构建单个统计项
  Widget _buildStatItem(String icon, String label, String value) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  /// 构建开始训练按钮
  Widget _buildStartWorkoutButton(WorkoutResultProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _startWorkoutExecution(provider),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD700),
          foregroundColor: Colors.black,
          elevation: 8,
          shadowColor: const Color(0xFFFFD700).withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow, size: 20),
            SizedBox(width: 8),
            Text(
              'Start Workout',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 开始训练执行
  void _startWorkoutExecution(WorkoutResultProvider provider) {
    final session = provider.currentSession;
    final exercises = provider.exercises;

    if (exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No exercises to start workout')),
      );
      return;
    }

    debugPrint('🚀 Starting workout with ${exercises.length} exercises');

    // Create a workout session if one doesn't exist
    final workoutSession = session ?? _createFallbackSession(exercises);

    // 导航到训练执行页面
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => WorkoutExecutionProvider(),
          child: WorkoutExecutionPage(
            workoutSession: workoutSession,
          ),
        ),
      ),
    );
  }

  /// 创建后备训练会话
  WorkoutSession _createFallbackSession(List<Exercise> exercises) {
    return WorkoutSession(
      id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'fallback_user',
      status: WorkoutSessionStatus.pending,
      intent: WorkoutIntent.stretch, // Default intent
      scenarioCode: 'home',
      equipmentCodes: ['hands_free'],
      targetMuscles: [TargetMuscle.fullBody],
      exercises: exercises,
      plannedDurationSec: exercises.length * 60,
      estimatedCalories: exercises.fold<int>(0, (sum, e) => sum + (e.durationSeconds ~/ 6)),
      createdAt: DateTime.now(),
    );
  }

  /// 构建内容区域
  Widget _buildContentSection(WorkoutResultProvider provider) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tags
                _buildTagsSection(provider),

                const SizedBox(height: 24),

                // Description
                _buildDescriptionSection(provider),

                const SizedBox(height: 32),

                // Target Area
                _buildTargetAreaSection(provider),

                const SizedBox(height: 32),

                // Exercise List
                _buildExerciseListSection(provider),

                const SizedBox(height: 32),

                // Recommended Workouts
                _buildRecommendedWorkoutsSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建标签区域
  Widget _buildTagsSection(WorkoutResultProvider provider) {
    final session = provider.currentSession;
    final exercises = provider.exercises;

    List<String> tags = [];

    if (session != null) {
      tags = [
        session.intent.displayName,
        session.overallDifficulty.displayName,
        session.scenarioDisplayName,
      ];
    } else {
      // Fallback tags when no session
      tags = [
        'Custom Workout',
        'Beginner',
        '${exercises.length} Exercises',
      ];
    }

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: tags.map((tag) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          tag,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFFF57C00),
          ),
        ),
      )).toList(),
    );
  }

  /// 构建描述区域
  Widget _buildDescriptionSection(WorkoutResultProvider provider) {
    return Text(
      _getWorkoutDescription(provider),
      style: TextStyle(
        fontSize: 16,
        color: Colors.grey.shade600,
        height: 1.6,
      ),
    );
  }

  /// 获取训练描述
  String _getWorkoutDescription(WorkoutResultProvider provider) {
    final session = provider.currentSession;
    final exercises = provider.exercises;

    if (session != null) {
      return 'This ${session.overallDifficulty.displayName.toLowerCase()}-level '
             '${session.intent.displayName.toLowerCase()} program helps you strengthen your '
             '${session.primaryMuscleDescription.toLowerCase()} using ${session.equipmentDisplayNames.toLowerCase()}.'
             ' Perfect for ${session.scenarioDisplayName.toLowerCase()} training.';
    } else {
      // Fallback description when no session
      return 'This custom workout includes ${exercises.length} carefully selected exercises '
             'to help you achieve your fitness goals. Perfect for any fitness level.';
    }
  }

  /// 构建目标区域部分
  Widget _buildTargetAreaSection(WorkoutResultProvider provider) {
    final session = provider.currentSession;
    final exercises = provider.exercises;

    String targetDescription;
    if (session != null) {
      targetDescription = session.primaryMuscleDescription;
    } else {
      // Fallback based on exercises
      final muscleGroups = exercises.map((e) => e.primaryMuscle.displayName).toSet();
      targetDescription = muscleGroups.length <= 2
          ? muscleGroups.join(' & ')
          : 'Multiple Muscle Groups';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Target Area'),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.fitness_center,
                size: 24,
                color: Color(0xFF667eea),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                targetDescription,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建动作列表部分
  Widget _buildExerciseListSection(WorkoutResultProvider provider) {
    final exercises = provider.exercises;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Exercises (${exercises.length})'),
        const SizedBox(height: 16),
        ...exercises.asMap().entries.map((entry) {
          final index = entry.key;
          final exercise = entry.value;
          return _buildExerciseListItem(exercise, index + 1);
        }).toList(),
      ],
    );
  }

  /// 构建动作列表项
  Widget _buildExerciseListItem(Exercise exercise, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Index
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFFFD700),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Exercise Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${exercise.durationSeconds}s',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Color(int.parse(exercise.difficulty.color.substring(1), radix: 16) + 0xFF000000).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        exercise.difficulty.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(int.parse(exercise.difficulty.color.substring(1), radix: 16) + 0xFF000000),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Calories badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${exercise.durationSeconds ~/ 6} kcal',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF57C00),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建推荐训练部分
  Widget _buildRecommendedWorkoutsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('You May Like'),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: 8),
            itemCount: _getRecommendedWorkouts().length,
            itemBuilder: (context, index) {
              final workout = _getRecommendedWorkouts()[index];
              return Container(
                width: 160,
                margin: EdgeInsets.only(
                  right: index < _getRecommendedWorkouts().length - 1 ? 16 : 0,
                ),
                child: _buildRecommendationCard(workout),
              );
            },
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  /// 构建推荐卡片
  Widget _buildRecommendationCard(Map<String, dynamic> workout) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: workout['gradient'] as List<Color>,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout['title'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${workout['duration']} min',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${workout['calories']} kcal',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 获取推荐训练列表
  List<Map<String, dynamic>> _getRecommendedWorkouts() {
    return [
      {
        'title': 'Back Strength',
        'duration': 26,
        'calories': 164,
        'gradient': [const Color(0xFF667eea), const Color(0xFF764ba2)],
      },
      {
        'title': 'Core Beginner',
        'duration': 22,
        'calories': 116,
        'gradient': [const Color(0xFFf093fb), const Color(0xFFf5576c)],
      },
      {
        'title': 'Beginner Core',
        'duration': 16,
        'calories': 84,
        'gradient': [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
      },
      {
        'title': 'Full Body Burn',
        'duration': 30,
        'calories': 200,
        'gradient': [const Color(0xFFfd79a8), const Color(0xFFfdcb6e)],
      },
      {
        'title': 'Neck & Shoulders',
        'duration': 15,
        'calories': 95,
        'gradient': [const Color(0xFF6c5ce7), const Color(0xFFa29bfe)],
      },
    ];
  }

  /// 构建节标题
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
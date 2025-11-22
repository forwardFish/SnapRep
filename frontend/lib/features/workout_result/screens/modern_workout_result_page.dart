import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/widgets/bottom_navigation_bar.dart';
import '../../../routes/app_routes.dart';
import '../../../core/models/exercise.dart';
import '../../../core/models/target_muscle.dart';
import '../../../core/models/workout_intent.dart';
import '../../../core/services/exercise_service.dart';
import '../../workout_execution/screens/professional_workout_video_page_v2.dart';

/// Modern Workout Result Page - Based on Design Document Section 3.2
/// Displays 3 workout cards with professional UI design
/// Features: Info bar, workout cards, preview strip, action buttons
class ModernWorkoutResultPage extends StatefulWidget {
  final Map<String, dynamic>? recommendationParams;

  const ModernWorkoutResultPage({
    super.key,
    this.recommendationParams,
  });

  @override
  State<ModernWorkoutResultPage> createState() => _ModernWorkoutResultPageState();
}

class _ModernWorkoutResultPageState extends State<ModernWorkoutResultPage>
    with TickerProviderStateMixin {
  int _currentNavIndex = 0; // Home section
  bool _isLoading = false;
  String? _error;
  late AnimationController _cardController;
  late AnimationController _previewController;
  late Animation<double> _cardAnimation;
  late Animation<Offset> _cardSlideAnimation;

  final ExerciseService _exerciseService = ExerciseService();

  // Data loaded from API
  List<WorkoutCard> _workoutCards = [];
  List<WorkoutCard> _alternativeCards = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadWorkoutData();
  }

  void _setupAnimations() {
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _previewController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutCubic,
    );

    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutCubic,
    ));

    _cardController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      _previewController.forward();
    });
  }

  @override
  void dispose() {
    _cardController.dispose();
    _previewController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkoutData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Extract parameters from widget.recommendationParams or use defaults
      final params = widget.recommendationParams ?? {};

      final intent = _parseIntent(params['intent'] ?? 'STRETCH');
      // Support both 'equipment' and 'equipmentCodes' keys for compatibility
      final equipmentCodes = _parseEquipmentCodes(
        params['equipmentCodes'] ?? params['equipment'] ?? ['chair', 'wall']
      );
      final scenarioCode = params['scenarioCode'] ?? params['scenario'] ?? 'office';
      final targetMuscles = _parseTargetMuscles(params['targetMuscles']);

      debugPrint('🎯 Loading workout recommendations: intent=$intent, equipment=$equipmentCodes, scenario=$scenarioCode');

      // Get recommendations from API
      final recommendationData = await _exerciseService.getQuickRecommendation(
        intent: intent,
        equipmentCodes: equipmentCodes,
        scenarioCode: scenarioCode,
        targetMuscles: targetMuscles,
        difficultyLevel: params['difficultyLevel'],
        maxDuration: params['maxDuration'],
      );

      // Convert API response to WorkoutCard objects
      final exercises = recommendationData['exercises'] as List<dynamic>? ?? [];
      _workoutCards = exercises.take(3).map((exercise) => _convertToWorkoutCard(exercise, false)).toList();

      // Load alternative exercises if needed
      if (_workoutCards.isNotEmpty) {
        try {
          final alternatives = await _exerciseService.getExercisesByContext(
            equipmentCodes: equipmentCodes,
            scenarioCode: scenarioCode,
            intent: intent,
            targetMuscles: targetMuscles,
            pageSize: 6,
          );

          _alternativeCards = alternatives
              .where((ex) => !_workoutCards.any((card) => card.id == ex.id))
              .take(3)
              .map((exercise) => _convertExerciseToWorkoutCard(exercise, true))
              .toList();
        } catch (e) {
          debugPrint('⚠️ Failed to load alternatives: $e');
          _alternativeCards = [];
        }
      }

      debugPrint('✅ Workout data loaded: ${_workoutCards.length} main exercises, ${_alternativeCards.length} alternatives');
    } catch (e) {
      debugPrint('❌ Failed to load workout data: $e');
      setState(() {
        _error = 'Failed to load workout recommendations: $e';
      });

      // Use fallback data if API fails
      _setFallbackWorkoutData();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  WorkoutIntent _parseIntent(dynamic intentValue) {
    if (intentValue is WorkoutIntent) return intentValue;
    final intentStr = intentValue.toString().toUpperCase();
    return WorkoutIntent.values.firstWhere(
      (e) => e.name.toUpperCase() == intentStr,
      orElse: () => WorkoutIntent.stretch,
    );
  }

  List<String> _parseEquipmentCodes(dynamic equipmentValue) {
    if (equipmentValue is List<String>) return equipmentValue;
    if (equipmentValue is List) return equipmentValue.map((e) => e.toString()).toList();
    if (equipmentValue is String) return [equipmentValue];
    return ['chair', 'wall']; // Default fallback
  }

  List<TargetMuscle>? _parseTargetMuscles(dynamic muscleValue) {
    if (muscleValue == null) return null;
    if (muscleValue is List<TargetMuscle>) return muscleValue;
    if (muscleValue is List) {
      return muscleValue
          .map((m) => TargetMuscle.values.firstWhere(
                (tm) => tm.name.toUpperCase() == m.toString().toUpperCase(),
                orElse: () => TargetMuscle.fullBody,
              ))
          .toList();
    }
    return null;
  }

  WorkoutCard _convertToWorkoutCard(dynamic exercise, bool isReplacement) {
    return WorkoutCard(
      id: exercise['id']?.toString() ?? '',
      name: exercise['name']?.toString() ?? 'Exercise',
      difficulty: _parseDifficulty(exercise['difficulty']),
      duration: exercise['duration'] ?? 30,
      sets: exercise['sets'] ?? 1,
      tags: _parseTags(exercise),
      benefits: exercise['benefits']?.toString() ?? '',
      safetyTips: _parseSafetyTips(exercise),
      previewImage: exercise['thumbnailUrl'] ?? 'assets/exercises/default.jpg',
      isReplacement: isReplacement,
    );
  }

  WorkoutCard _convertExerciseToWorkoutCard(Exercise exercise, bool isReplacement) {
    return WorkoutCard(
      id: exercise.id,
      name: exercise.name,
      difficulty: _exerciseDifficultyToLevel(exercise.difficulty),
      duration: exercise.durationSeconds,
      sets: exercise.sets,
      tags: _exerciseToTags(exercise),
      benefits: exercise.benefits,
      safetyTips: exercise.safetyWarnings,
      previewImage: exercise.thumbnailUrl ?? 'assets/exercises/default.jpg',
      isReplacement: isReplacement,
    );
  }

  DifficultyLevel _parseDifficulty(dynamic difficulty) {
    if (difficulty == null) return DifficultyLevel.easy;
    final diffStr = difficulty.toString().toLowerCase();
    if (diffStr.contains('hard') || diffStr.contains('advanced')) return DifficultyLevel.hard;
    if (diffStr.contains('medium') || diffStr.contains('intermediate')) return DifficultyLevel.medium;
    return DifficultyLevel.easy;
  }

  DifficultyLevel _exerciseDifficultyToLevel(ExerciseDifficulty difficulty) {
    switch (difficulty) {
      case ExerciseDifficulty.beginner:
        return DifficultyLevel.easy;
      case ExerciseDifficulty.intermediate:
        return DifficultyLevel.medium;
      case ExerciseDifficulty.advanced:
      case ExerciseDifficulty.expert:
        return DifficultyLevel.hard;
    }
  }

  List<String> _parseTags(dynamic exercise) {
    final tags = <String>[];

    if (exercise['primaryMuscle'] != null) {
      tags.add(exercise['primaryMuscle'].toString());
    }

    if (exercise['intentType'] != null) {
      tags.add(exercise['intentType'].toString());
    }

    if (exercise['tags'] != null && exercise['tags'] is List) {
      tags.addAll((exercise['tags'] as List).map((t) => t.toString()));
    }

    return tags.isNotEmpty ? tags : ['General'];
  }

  List<String> _exerciseToTags(Exercise exercise) {
    final tags = <String>[exercise.primaryMuscle.name];
    if (exercise.secondaryMuscles.isNotEmpty) {
      tags.addAll(exercise.secondaryMuscles.take(2).map((m) => m.name));
    }
    tags.add(exercise.intentType.name);
    return tags;
  }

  List<String> _parseSafetyTips(dynamic exercise) {
    if (exercise['safetyWarnings'] != null && exercise['safetyWarnings'] is List) {
      return (exercise['safetyWarnings'] as List)
          .map((tip) => '⚠️ ${tip.toString()}')
          .toList();
    }

    if (exercise['keyPoints'] != null && exercise['keyPoints'] is List) {
      return (exercise['keyPoints'] as List)
          .take(2)
          .map((point) => '⚠️ ${point.toString()}')
          .toList();
    }

    return ['⚠️ Maintain proper form', '⚠️ Listen to your body'];
  }

  void _setFallbackWorkoutData() {
    debugPrint('⚠️ Using fallback workout data');
    _workoutCards = [
      WorkoutCard(
        id: 'fallback-1',
        name: 'Wall Chest Opener',
        difficulty: DifficultyLevel.easy,
        duration: 20,
        sets: 1,
        tags: ['Standing', 'Wall', 'Stretching'],
        benefits: 'Relieves neck tension\nOpens upper back',
        safetyTips: ['⚠️ Keep neck neutral', '⚠️ Shoulders down'],
        previewImage: 'assets/exercises/wall_chest_opener.jpg',
        isReplacement: false,
      ),
      WorkoutCard(
        id: 'fallback-2',
        name: 'Chair Sit-to-Stand',
        difficulty: DifficultyLevel.easy,
        duration: 30,
        sets: 1,
        tags: ['Chair', 'Lower Body'],
        benefits: 'Strengthens legs\nImproves mobility',
        safetyTips: ['⚠️ Control the movement', '⚠️ Keep feet flat'],
        previewImage: 'assets/exercises/chair_sit_stand.jpg',
        isReplacement: false,
      ),
    ];
    _alternativeCards = [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black),
            onPressed: _showSafetyInfo,
          ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : Column(
              children: [
                // Top Info Bar
                _buildInfoBar(),

                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Workout Cards (3 cards)
                        _buildWorkoutCards(),

                        const SizedBox(height: 32),

                        // Preview Strip
                        _buildPreviewStrip(),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // Bottom Action Bar
                _buildBottomActionBar(),
              ],
            ),
      bottomNavigationBar: BottomNavigationBarWidget(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }

  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });

    switch (index) {
      case 0:
        // Already on home section
        break;
      case 1:
        // Navigate to camera page
        debugPrint('Navigate to camera page');
        break;
      case 2:
        // Navigate to profile page
        Navigator.pushNamed(context, AppRoutes.myPage);
        break;
    }
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
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
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
            'Generating Your Workout',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Finding perfect exercises for you...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Top Info Bar - Shows equipment, scenario, duration, difficulty
  Widget _buildInfoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Equipment & Scenario
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.chair,
                    size: 20,
                    color: Color(0xFFFFD700),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chair · Office',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    Text(
                      'Equipment',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Duration & Mode
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  '60s · Stretch',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                Text(
                  'Duration',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Difficulty & Silent Mode
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Easy',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.volume_off,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
                Text(
                  'Level',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Workout Cards - 3 cards in vertical layout
  Widget _buildWorkoutCards() {
    return FadeTransition(
      opacity: _cardAnimation,
      child: SlideTransition(
        position: _cardSlideAnimation,
        child: Column(
          children: _workoutCards.asMap().entries.map((entry) {
            final index = entry.key;
            final card = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: _buildWorkoutCard(card, index),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(WorkoutCard card, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildDifficultyBadge(card.difficulty),
                          const SizedBox(width: 8),
                          Text(
                            '${card.duration}s × ${card.sets}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (value) => _handleCardAction(value, card, index),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'replace',
                      child: Row(
                        children: [
                          Icon(Icons.swap_horiz, size: 20),
                          SizedBox(width: 12),
                          Text('Replace Card'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'easier',
                      child: Row(
                        children: [
                          Icon(Icons.trending_down, size: 20),
                          SizedBox(width: 12),
                          Text('Make Easier'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Exercise Preview (Placeholder)
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey[200]!,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_circle_filled,
                      size: 32,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '20s Preview Animation',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  Text(
                    'Tap to view full demonstration',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Tags
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: card.tags.map((tag) => _buildTag(tag)).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Benefits
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Benefits',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  card.benefits,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Safety Tips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Safety Guidelines',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                ...card.safetyTips.map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        tip,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFE74C3C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDifficultyBadge(DifficultyLevel difficulty) {
    Color color;
    String text;

    switch (difficulty) {
      case DifficultyLevel.easy:
        color = Colors.green;
        text = 'Easy';
        break;
      case DifficultyLevel.medium:
        color = Colors.blue;
        text = 'Medium';
        break;
      case DifficultyLevel.hard:
        color = Colors.red;
        text = 'Hard';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
        ),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2C3E50),
        ),
      ),
    );
  }

  /// Preview Strip - Horizontal scrollable alternatives
  Widget _buildPreviewStrip() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'More Options (Same Conditions)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),

        const SizedBox(height: 16),

        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: _alternativeCards.length,
            itemBuilder: (context, index) {
              final card = _alternativeCards[index];
              return Container(
                width: 100,
                margin: EdgeInsets.only(
                  right: index < _alternativeCards.length - 1 ? 16 : 0,
                ),
                child: GestureDetector(
                  onTap: () => _showReplaceBottomSheet(card),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Preview thumbnail
                        Container(
                          height: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.fitness_center,
                              size: 24,
                              color: Color(0xFFFFD700),
                            ),
                          ),
                        ),

                        // Card info
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  card.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2C3E50),
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  card.benefits.split('\n')[0],
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Bottom Action Bar - Start Practice & Refresh buttons
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Start Practice Button (Primary)
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _startWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Start Practice',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Refresh Button (Secondary)
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: _refreshWorkout,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2C3E50),
                side: const BorderSide(
                  color: Color(0xFFE1E5E9),
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh, size: 20),
                  SizedBox(width: 4),
                  Text(
                    'New Set',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleCardAction(String action, WorkoutCard card, int index) {
    HapticFeedback.lightImpact();

    switch (action) {
      case 'replace':
        _showReplaceBottomSheet(card);
        break;
      case 'easier':
        _makeExerciseEasier(card, index);
        break;
    }
  }

  void _showReplaceBottomSheet(WorkoutCard card) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const Text(
                    'Replace Exercise',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Filter summary
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Stretch · Office · Chair · Chest & Back',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6C757D),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Alternative exercises list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _alternativeCards.length,
                itemBuilder: (context, index) {
                  final altCard = _alternativeCards[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[200]!,
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          color: Color(0xFFFFD700),
                        ),
                      ),
                      title: Text(
                        altCard.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(altCard.benefits.split('\n')[0]),
                      trailing: _buildDifficultyBadge(altCard.difficulty),
                      onTap: () {
                        Navigator.pop(context);
                        _replaceCard(card, altCard);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _replaceCard(WorkoutCard oldCard, WorkoutCard newCard) {
    setState(() {
      final index = _workoutCards.indexWhere((c) => c.id == oldCard.id);
      if (index != -1) {
        _workoutCards[index] = newCard;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Replaced with ${newCard.name}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _makeExerciseEasier(WorkoutCard card, int index) {
    // Implementation for making exercise easier
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Finding easier alternative...'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _startWorkout() {
    HapticFeedback.lightImpact();

    // Convert workout cards to Exercise objects
    final exercises = _workoutCards.map((card) => Exercise(
      id: card.id,
      code: card.name.toLowerCase().replaceAll(' ', '_'),
      name: card.name,
      description: card.benefits,
      primaryMuscle: TargetMuscle.core, // Default to core
      secondaryMuscles: [], // Empty secondary muscles
      intentType: WorkoutIntent.stretch, // Default to stretch
      difficulty: ExerciseDifficulty.beginner, // Convert from card.difficulty if needed
      durationSeconds: card.duration,
      sets: card.sets,
      keyPoints: [], // Add key points if available
      safetyWarnings: card.safetyTips,
      benefits: card.benefits,
      tags: card.tags.map((tag) => ExerciseTag.fromCode(tag)).toList(),
      demoVideoUrl: 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
    )).toList();

    // Navigate to professional workout video page (Windows compatible version)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfessionalWorkoutVideoPageV2(
          exercise: exercises.first,
          exercises: exercises,
          currentExerciseIndex: 0,
        ),
      ),
    );
  }

  void _refreshWorkout() {
    HapticFeedback.lightImpact();

    // Reload with new exercises
    setState(() {
      _isLoading = true;
    });

    _loadWorkoutData().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New workout set generated!'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _showSafetyInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Safety Information'),
        content: const Text(
          'Stop immediately if you feel any discomfort. '
          'Choose "Make Easier" if you have any previous injuries. '
          'This app provides fitness guidance only, not medical advice.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

// Data Models
class WorkoutCard {
  final String id;
  final String name;
  final DifficultyLevel difficulty;
  final int duration;
  final int sets;
  final List<String> tags;
  final String benefits;
  final List<String> safetyTips;
  final String previewImage;
  final bool isReplacement;

  WorkoutCard({
    required this.id,
    required this.name,
    required this.difficulty,
    required this.duration,
    required this.sets,
    required this.tags,
    required this.benefits,
    required this.safetyTips,
    required this.previewImage,
    this.isReplacement = false,
  });
}

enum DifficultyLevel {
  easy,
  medium,
  hard,
}
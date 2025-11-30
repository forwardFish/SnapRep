import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../routes/app_routes.dart';
import '../../../core/models/exercise.dart';
import '../../../core/models/target_muscle.dart';
import '../../../core/models/workout_intent.dart';
import '../../../core/services/exercise_service.dart';
import '../../../core/services/token_service.dart';
import '../../../core/services/subscription_service.dart';
import '../../subscription/widgets/subscription_paywall_dialog.dart';
import '../../workout_execution/screens/professional_workout_video_page_v2.dart';
import '../../workout_execution/screens/improved_workout_video_page.dart';

/// Modern Workout Result Page - Based on Design Document Section 3.2
/// Displays workout cards with professional UI design matching xunlian-2.jpg
/// Supports both API-based loading (recommendationParams) and direct exercise passing
/// Features: Background image, exercise cards, detailed info (Benefits, Key Points, Safety Tips)
class ModernWorkoutResultPage extends StatefulWidget {
  final Map<String, dynamic>? recommendationParams;
  final Exercise? exercise;
  final List<Exercise>? exercises;
  final int currentExerciseIndex;

  const ModernWorkoutResultPage({
    super.key,
    this.recommendationParams,
    this.exercise,
    this.exercises,
    this.currentExerciseIndex = 0,
  });

  @override
  State<ModernWorkoutResultPage> createState() =>
      _ModernWorkoutResultPageState();
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
      // Method 1: Direct exercises passed (from ReferenceWorkoutPage pattern)
      if (widget.exercises != null && widget.exercises!.isNotEmpty) {
        _workoutCards = widget.exercises!
            .map((ex) => _convertExerciseToWorkoutCard(ex, false))
            .toList();
        _selectedExerciseIndex = widget.currentExerciseIndex;
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Method 2: Single exercise passed
      if (widget.exercise != null) {
        _workoutCards = [
          _convertExerciseToWorkoutCard(widget.exercise!, false)
        ];
        _selectedExerciseIndex = 0;
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Method 3: Load from API using recommendationParams
      final params = widget.recommendationParams ?? {};

      final intent = _parseIntent(params['intent'] ?? 'STRETCH');
      // Support both 'equipment' and 'equipmentCodes' keys for compatibility
      final equipmentCodes = _parseEquipmentCodes(
          params['equipmentCodes'] ?? params['equipment'] ?? ['chair', 'wall']);
      final scenarioCode =
          params['scenarioCode'] ?? params['scenario'] ?? 'office';
      final targetMuscles = _parseTargetMuscles(params['targetMuscles']);

      debugPrint(
          '🎯 Loading workout recommendations: intent=$intent, equipment=$equipmentCodes, scenario=$scenarioCode');

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
      _workoutCards = exercises
          .take(3)
          .map((exercise) => _convertToWorkoutCard(exercise, false))
          .toList();

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

      debugPrint(
          '✅ Workout data loaded: ${_workoutCards.length} main exercises, ${_alternativeCards.length} alternatives');
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
    if (equipmentValue is List)
      return equipmentValue.map((e) => e.toString()).toList();
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

  WorkoutCard _convertExerciseToWorkoutCard(
      Exercise exercise, bool isReplacement) {
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
      exercise: exercise, // 保存完整的 Exercise 对象
    );
  }

  DifficultyLevel _parseDifficulty(dynamic difficulty) {
    if (difficulty == null) return DifficultyLevel.easy;
    final diffStr = difficulty.toString().toLowerCase();
    if (diffStr.contains('hard') || diffStr.contains('advanced'))
      return DifficultyLevel.hard;
    if (diffStr.contains('medium') || diffStr.contains('intermediate'))
      return DifficultyLevel.medium;
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
    if (exercise['safetyWarnings'] != null &&
        exercise['safetyWarnings'] is List) {
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
              ),
              SizedBox(height: 16),
              Text(
                'Loading workout recommendations...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top White Navigation Bar (matching reference xunlian-2.jpg)
          _buildTopNavigation(),

          // Background Image Section with Exercise Cards
          Expanded(
            flex: 3,
            child: _buildBackgroundImageSection(),
          ),

          // Bottom White Details Section
          Expanded(
            flex: 4,
            child: _buildBottomDetailsSection(),
          ),
        ],
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

  int _selectedExerciseIndex = 0;

  void _selectExercise(int index) {
    setState(() {
      _selectedExerciseIndex = index;
    });
  }

  WorkoutCard get _selectedCard {
    if (_selectedExerciseIndex < _workoutCards.length) {
      return _workoutCards[_selectedExerciseIndex];
    }
    return _workoutCards.first;
  }

  /// Top navigation bar - clean white design matching xunlian-2.jpg
  Widget _buildTopNavigation() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 12,
      ),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button - simple arrow
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF1A1A1A),
                size: 20,
              ),
            ),
          ),

          // Title - bold center text
          Expanded(
            child: Text(
              _selectedCard.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Background image section - with real fitness background image
  Widget _buildBackgroundImageSection() {
    return Stack(
      children: [
        // Main Background Image - use actual exercise image with fallback to Unsplash
        Positioned.fill(
          child: Image.network(
            _selectedCard.previewImage.isNotEmpty &&
                    !_selectedCard.previewImage.contains('default')
                ? _selectedCard.previewImage
                : 'assets/images/backpack_workout.jpg',
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF6B7280), Color(0xFF374151)],
                  ),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Image.asset(
              'assets/images/backpack_workout.jpg',
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, trace) => Container(
                color: const Color(0xFF374151),
                child: const Center(
                  child: Icon(Icons.fitness_center,
                      color: Colors.white38, size: 48),
                ),
              ),
            ),
          ),
        ),

        // Subtle gradient overlay - for text readability
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.15),
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.55),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
        ),

        // Series badge
        Positioned(
          top: 20,
          left: 20,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.layers_outlined,
                color: Colors.white.withOpacity(0.9),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'From「Quick Fitness Series」',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.95),
                  shadows: const [
                    Shadow(
                        color: Colors.black38,
                        blurRadius: 4,
                        offset: Offset(0, 1)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Session info
        Positioned(
          top: 46,
          left: 20,
          child: Text(
            '${_workoutCards.length} Sessions · Current #${_selectedExerciseIndex + 1}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.85),
              shadows: const [
                Shadow(
                    color: Colors.black38, blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
          ),
        ),

        // Exercise Cards at bottom - with background images
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: _buildExerciseCards(),
        ),
      ],
    );
  }

  /// Exercise cards - frosted glass style matching xunlian-2.jpg exactly
  Widget _buildExerciseCards() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _workoutCards.length,
        itemBuilder: (context, index) {
          final card = _workoutCards[index];
          final isSelected = index == _selectedExerciseIndex;

          return GestureDetector(
            onTap: () => _selectExercise(index),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              width: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // Background Image
                    Positioned.fill(
                      child: Image.network(
                        card.previewImage.isNotEmpty &&
                                !card.previewImage.contains('default')
                            ? card.previewImage
                            : 'assets/images/outdoor_workout.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF6B7280),
                                const Color(0xFF374151),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Frosted glass overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          // Frosted glass effect - semi-transparent with blur simulation
                          color: isSelected
                              ? Colors.black.withOpacity(0.55)
                              : Colors.black.withOpacity(0.35),
                          border: isSelected
                              ? Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 1.5)
                              : Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                  width: 1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    // Content
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Exercise thumbnail - rounded rectangle like reference
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white.withOpacity(0.15),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  card.previewImage.isNotEmpty &&
                                          !card.previewImage.contains('default')
                                      ? card.previewImage
                                      : 'assets/images/outdoor_workout.jpg',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: Colors.white.withOpacity(0.1),
                                    child: const Icon(Icons.fitness_center,
                                        color: Colors.white54, size: 28),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Exercise info - matching reference format exactly
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Exercise number and name - "01 臀部强化" style
                                  Text(
                                    '${(index + 1).toString().padLeft(2, '0')} ${card.name}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      height: 1.2,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black54,
                                          offset: Offset(0, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),

                                  // Duration and calories - "12分钟 | 66千卡" style
                                  Text(
                                    '${card.duration ~/ 60}min | ${(card.duration * 0.055).toStringAsFixed(0)}cal',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white.withOpacity(0.9),
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black54,
                                          offset: Offset(0, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
    );
  }

  /// Bottom details section - matching xunlian-2.jpg style exactly
  Widget _buildBottomDetailsSection() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise name - bold title like reference
            Text(
              _selectedCard.name,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),

            // Tags - matching reference style exactly
            _buildTagsSection(),
            const SizedBox(height: 20),

            // Description/Benefits text
            Text(
              _selectedCard.benefits,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Color(0xFF666666),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            // Info cards - matching reference exactly (Level, Time, Calories)
            _buildInfoCards(),
            const SizedBox(height: 28),

            // Target muscles section with yellow accent bar like reference
            _buildTargetMusclesSection(),
            const SizedBox(height: 28),

            // Key Points Section
            if (_selectedCard.safetyTips.isNotEmpty) ...[
              _buildSectionWithAccent('Key Points'),
              const SizedBox(height: 12),
              ..._selectedCard.safetyTips
                  .take(3)
                  .toList()
                  .asMap()
                  .entries
                  .map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D2D2D),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.value.replaceAll('⚠️ ', ''),
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],

            // Safety Tips Section
            if (_selectedCard.safetyTips.isNotEmpty) ...[
              _buildSectionWithAccent('Safety Tips'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _selectedCard.safetyTips.map((warning) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFE5A000),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              warning.replaceAll('⚠️ ', ''),
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Color(0xFF5C5C5C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 28),
            ],

            // Start button - dark bg with golden text like reference
            _buildStartButton(),
          ],
        ),
      ),
    );
  }

  /// Section title with yellow accent bar like reference "练习部位"
  Widget _buildSectionWithAccent(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFFE5A000),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  /// Tags section - matching reference style exactly (first dark, others light orange)
  Widget _buildTagsSection() {
    final tags = _selectedCard.tags;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: tags.asMap().entries.map((entry) {
        final index = entry.key;
        final tag = entry.value;
        final isDark = index == 0; // First tag is dark like reference

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            tag,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : const Color(0xFFE07800),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Info cards (Level, Time, Calories) - Refined subtle design
  Widget _buildInfoCards() {
    return Row(
      children: [
        // Level card - Soft gold/amber tone
        Expanded(
          child: _buildInfoCard(
            icon: Icons.bar_chart_rounded,
            label: 'Level',
            value: _selectedCard.difficulty.name[0].toUpperCase() +
                _selectedCard.difficulty.name.substring(1),
            iconColor: const Color(0xFFD4A574),
            accentColor: const Color(0xFFD4A574),
            backgroundColor: const Color(0xFFFFFBF5),
          ),
        ),
        const SizedBox(width: 12),

        // Time card - Neutral dark gray
        Expanded(
          child: _buildInfoCard(
            icon: Icons.schedule_rounded,
            label: 'Time',
            value: '${_selectedCard.duration ~/ 60}',
            unit: 'min',
            iconColor: const Color(0xFF2D2D2D),
            accentColor: const Color(0xFF2D2D2D),
            backgroundColor: const Color(0xFFF8F8F8),
          ),
        ),
        const SizedBox(width: 12),

        // Calories card - Warm coral/rose tone
        Expanded(
          child: _buildInfoCard(
            icon: Icons.local_fire_department_rounded,
            label: 'Burn',
            value: '${(_selectedCard.duration * 0.055).toStringAsFixed(0)}',
            unit: 'cal',
            iconColor: const Color(0xFFE5A090),
            accentColor: const Color(0xFFE5A090),
            backgroundColor: const Color(0xFFFFF8F6),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color backgroundColor,
    required Color iconColor,
    required Color accentColor,
    String? unit,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon circle with accent color
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 10),

          // Label text
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 3),

          // Value with unit - fixed overflow
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 1),
                Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: accentColor.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Target muscles section - matching reference "练习部位" exactly
  Widget _buildTargetMusclesSection() {
    // 从当前选中的 Exercise 获取肌肉群信息
    final exercise = _selectedCard.exercise;
    if (exercise == null) {
      // 如果没有 Exercise 数据，不显示该部分
      return const SizedBox.shrink();
    }

    // 收集所有目标肌肉群（主要 + 次要）
    final List<TargetMuscle> targetMuscles = [
      exercise.primaryMuscle,
      ...exercise.secondaryMuscles,
    ];

    // 去重
    final uniqueMuscles = targetMuscles.toSet().toList();

    if (uniqueMuscles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionWithAccent('Target Muscles'),
        const SizedBox(height: 16),

        // 动态生成肌肉图标 - 从后端 Exercise 数据获取
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: uniqueMuscles.map((muscle) {
            return _buildMuscleIcon(
              _getMuscleIcon(muscle),
              muscle.displayName,
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 根据 TargetMuscle 返回对应的图标
  IconData _getMuscleIcon(TargetMuscle muscle) {
    switch (muscle) {
      case TargetMuscle.fullBody:
        return Icons.accessibility_new;
      case TargetMuscle.neckShoulder:
        return Icons.self_improvement;
      case TargetMuscle.chestBack:
        return Icons.fitness_center;
      case TargetMuscle.core:
        return Icons.circle_outlined;
      case TargetMuscle.legs:
        return Icons.directions_run;
      case TargetMuscle.glutes:
        return Icons.sports_gymnastics;
      case TargetMuscle.calves:
        return Icons.nordic_walking;
      case TargetMuscle.arms:
        return Icons.sports_kabaddi;
    }
  }

  Widget _buildMuscleIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 28, color: const Color(0xFF888888)),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Color(0xFF888888),
          ),
        ),
      ],
    );
  }

  /// Section title helper (kept for compatibility)
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A1A),
      ),
    );
  }

  /// Start button - matching reference "开练" exactly (dark bg + golden text)
  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _startWorkout,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D2D2D),
          foregroundColor: const Color(0xFFD4A574),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: const Text(
          'Start Workout',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
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

  void _startWorkout() async {
    HapticFeedback.lightImpact();

    // Step 1: 检查登录状态
    final isLoggedIn = await _checkLoginStatus();
    if (!isLoggedIn) return;

    // Step 2: 检查订阅状态和每日限制
    final canStart = await _checkSubscriptionAndUsage();
    if (!canStart) return;

    // Step 3: 允许开始训练
    _navigateToWorkoutVideo();
  }

  /// 检查登录状态
  Future<bool> _checkLoginStatus() async {
    final tokenService = TokenService.instance;
    final isLoggedIn = await tokenService.isLoggedIn();

    if (!isLoggedIn) {
      debugPrint('⚠️ User not logged in, navigating to login page...');

      // 跳转到登录页
      if (!mounted) return false;
      await Navigator.pushNamed(context, AppRoutes.googleLogin);

      // 检查用户是否成功登录
      final isNowLoggedIn = await tokenService.isLoggedIn();
      if (!isNowLoggedIn) {
        debugPrint('❌ User canceled login or login failed');
        return false;
      }

      debugPrint('✅ User logged in successfully');
      return true;
    }

    return true;
  }

  /// 检查订阅状态和每日使用限制
  Future<bool> _checkSubscriptionAndUsage() async {
    try {
      final subscriptionService = SubscriptionService();

      /* 恢复正常逻辑的步骤：
      当你测试完成后，只需要：
      删除 第 2048-2051 行的测试说明注释
      删除 第 2062-2081 行的测试代码
      取消注释 第 2054-2060 行和 2083-2088 行（正常逻辑） */

      // ============================================================
      // 🔧 测试模式: 临时注释每日限制检查，所有用户都显示付费弹窗
      // 用于测试付费订阅流程的 UI 和交互效果
      // ============================================================

      // TODO: 恢复正常逻辑时，取消下面的注释，并删除强制显示弹窗的代码
      /*
      // 正常逻辑: 检查是否可以开始训练 (付费用户/试用期用户/未达限制的免费用户可以开始)
      final canStart = await subscriptionService.canStartExercise();

      if (!canStart) {
        debugPrint('⚠️ User reached daily limit, showing subscription paywall...');
      */

      // 🧪 测试代码: 强制所有用户都显示付费弹窗
      debugPrint(
          '🧪 [TEST MODE] Forcing subscription paywall for all users...');

      // 显示付费弹窗
      if (!mounted) return false;
      final subscribed = await showSubscriptionPaywall(
        context,
        triggerSource: 'workout_start',
        onSubscribed: () {
          debugPrint('✅ User subscribed, can start workout now');
        },
      );

      // 如果用户订阅成功,再次检查权限
      if (subscribed == true) {
        final canStartNow = await subscriptionService.canStartExercise();
        return canStartNow;
      }

      return false;

      /*
      // 正常逻辑的结束
      }

      return true;
      */
    } catch (e) {
      debugPrint('❌ Error checking subscription: $e');

      // 出错时显示友好提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check subscription status: $e'),
            backgroundColor: const Color(0xFFE74C3C),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      return false;
    }
  }

  /// 导航到训练视频页面
  void _navigateToWorkoutVideo() {
    // Convert workout cards to Exercise objects
    final exercises = _workoutCards
        .map((card) => Exercise(
              id: card.id,
              code: card.name.toLowerCase().replaceAll(' ', '_'),
              name: card.name,
              description: card.benefits,
              primaryMuscle: TargetMuscle.core, // Default to core
              secondaryMuscles: [], // Empty secondary muscles
              intentType: WorkoutIntent.stretch, // Default to stretch
              difficulty: ExerciseDifficulty
                  .beginner, // Convert from card.difficulty if needed
              durationSeconds: card.duration,
              sets: card.sets,
              keyPoints: [], // Add key points if available
              safetyWarnings: card.safetyTips,
              benefits: card.benefits,
              tags: card.tags.map((tag) => ExerciseTag.fromCode(tag)).toList(),
              demoVideoUrl:
                  'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
            ))
        .toList();

    // Navigate to improved workout video page with thumbnail and click-to-play
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImprovedWorkoutVideoPage(
          exercise: exercises[_selectedExerciseIndex],
          exercises: exercises,
          currentExerciseIndex: _selectedExerciseIndex,
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
  final Exercise? exercise; // 添加完整的 Exercise 数据，用于访问肌肉群信息

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
    this.exercise, // 可选的 Exercise 对象
  });
}

enum DifficultyLevel {
  easy,
  medium,
  hard,
}

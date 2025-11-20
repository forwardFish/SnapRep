import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/exercise.dart';
import '../../../core/models/target_muscle.dart';

/// Modern Workout Page - Redesigned based on reference UI
/// Features: Hero background image, horizontal exercise cards, detailed info section
class ModernWorkoutPage extends StatefulWidget {
  final Exercise exercise;
  final List<Exercise> exercises;
  final int currentExerciseIndex;

  const ModernWorkoutPage({
    super.key,
    required this.exercise,
    required this.exercises,
    this.currentExerciseIndex = 0,
  });

  @override
  State<ModernWorkoutPage> createState() => _ModernWorkoutPageState();
}

class _ModernWorkoutPageState extends State<ModernWorkoutPage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  int _selectedExerciseIndex = 0;
  Exercise get _currentExercise => widget.exercises[_selectedExerciseIndex];

  // High-quality fitness background images from Unsplash
  final List<String> _backgroundImages = [
    'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&q=80', // Gym equipment
    'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80', // Running/cardio
    'https://images.unsplash.com/photo-1517963628607-235ccdd5476c?w=800&q=80', // Strength training
    'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=800&q=80', // Functional fitness
    'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&q=80', // Flexibility/yoga
  ];

  @override
  void initState() {
    super.initState();
    _selectedExerciseIndex = widget.currentExerciseIndex;
    _pageController = PageController();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutQuart,
    ));
    _slideController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _selectExercise(int index) {
    if (index != _selectedExerciseIndex) {
      setState(() {
        _selectedExerciseIndex = index;
      });
      _slideController.reset();
      _slideController.forward();
    }
  }

  String _getDifficultyText(ExerciseDifficulty difficulty) {
    switch (difficulty) {
      case ExerciseDifficulty.beginner:
        return 'Beginner';
      case ExerciseDifficulty.intermediate:
        return 'Intermediate';
      case ExerciseDifficulty.advanced:
        return 'Advanced';
      case ExerciseDifficulty.expert:
        return 'Expert';
    }
  }

  String _getMuscleGroupText(TargetMuscle muscle) {
    switch (muscle) {
      case TargetMuscle.chestBack:
        return 'Chest & Back';
      case TargetMuscle.neckShoulder:
        return 'Neck & Shoulders';
      case TargetMuscle.core:
        return 'Core';
      case TargetMuscle.legs:
        return 'Legs';
      case TargetMuscle.glutes:
        return 'Glutes';
      case TargetMuscle.calves:
        return 'Calves';
      case TargetMuscle.arms:
        return 'Arms';
      case TargetMuscle.fullBody:
        return 'Full Body';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Hero Background Image Section + Exercise Cards
          Stack(
            children: [
              // Hero Background Image Section
              _buildHeroSection(),

              // Exercise Cards Section (Overlay on hero)
              _buildExerciseCardsSection(),

              // Top Navigation Bar
              _buildTopNavigation(),
            ],
          ),

          // Bottom Details Section (Always visible)
          Expanded(
            child: _buildDetailsSection(),
          ),
        ],
      ),
    );
  }

  /// Hero background section with dramatic image and overlay
  Widget _buildHeroSection() {
    final backgroundImage = _backgroundImages[_selectedExerciseIndex % _backgroundImages.length];

    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          CachedNetworkImage(
            imageUrl: backgroundImage,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[900],
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[900],
              child: const Center(
                child: Icon(Icons.fitness_center,
                  color: Colors.white54, size: 64),
              ),
            ),
          ),

          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.9),
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
            ),
          ),

          // Hero Text Content
          Positioned(
            left: 24,
            bottom: 120,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Workout Series Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.layers_outlined, size: 16, color: Colors.black87),
                      const SizedBox(width: 6),
                      Text(
                        'From "Professional Fitness Training"',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Main Title
                Text(
                  _currentExercise.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  '${widget.exercises.length} exercises • Session ${_selectedExerciseIndex + 1}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Horizontal scrolling exercise cards section
  Widget _buildExerciseCardsSection() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.35,
      left: 0,
      right: 0,
      height: 120,
      child: Container(
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: widget.exercises.length,
          itemBuilder: (context, index) {
            final exercise = widget.exercises[index];
            final isSelected = index == _selectedExerciseIndex;

            return GestureDetector(
              onTap: () => _selectExercise(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 16),
                width: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.9),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                      blurRadius: isSelected ? 20 : 10,
                      spreadRadius: 0,
                      offset: Offset(0, isSelected ? 8 : 4),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Exercise Thumbnail
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: const Color(0xFF6366F1),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}'.padLeft(2, '0'),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              exercise.name.length > 20
                                ? '${exercise.name.substring(0, 20)}...'
                                : exercise.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.black87 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${exercise.durationSeconds ~/ 60}min • ${exercise.repetitions} reps',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.black54 : Colors.black38,
                              ),
                            ),
                          ],
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
    );
  }

  /// Bottom details section with exercise information
  Widget _buildDetailsSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle Bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 32),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Exercise Title
                Text(
                  _currentExercise.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // Muscle Group Tags
                Wrap(
                  spacing: 8,
                  children: [
                    _buildMuscleTag(_getMuscleGroupText(_currentExercise.primaryMuscle), true),
                    ..._currentExercise.secondaryMuscles.map(
                      (muscle) => _buildMuscleTag(_getMuscleGroupText(muscle), false),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Exercise Description
                Text(
                  _currentExercise.description,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black54,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 32),

                // Stats Cards
                _buildStatsSection(),

                const SizedBox(height: 32),

                // Target Muscles Section
                _buildTargetMusclesSection(),

                const SizedBox(height: 32),

                // Key Points Section
                _buildKeyPointsSection(),

                const SizedBox(height: 32),

                // Start Workout Button
                _buildStartWorkoutButton(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMuscleTag(String text, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary
          ? const Color(0xFF6366F1).withOpacity(0.1)
          : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPrimary
            ? const Color(0xFF6366F1).withOpacity(0.3)
            : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isPrimary ? const Color(0xFF6366F1) : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.signal_cellular_alt,
            label: 'Level',
            value: _getDifficultyText(_currentExercise.difficulty),
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.schedule,
            label: 'Duration',
            value: '${_currentExercise.durationSeconds ~/ 60}min',
            color: const Color(0xFF6366F1),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department,
            label: 'Calories',
            value: '${(_currentExercise.repetitions ?? 10) * 5}cal',
            color: const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetMusclesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Target Muscles',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        // Add muscle group icons here - simplified for now
        Container(
          height: 80,
          child: Row(
            children: [
              _buildMuscleIcon('💪', 'Arms'),
              const SizedBox(width: 16),
              _buildMuscleIcon('🦵', 'Legs'),
              const SizedBox(width: 16),
              _buildMuscleIcon('🫁', 'Core'),
              const SizedBox(width: 16),
              _buildMuscleIcon('🏃', 'Full Body'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMuscleIcon(String emoji, String label) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildKeyPointsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Points',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ..._currentExercise.keyPoints.map((point) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 6, right: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF6366F1),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  point,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildStartWorkoutButton() {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          // Navigate to actual workout execution
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ModernWorkoutPage(
                exercise: _currentExercise,
                exercises: widget.exercises,
                currentExerciseIndex: _selectedExerciseIndex,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'START WORKOUT',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildTopNavigation() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 24,
      right: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),

          // Favorite Button
          GestureDetector(
            onTap: () {
              // Add to favorites logic
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.favorite_border,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
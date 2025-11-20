import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/exercise.dart';
import '../../../core/models/target_muscle.dart';

/// Workout Page - Exactly matching reference UI design (xunlian-2.jpg)
class ReferenceWorkoutPage extends StatefulWidget {
  final Exercise exercise;
  final List<Exercise> exercises;
  final int currentExerciseIndex;

  const ReferenceWorkoutPage({
    super.key,
    required this.exercise,
    required this.exercises,
    this.currentExerciseIndex = 0,
  });

  @override
  State<ReferenceWorkoutPage> createState() => _ReferenceWorkoutPageState();
}

class _ReferenceWorkoutPageState extends State<ReferenceWorkoutPage> {
  int _selectedExerciseIndex = 0;
  Exercise get _currentExercise => widget.exercises[_selectedExerciseIndex];

  // Athletic background images matching reference style
  final List<String> _athleticBackgrounds = [
    'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80', // Athletic male body
    'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&q=80', // Fitness workout
    'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=800&q=80', // Strong athletic pose
    'https://images.unsplash.com/photo-1517963628607-235ccdd5476c?w=800&q=80', // Athletic training
    'https://images.unsplash.com/photo-1556817411-31ae72fa3ea0?w=800&q=80', // Muscle definition
  ];

  // Small exercise demo images for cards
  final List<String> _exerciseDemoImages = [
    'https://images.unsplash.com/photo-1566241440091-ec10de8db2e1?w=200&q=80', // Hip exercise demo
    'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=200&q=80', // Cardio demo
    'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=200&q=80', // Strength demo
    'https://images.unsplash.com/photo-1517963628607-235ccdd5476c?w=200&q=80', // Core demo
    'https://images.unsplash.com/photo-1556817411-31ae72fa3ea0?w=200&q=80', // Muscle demo
  ];

  @override
  void initState() {
    super.initState();
    _selectedExerciseIndex = widget.currentExerciseIndex;
  }

  void _selectExercise(int index) {
    if (index != _selectedExerciseIndex) {
      setState(() {
        _selectedExerciseIndex = index;
      });
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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top White Navigation Bar (matching reference)
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

  /// Top navigation bar with white background (exactly matching reference)
  Widget _buildTopNavigation() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 24,
        right: 24,
        bottom: 16,
      ),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black87,
              size: 24,
            ),
          ),

          // Title
          Text(
            _currentExercise.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          // Favorite Button
          GestureDetector(
            onTap: () {},
            child: const Icon(
              Icons.favorite_border,
              color: Colors.black87,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  /// Background image section with exercise cards overlay (matching reference)
  Widget _buildBackgroundImageSection() {
    final backgroundImage = _athleticBackgrounds[_selectedExerciseIndex % _athleticBackgrounds.length];

    return Stack(
      children: [
        // Main Background Image (athletic pose)
        Positioned.fill(
          child: CachedNetworkImage(
            imageUrl: backgroundImage,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.fitness_center, color: Colors.grey, size: 64),
            ),
          ),
        ),

        // Dark Gradient Overlay for text readability
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.4),
                ],
              ),
            ),
          ),
        ),

        // Top Left Series Badge (matching reference "来自 综合男性能力提升")
        Positioned(
          top: 24,
          left: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.layers_outlined, size: 16, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'From "Professional Fitness Training"',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Series Info (matching reference "共6节·当前课为第2节")
        Positioned(
          top: 64,
          left: 24,
          child: Text(
            '${widget.exercises.length} Sessions • Current Session ${_selectedExerciseIndex + 1}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ),

        // Exercise Cards positioned like reference (bottom of background area)
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: _buildExerciseCards(),
        ),
      ],
    );
  }

  /// Exercise cards exactly matching reference design
  Widget _buildExerciseCards() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.exercises.length,
        itemBuilder: (context, index) {
          final exercise = widget.exercises[index];
          final isSelected = index == _selectedExerciseIndex;
          final demoImage = _exerciseDemoImages[index % _exerciseDemoImages.length];

          return GestureDetector(
            onTap: () => _selectExercise(index),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black.withOpacity(isSelected ? 0.7 : 0.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Small exercise demo image (like reference)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: demoImage,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[400],
                          child: const Icon(Icons.fitness_center, color: Colors.white, size: 24),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[400],
                          child: const Icon(Icons.fitness_center, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Exercise info (matching reference format)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(index + 1).toString().padLeft(2, '0')} ${exercise.name}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${exercise.durationSeconds ~/ 60}min | ${(_currentExercise.repetitions ?? 10) * 5} cal',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.8),
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
    );
  }

  /// Bottom white details section (exactly matching reference)
  Widget _buildBottomDetailsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise Title
            Text(
              _currentExercise.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Category Tags (matching reference: 凯格尔、增肌塑形)
            Wrap(
              spacing: 8,
              children: [
                _buildCategoryTag(_getMuscleGroupText(_currentExercise.primaryMuscle), true),
                _buildCategoryTag('Muscle Building', false),
              ],
            ),

            const SizedBox(height: 24),

            // Description text
            Text(
              _currentExercise.description,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 32),

            // Stats Cards Row (matching reference: 等级、时间、消耗)
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.signal_cellular_alt,
                    label: 'Level',
                    value: _getDifficultyText(_currentExercise.difficulty),
                    backgroundColor: Colors.grey[100]!,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.schedule,
                    label: 'Duration',
                    value: '${_currentExercise.durationSeconds ~/ 60}min',
                    backgroundColor: Colors.grey[100]!,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.local_fire_department,
                    label: 'Calories',
                    value: '${(_currentExercise.repetitions ?? 10) * 5}cal',
                    backgroundColor: Colors.red[50]!,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Exercise Body Parts Section (matching reference: 练习部位)
            _buildBodyPartsSection(),

            const SizedBox(height: 32),

            // Start Exercise Button (matching reference: 开练)
            _buildStartButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTag(String text, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isPrimary ? Colors.black87 : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isPrimary ? Colors.white : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.black87, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyPartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Exercise Body Parts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        // Body part icons (simplified matching reference style)
        Row(
          children: [
            _buildBodyPartIcon('💪', 'Arms'),
            const SizedBox(width: 24),
            _buildBodyPartIcon('🦵', 'Legs'),
            const SizedBox(width: 24),
            _buildBodyPartIcon('🫁', 'Core'),
            const SizedBox(width: 24),
            _buildBodyPartIcon('🏃', 'Full Body'),
          ],
        ),
      ],
    );
  }

  Widget _buildBodyPartIcon(String emoji, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
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

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Starting ${_currentExercise.name} workout!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'START TRAINING',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
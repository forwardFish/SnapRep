import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/workout_guide_provider.dart';
import '../../../core/models/workout_intent.dart';
import '../../../routes/app_routes.dart';

/// Workout Mode Selection Page - Now Step 2
/// Previously step1, now moved to step2 after camera detection
class WorkoutModeSelectionPage extends StatefulWidget {
  final Map<String, dynamic>? guideData;

  const WorkoutModeSelectionPage({super.key, this.guideData});

  @override
  State<WorkoutModeSelectionPage> createState() => _WorkoutModeSelectionPageState();
}

class _WorkoutModeSelectionPageState extends State<WorkoutModeSelectionPage> {
  String? _selectedMode;
  String? _detectedScene;
  List<String> _detectedEquipment = [];

  @override
  void initState() {
    super.initState();

    // Get camera detection data
    if (widget.guideData != null) {
      _detectedScene = widget.guideData!['detectedScene'];
      _detectedEquipment = List<String>.from(widget.guideData!['detectedEquipment'] ?? []);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutGuideProvider>().initializeStep2(); // ✅ 修正：这现在是 Step 2
    });
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
        title: const Text(
          'Workout Guide',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Content area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress indicator
                  _buildProgressIndicator(),

                  const SizedBox(height: 20),

                  // Detection summary
                  if (_detectedScene != null) _buildDetectionSummary(),

                  const SizedBox(height: 24),

                  // Title section
                  _buildTitleSection(),

                  const SizedBox(height: 32),

                  // Content sections
                  Expanded(
                    child: _buildContentSection(),
                  ),
                ],
              ),
            ),
          ),

          // Bottom button area
          _buildBottomButtonArea(),
        ],
      ),
    );
  }

  /// Build progress indicator
  Widget _buildProgressIndicator() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: const Color(0xFFFFD700), // Step 1 completed
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: const Color(0xFFFFD700), // Step 2 current
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: const Color(0xFFE0E0E0), // Step 3 not completed yet
            ),
          ),
        ),
      ],
    );
  }

  /// Build detection summary
  Widget _buildDetectionSummary() {
    final sceneNames = {
      'home': 'Living Space',
      'gym': 'Fitness Center',
      'office': 'Workplace',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFFD700),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Environment Detected',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                Text(
                  sceneNames[_detectedScene] ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_detectedEquipment.length} items',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build title section
  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFFFD700),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '2',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'STEP 2',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Choose your\nworkout mode',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            height: 1.2,
            color: Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select your preferred training intensity',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  /// Build content section
  Widget _buildContentSection() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // First row
          Row(
            children: [
              Expanded(
                child: _buildModeCard(
                  mode: 'relax',
                  badge: 'RELAX',
                  title: 'Relaxation',
                  description: 'Reduce muscle tension\nGentle movements',
                  badgeColor: const Color(0xFF9B59B6),
                  imageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildModeCard(
                  mode: 'stretch',
                  badge: 'STRETCH',
                  title: 'Flexibility',
                  description: 'Improve mobility\nIncrease range of motion',
                  badgeColor: const Color(0xFF2ECC71),
                  imageUrl: 'https://images.unsplash.com/photo-1588286840104-8957b019727f?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Second row
          Row(
            children: [
              Expanded(
                child: _buildModeCard(
                  mode: 'moderate',
                  badge: 'MODERATE',
                  title: 'Cardio',
                  description: 'Light sweat session\nModerate heart rate',
                  badgeColor: const Color(0xFFF39C12),
                  imageUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildModeCard(
                  mode: 'strength',
                  badge: 'STRENGTH',
                  title: 'Power Training',
                  description: 'Build muscle strength\nResistance exercises',
                  badgeColor: const Color(0xFFE74C3C),
                  imageUrl: 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build bottom button area
  Widget _buildBottomButtonArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedMode != null ? _onContinuePressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: (_selectedMode != null) ? const Color(0xFFFFD700) : Colors.grey.shade300,
              foregroundColor: (_selectedMode != null) ? Colors.white : Colors.grey.shade500,
              elevation: (_selectedMode != null) ? 8 : 0,
              shadowColor: (_selectedMode != null) ? const Color(0xFFFFD700).withOpacity(0.3) : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              minimumSize: const Size(0, 56),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required String mode,
    required String badge,
    required String title,
    required String description,
    required Color badgeColor,
    required String imageUrl,
  }) {
    final isSelected = _selectedMode == mode;

    return GestureDetector(
      onTap: () => _onModeSelected(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD700) : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Title
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Description
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          height: 1.4,
                          shadows: const [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Selection Animation Overlay
              if (isSelected)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFFD700),
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onModeSelected(String mode) {
    setState(() {
      _selectedMode = mode;
    });

    // Update provider with selected mode
    final provider = context.read<WorkoutGuideProvider>();
    switch (mode) {
      case 'relax':
        provider.selectIntent(WorkoutIntent.relax);
        break;
      case 'stretch':
        provider.selectIntent(WorkoutIntent.stretch);
        break;
      case 'moderate':
        provider.selectIntent(WorkoutIntent.lightCardio);
        break;
      case 'strength':
        provider.selectIntent(WorkoutIntent.strength);
        break;
    }
  }

  void _onContinuePressed() {
    if (_selectedMode != null) {
      // ✅ 正确导航：Step 2 完成后去 Step 3 选择目标肌群
      AppRoutes.navigateToWorkoutGuideStep3(
        context,
        guideData: {
          'detectedScene': _detectedScene,
          'detectedEquipment': _detectedEquipment,
          'selectedMode': _selectedMode,
        },
      );
    }
  }
}
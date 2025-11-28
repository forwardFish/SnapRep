import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/workout_guide_provider.dart';
import '../../../routes/app_routes.dart';

/// Workout Guide Step 3 - Target Muscle Selection Page
/// Matches HTML reference: 04-guide-step3.html
class WorkoutGuideStep3Page extends StatefulWidget {
  const WorkoutGuideStep3Page({super.key});

  @override
  State<WorkoutGuideStep3Page> createState() => _WorkoutGuideStep3PageState();
}

class _WorkoutGuideStep3PageState extends State<WorkoutGuideStep3Page> {
  // 跟踪每个独立身体部位的选择状态
  final Set<String> _selectedBodyParts = {};

  @override
  void initState() {
    super.initState();
    // Initialize step 3
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutGuideProvider>().initializeStep3();
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
      body: Consumer<WorkoutGuideProvider>(
        builder: (context, provider, child) {
          return Column(
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

                      const SizedBox(height: 32),

                      // Title section
                      _buildTitleSection(),

                      const SizedBox(height: 32),

                      // Target muscle selection area
                      Expanded(
                        child: _buildTargetMuscleSelection(provider),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom button area
              _buildBottomButtonArea(provider),
            ],
          );
        },
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
              color: const Color(0xFFFFD700),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: const Color(0xFFFFD700),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: const Color(0xFFFFD700),
            ),
          ),
        ),
      ],
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
                  '3',
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
              'STEP 3',
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
          'Choose your\ntarget zones',
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
          'Select muscle groups you want to focus on today',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  /// Build target muscle selection area
  Widget _buildTargetMuscleSelection(WorkoutGuideProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Target Areas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${provider.selectedTargetMuscles.length} Selected',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFD700),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: provider.isLoadingTargetMuscles
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFD700)),
              )
            : Row(
                children: [
                  // Left Side: Body Diagram
                  Expanded(
                    flex: 1,
                    child: _buildBodyDiagram(),
                  ),
                  const SizedBox(width: 20),
                  // Right Side: Body Parts Selection
                  Expanded(
                    flex: 1,
                    child: _buildBodyPartsList(provider),
                  ),
                ],
              ),
        ),
      ],
    );
  }

  /// Build body diagram section (left side)
  Widget _buildBodyDiagram() {
    return Center(
      child: Container(
        width: 160,
        height: 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
          image: const DecorationImage(
            image: NetworkImage('https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  /// Build body parts selection list (right side)
  Widget _buildBodyPartsList(WorkoutGuideProvider provider) {
    final bodyParts = [
      {'name': 'Neck', 'value': 'NECK_SHOULDER', 'uniqueId': 'neck'},
      {'name': 'Pecs', 'value': 'CHEST_BACK', 'uniqueId': 'pecs'},
      {'name': 'Arms', 'value': 'ARMS', 'uniqueId': 'arms'},
      {'name': 'Belly', 'value': 'CORE', 'uniqueId': 'belly'},
      {'name': 'Back', 'value': 'CHEST_BACK', 'uniqueId': 'back'},
      {'name': 'Legs', 'value': 'LEGS', 'uniqueId': 'legs'},
      {'name': 'Knees', 'value': 'LEGS', 'uniqueId': 'knees'},
      {'name': 'Lower back', 'value': 'CORE', 'uniqueId': 'lower_back'},
    ];

    return SingleChildScrollView(
      child: Column(
        children: bodyParts.map((part) {
          final isSelected = _selectedBodyParts.contains(part['uniqueId']!);
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            child: _buildBodyPartButton(
              name: part['name']!,
              value: part['value']!,
              uniqueId: part['uniqueId']!,
              isSelected: isSelected,
              onTap: () => _onBodyPartTapped(provider, part['value']!, part['uniqueId']!),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Build individual body part button
  Widget _buildBodyPartButton({
    required String name,
    required String value,
    required String uniqueId,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6B35) : const Color(0xFFF5F5F5),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
          color: isSelected ? const Color(0xFFFF6B35) : Colors.white,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity(0.3),
                    blurRadius: 4,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF333333),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Check if body part is selected
  bool _isBodyPartSelected(WorkoutGuideProvider provider, String bodyPartValue) {
    // Map body part values to TargetMuscle enum name (camelCase)
    final targetMuscleEnumMap = {
      'NECK_SHOULDER': ['neckShoulder'],  // ✅ 使用小驼峰
      'CHEST_BACK': ['chestBack'],
      'ARMS': ['arms'],
      'CORE': ['core'],
      'LEGS': ['legs'],
      'FULL_BODY': ['fullBody'],
      'GLUTES': ['glutes'],
      'CALVES': ['calves'],
    };

    final enumNames = targetMuscleEnumMap[bodyPartValue] ?? [];
    return provider.selectedTargetMuscles.any(
      (muscle) => enumNames.contains(muscle.name),
    );
  }

  /// Handle body part tap
  void _onBodyPartTapped(WorkoutGuideProvider provider, String bodyPartValue, String uniqueId) {
    setState(() {
      // 切换本地选择状态
      if (_selectedBodyParts.contains(uniqueId)) {
        _selectedBodyParts.remove(uniqueId);
      } else {
        _selectedBodyParts.add(uniqueId);
      }
    });

    // Map body part values to TargetMuscle enum values
    final targetMuscleEnumMap = {
      'NECK_SHOULDER': 'neckShoulder',
      'CHEST_BACK': 'chestBack',
      'ARMS': 'arms',
      'CORE': 'core',
      'LEGS': 'legs',
    };

    final enumKey = targetMuscleEnumMap[bodyPartValue];
    if (enumKey != null) {
      // Find the corresponding TargetMuscle from available muscles
      final targetMuscle = provider.availableTargetMuscles.firstWhere(
        (muscle) => muscle.name == enumKey,
        orElse: () => provider.availableTargetMuscles.first,
      );
      provider.toggleTargetMuscle(targetMuscle);
    }
  }

  /// Build bottom button area
  Widget _buildBottomButtonArea(WorkoutGuideProvider provider) {
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
          child: _buildGenerateButton(provider),
        ),
      ),
    );
  }

  /// Build generate plan button
  Widget _buildGenerateButton(WorkoutGuideProvider provider) {
    final isEnabled = provider.canGenerateWorkout;
    final isGenerating = provider.isGeneratingWorkout;

    // 🔍 临时调试信息
    debugPrint('🔍 Generate button state:');
    debugPrint('  isStep1Valid: ${provider.isStep1Valid}');
    debugPrint('  isStep2Valid: ${provider.isStep2Valid}');
    debugPrint('  isStep3Valid: ${provider.isStep3Valid}');
    debugPrint('  canGenerateWorkout: $isEnabled');
    debugPrint('  selectedIntents: ${provider.selectedIntents.map((i) => i.displayName).toList()}');
    debugPrint('  selectedScenario: ${provider.selectedScenario?.name}');
    debugPrint('  selectedEquipment: ${provider.selectedEquipment.map((e) => e.name).toList()}');
    debugPrint('  selectedTargetMuscles: ${provider.selectedTargetMuscles.map((m) => m.displayName).toList()}');

    return Column(
      children: [
        ElevatedButton(
          onPressed: isEnabled && !isGenerating ? () => _generateWorkout(provider) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isEnabled ? const Color(0xFFFFD700) : Colors.grey.shade300,
            foregroundColor: isEnabled ? Colors.white : Colors.grey.shade500,
            elevation: isEnabled ? 8 : 0,
            shadowColor: isEnabled ? const Color(0xFFFFD700).withOpacity(0.3) : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            minimumSize: const Size(0, 56),
          ),
          child: isGenerating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Generate Plan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isEnabled ? Colors.white : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
        ),
      ],
    );
  }

  /// Generate workout plan
  Future<void> _generateWorkout(WorkoutGuideProvider provider) async {
    // Validate current step
    if (!provider.canGenerateWorkout) {
      _showErrorSnackBar('请至少选择一个目标部位');
      return;
    }

    try {
      // Clear any previous errors
      provider.setError(null);

      // Generate workout recommendation
      final workoutSession = await provider.generateWorkoutRecommendation();

      if (workoutSession != null && workoutSession['exercises'] != null) {
        final exercises = workoutSession['exercises'] as List;

        if (exercises.isEmpty) {
          // 没有找到训练动作 - 显示友好提示
          _showWarningSnackBar(
            '未找到符合您选择的训练动作\n建议：尝试调整场景、器材或目标部位',
          );
          return;
        }

        // Navigate to workout result page
        if (mounted) {
          AppRoutes.pushToWorkoutResult(
            context,
            recommendationParams: workoutSession,
          ).then((result) {
            if (result == true) {
              // Can handle workout completion logic here
            }
          });
        }
      } else {
        // 检查provider的error状态
        final error = provider.error;
        if (error != null && error.isNotEmpty) {
          _showErrorSnackBar(error);
        } else {
          _showErrorSnackBar('生成训练计划失败，请重试');
        }
      }
    } catch (e) {
      debugPrint('❌ Error in _generateWorkout: $e');
      _showErrorSnackBar('生成训练计划时发生错误，请重试');
    }
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Show warning snackbar (for no results)
  void _showWarningSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
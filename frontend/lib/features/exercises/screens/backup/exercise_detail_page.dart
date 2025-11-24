import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/exercise.dart';
import '../../../core/models/popular_exercise_dto.dart';
import '../../../core/models/target_muscle.dart';
import '../../../core/models/workout_intent.dart';
import '../../../core/services/exercise_service.dart';
import '../../../routes/app_routes.dart';

/// 训练动作详情页面
/// 显示单个动作的详细信息、视频、相关推荐等
class ExerciseDetailPage extends StatefulWidget {
  final String? exerciseId;
  final String? exerciseName;
  final PopularExerciseDto? popularExercise;

  const ExerciseDetailPage({
    super.key,
    this.exerciseId,
    this.exerciseName,
    this.popularExercise,
  });

  @override
  State<ExerciseDetailPage> createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends State<ExerciseDetailPage> {
  Exercise? exercise;
  List<Exercise> relatedExercises = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadExerciseDetails();
  }

  Future<void> _loadExerciseDetails() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      // 如果有 exerciseId,加载详细信息
      if (widget.exerciseId != null) {
        // TODO: 调用 API 获取动作详情
        // final exerciseService = ExerciseService();
        // exercise = await exerciseService.getExerciseById(widget.exerciseId!);

        // 暂时使用模拟数据
        exercise = Exercise(
          id: widget.exerciseId!,
          code: 'mock_exercise',
          name: widget.exerciseName ?? '动作名称',
          description: '这是一个有效的训练动作,可以帮助你锻炼目标肌群。通过规律练习,能够有效提升身体素质。',
          primaryMuscle: TargetMuscle.core,
          secondaryMuscles: [TargetMuscle.legs, TargetMuscle.arms],
          intentType: WorkoutIntent.stretch,
          difficulty: ExerciseDifficulty.intermediate,
          durationSeconds: 30,
          sets: 3,
          repetitions: 12,
          thumbnailUrl: null,
          demoVideoUrl: 'https://example.com/video.mp4',
          keyPoints: [
            '准备姿势:站立,双脚与肩同宽',
            '开始动作:缓慢下蹲,保持背部挺直',
            '保持姿势:在最低点停留2-3秒',
            '返回起始位置:缓慢站起',
          ],
          safetyWarnings: [
            '保持呼吸均匀,不要憋气',
            '注意膝盖不要超过脚尖',
            '核心保持紧张,保护腰椎',
            '如感到不适立即停止',
          ],
          benefits: '增强核心力量,改善平衡能力,提升身体稳定性,塑造腿部线条',
          tags: [ExerciseTag.standing, ExerciseTag.handsFreee, ExerciseTag.strength],
        );
      }

      // 加载相关推荐动作
      // relatedExercises = await exerciseService.getRelatedExercises(widget.exerciseId!);

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
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
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('加载失败: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadExerciseDetails,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (exercise == null) {
      return const Center(child: Text('动作信息不存在'));
    }

    return CustomScrollView(
      slivers: [
        // App Bar with background image
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              exercise!.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black45,
                    offset: Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Background image or gradient
                exercise!.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: exercise!.thumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                // Dark overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick stats row
                _buildStatsRow(),
                const SizedBox(height: 24),

                // Description
                _buildSectionTitle('动作说明'),
                const SizedBox(height: 12),
                Text(
                  exercise!.description,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 32),

                // Target Muscles
                _buildSectionTitle('目标肌群'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text(exercise!.primaryMuscle.displayName),
                      backgroundColor: const Color(0xFF6366F1).withOpacity(0.2),
                      labelStyle: const TextStyle(
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ...exercise!.secondaryMuscles.map((muscle) {
                      return Chip(
                        label: Text(muscle.displayName),
                        backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                        labelStyle: const TextStyle(
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 32),

                // Benefits
                _buildSectionTitle('训练好处'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          exercise!.benefits,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Key Points (Instructions)
                _buildSectionTitle('动作要领'),
                const SizedBox(height: 12),
                ...exercise!.keyPoints.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 32),

                // Safety Warnings
                _buildSectionTitle('安全提示'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: exercise!.safetyWarnings.map((warning) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                warning,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 32),

                // Equipment tags
                if (exercise!.tags.isNotEmpty) ...[
                  _buildSectionTitle('训练标签'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: exercise!.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          tag.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                ],

                // Start button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _startWorkout(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '开始训练',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatItem(
          Icons.timer_outlined,
          '${exercise!.durationSeconds}秒',
          '每组时长',
        ),
        const SizedBox(width: 16),
        _buildStatItem(
          Icons.repeat_rounded,
          '${exercise!.sets}组',
          '组数',
        ),
        const SizedBox(width: 16),
        _buildStatItem(
          Icons.signal_cellular_alt,
          exercise!.difficulty.displayName,
          '难度',
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF6366F1), size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startWorkout() {
    // 开始训练,跳转到训练视频页面
    if (exercise != null) {
      AppRoutes.navigateToProfessionalWorkoutVideo(
        context,
        exercise: exercise!,
        exercises: [exercise!],
        currentExerciseIndex: 0,
      );
    }
  }
}

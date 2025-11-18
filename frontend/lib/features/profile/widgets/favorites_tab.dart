import 'package:flutter/material.dart';
import '../../../core/models/workout_session.dart';
import '../../../core/models/exercise.dart';

/// 收藏Tab - 显示收藏的训练计划和动作
class FavoritesTab extends StatefulWidget {
  const FavoritesTab({super.key});

  @override
  State<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab> {
  // Mock数据 - 实际应用中从API获取
  final List<Map<String, dynamic>> _mockFavoriteWorkouts = [
    {
      'title': 'Office Chair Workout',
      'description': 'Perfect for desk workers',
      'duration': 15,
      'exercises': 8,
      'difficulty': 'Beginner',
      'category': 'Office',
    },
    {
      'title': 'Full Body Home Routine',
      'description': 'Complete home workout',
      'duration': 25,
      'exercises': 12,
      'difficulty': 'Intermediate',
      'category': 'Home',
    },
    {
      'title': 'Core Strength Builder',
      'description': 'Build a strong core',
      'duration': 20,
      'exercises': 10,
      'difficulty': 'Advanced',
      'category': 'Core',
    },
  ];

  final List<Map<String, dynamic>> _mockFavoriteExercises = [
    {
      'name': 'Wall Push-ups',
      'targetMuscle': 'Chest & Arms',
      'difficulty': 'Beginner',
      'equipment': 'Wall',
    },
    {
      'name': 'Chair Squats',
      'targetMuscle': 'Legs & Glutes',
      'difficulty': 'Beginner',
      'equipment': 'Chair',
    },
    {
      'name': 'Desk Planks',
      'targetMuscle': 'Core',
      'difficulty': 'Intermediate',
      'equipment': 'Desk',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 收藏的训练计划部分
        _buildSectionHeader('Saved Workouts', Icons.fitness_center),
        const SizedBox(height: 12),

        if (_mockFavoriteWorkouts.isEmpty)
          _buildEmptyState('No saved workouts yet', Icons.bookmark_border)
        else
          ..._mockFavoriteWorkouts.map((workout) => _buildWorkoutCard(workout)),

        const SizedBox(height: 24),

        // 收藏的动作部分
        _buildSectionHeader('Favorite Exercises', Icons.favorite),
        const SizedBox(height: 12),

        if (_mockFavoriteExercises.isEmpty)
          _buildEmptyState('No favorite exercises yet', Icons.favorite_border)
        else
          ..._mockFavoriteExercises.map((exercise) => _buildExerciseCard(exercise)),
      ],
    );
  }

  /// 构建区域标题
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF4CAF50),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  /// 构建空状态提示
  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建训练计划卡片
  Widget _buildWorkoutCard(Map<String, dynamic> workout) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4CAF50),
            Color(0xFF388E3C),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleWorkoutTap(workout),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 左侧图标
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: Colors.white,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 16),

                // 中间内容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        workout['description'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildWorkoutTag('${workout['duration']} min'),
                          const SizedBox(width: 8),
                          _buildWorkoutTag('${workout['exercises']} exercises'),
                          const SizedBox(width: 8),
                          _buildWorkoutTag(workout['difficulty']),
                        ],
                      ),
                    ],
                  ),
                ),

                // 右侧操作按钮
                IconButton(
                  onPressed: () => _handleRemoveFavoriteWorkout(workout),
                  icon: const Icon(
                    Icons.favorite,
                    color: Color(0xFFFFD700),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建训练标签
  Widget _buildWorkoutTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 构建动作卡片
  Widget _buildExerciseCard(Map<String, dynamic> exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleExerciseTap(exercise),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 左侧图标
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.sports_gymnastics,
                    color: Color(0xFF4CAF50),
                    size: 24,
                  ),
                ),

                const SizedBox(width: 12),

                // 中间内容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise['name'],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.track_changes,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            exercise['targetMuscle'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getDifficultyColor(exercise['difficulty']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              exercise['difficulty'],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _getDifficultyColor(exercise['difficulty']),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 右侧操作按钮
                IconButton(
                  onPressed: () => _handleRemoveFavoriteExercise(exercise),
                  icon: const Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 根据难度获取颜色
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return const Color(0xFF4CAF50);
      case 'intermediate':
        return const Color(0xFFFF9800);
      case 'advanced':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  /// 处理训练计划点击
  void _handleWorkoutTap(Map<String, dynamic> workout) {
    debugPrint('Tapped workout: ${workout['title']}');
    // TODO: 导航到训练详情页
  }

  /// 处理动作点击
  void _handleExerciseTap(Map<String, dynamic> exercise) {
    debugPrint('Tapped exercise: ${exercise['name']}');
    // TODO: 显示动作详情弹窗
  }

  /// 处理取消收藏训练计划
  void _handleRemoveFavoriteWorkout(Map<String, dynamic> workout) {
    setState(() {
      _mockFavoriteWorkouts.remove(workout);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed "${workout['title']}" from favorites'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() {
              _mockFavoriteWorkouts.add(workout);
            });
          },
        ),
      ),
    );
  }

  /// 处理取消收藏动作
  void _handleRemoveFavoriteExercise(Map<String, dynamic> exercise) {
    setState(() {
      _mockFavoriteExercises.remove(exercise);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed "${exercise['name']}" from favorites'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() {
              _mockFavoriteExercises.add(exercise);
            });
          },
        ),
      ),
    );
  }
}

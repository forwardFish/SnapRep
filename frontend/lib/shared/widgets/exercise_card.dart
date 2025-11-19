import 'package:flutter/material.dart';
import '../../core/models/exercise.dart';

/// 动作卡片组件
/// 用于显示动作信息的卡片
class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showDuration;
  final bool isCompact;

  const ExerciseCard({
    super.key,
    required this.exercise,
    this.isSelected = false,
    this.onTap,
    this.showDuration = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6C5CE7).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6C5CE7)
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 动作图片/图标
            Container(
              height: isCompact ? 60 : 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: exercise.demoImageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        exercise.demoImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            _getExerciseIcon(exercise.primaryMuscle),
                            size: isCompact ? 24 : 32,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        _getExerciseIcon(exercise.primaryMuscle),
                        size: isCompact ? 24 : 32,
                        color: Colors.grey[400],
                      ),
                    ),
            ),

            SizedBox(height: isCompact ? 8 : 12),

            // 动作名称
            Text(
              exercise.name,
              style: TextStyle(
                fontSize: isCompact ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            SizedBox(height: isCompact ? 4 : 8),

            // 部位和难度
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getMuscleColor(exercise.primaryMuscle).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getMuscleName(exercise.primaryMuscle),
                    style: TextStyle(
                      fontSize: isCompact ? 10 : 12,
                      color: _getMuscleColor(exercise.primaryMuscle),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const Spacer(),

                DifficultyIndicator(
                  difficulty: exercise.difficulty,
                  size: isCompact ? 12 : 16,
                ),
              ],
            ),

            if (showDuration) ...[
              SizedBox(height: isCompact ? 4 : 8),

              // 时长信息
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: isCompact ? 14 : 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${exercise.defaultDuration}${exercise.durationType == 'TIME' ? '秒' : '次'}',
                    style: TextStyle(
                      fontSize: isCompact ? 12 : 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getExerciseIcon(String primaryMuscle) {
    switch (primaryMuscle.toLowerCase()) {
      case 'chest':
        return Icons.favorite_outline;
      case 'back':
        return Icons.accessibility;
      case 'legs':
        return Icons.directions_walk;
      case 'glutes':
        return Icons.fitness_center;
      case 'shoulders':
        return Icons.sports_gymnastics;
      case 'arms':
        return Icons.sports_handball;
      case 'core':
        return Icons.center_focus_strong;
      case 'full_body':
        return Icons.accessibility_new;
      case 'neck_shoulder':
        return Icons.person_outline;
      default:
        return Icons.fitness_center;
    }
  }

  Color _getMuscleColor(String primaryMuscle) {
    switch (primaryMuscle.toLowerCase()) {
      case 'chest':
        return const Color(0xFFE91E63);
      case 'back':
        return const Color(0xFF3F51B5);
      case 'legs':
        return const Color(0xFF4CAF50);
      case 'glutes':
        return const Color(0xFF9C27B0);
      case 'shoulders':
        return const Color(0xFFFF9800);
      case 'arms':
        return const Color(0xFFF44336);
      case 'core':
        return const Color(0xFF795548);
      case 'full_body':
        return const Color(0xFF607D8B);
      case 'neck_shoulder':
        return const Color(0xFF00BCD4);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _getMuscleName(String primaryMuscle) {
    switch (primaryMuscle.toLowerCase()) {
      case 'chest':
        return '胸部';
      case 'back':
        return '背部';
      case 'legs':
        return '腿部';
      case 'glutes':
        return '臀部';
      case 'shoulders':
        return '肩部';
      case 'arms':
        return '手臂';
      case 'core':
        return '核心';
      case 'full_body':
        return '全身';
      case 'neck_shoulder':
        return '颈肩';
      default:
        return primaryMuscle.toUpperCase();
    }
  }
}

/// 难度指示器
class DifficultyIndicator extends StatelessWidget {
  final String difficulty;
  final double size;

  const DifficultyIndicator({
    super.key,
    required this.difficulty,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (difficulty.toUpperCase()) {
      case 'GREEN':
        color = const Color(0xFF4CAF50);
        text = '简单';
        break;
      case 'BLUE':
        color = const Color(0xFF2196F3);
        text = '中等';
        break;
      case 'RED':
        color = const Color(0xFFF44336);
        text = '困难';
        break;
      default:
        color = Colors.grey;
        text = '未知';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: size * 0.75,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 快速预览卡片（用于最快路径）
class QuickExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final bool isSelected;
  final VoidCallback? onTap;

  const QuickExerciseCard({
    super.key,
    required this.exercise,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6C5CE7).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6C5CE7)
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // 动作名称
            Text(
              exercise.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // 肌群标签
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _getMuscleName(exercise.primaryMuscle),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6C5CE7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 时长
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  '${exercise.defaultDuration}秒',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getMuscleName(String primaryMuscle) {
    switch (primaryMuscle.toLowerCase()) {
      case 'chest':
        return '胸部';
      case 'back':
        return '背部';
      case 'legs':
        return '腿部';
      case 'glutes':
        return '臀部';
      case 'shoulders':
        return '肩部';
      case 'arms':
        return '手臂';
      case 'core':
        return '核心';
      case 'full_body':
        return '全身';
      case 'neck_shoulder':
        return '颈肩';
      default:
        return primaryMuscle.toUpperCase();
    }
  }
}
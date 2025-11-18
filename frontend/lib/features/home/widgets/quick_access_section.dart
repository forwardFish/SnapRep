import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart';

/// 快速访问区域组件 - 为用户提供常用功能的快速入口
class QuickAccessSection extends StatelessWidget {
  const QuickAccessSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 区域标题
          Row(
            children: [
              Icon(
                Icons.flash_on,
                size: 20,
                color: const Color(0xFF4CAF50),
              ),
              const SizedBox(width: 8),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 快速操作按钮网格
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  icon: Icons.timer,
                  title: '5 Min Break',
                  subtitle: 'Office stretch',
                  color: const Color(0xFF4CAF50),
                  onTap: () => _handle5MinBreak(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  icon: Icons.fitness_center,
                  title: 'Full Workout',
                  subtitle: 'Home routine',
                  color: const Color(0xFFFF9800),
                  onTap: () => _handleFullWorkout(context),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  icon: Icons.self_improvement,
                  title: 'Neck & Back',
                  subtitle: 'Pain relief',
                  color: const Color(0xFF2196F3),
                  onTap: () => _handleNeckAndBack(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  icon: Icons.history,
                  title: 'Last Workout',
                  subtitle: 'Repeat session',
                  color: const Color(0xFF9C27B0),
                  onTap: () => _handleLastWorkout(context),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 推荐时间段提示
          _buildRecommendedTimeWidget(context),
        ],
      ),
    );
  }

  /// 构建快速操作卡片
  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建推荐时间段提示组件
  Widget _buildRecommendedTimeWidget(BuildContext context) {
    final currentHour = DateTime.now().hour;
    String message;
    IconData icon;
    Color color;

    if (currentHour >= 6 && currentHour < 9) {
      message = "🌅 Perfect time for morning energizer!";
      icon = Icons.wb_sunny;
      color = const Color(0xFFFF9800);
    } else if (currentHour >= 9 && currentHour < 12) {
      message = "⚡ Boost your productivity with a quick break!";
      icon = Icons.bolt;
      color = const Color(0xFF4CAF50);
    } else if (currentHour >= 12 && currentHour < 14) {
      message = "🍽️ Post-lunch stretch to stay active!";
      icon = Icons.restaurant;
      color = const Color(0xFF2196F3);
    } else if (currentHour >= 14 && currentHour < 17) {
      message = "💪 Afternoon energy boost time!";
      icon = Icons.fitness_center;
      color = const Color(0xFFFF5722);
    } else if (currentHour >= 17 && currentHour < 20) {
      message = "🏠 Wind down with a gentle routine!";
      icon = Icons.home;
      color = const Color(0xFF9C27B0);
    } else {
      message = "🌙 Relax with gentle stretches before bed!";
      icon = Icons.nightlight_round;
      color = const Color(0xFF673AB7);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 处理5分钟休息
  void _handle5MinBreak(BuildContext context) {
    AppRoutes.navigateToWorkoutResult(
      context,
      recommendationParams: {
        'intent': 'STRETCH',
        'equipment': ['hands_free', 'chair'],
        'duration': 300, // 5 minutes
        'tags': ['office', 'break', 'quick'],
        'targetMuscles': ['neck_shoulder', 'back_spine'],
        'isQuickStart': true,
      },
    );
  }

  /// 处理全套训练
  void _handleFullWorkout(BuildContext context) {
    AppRoutes.navigateToWorkoutResult(
      context,
      recommendationParams: {
        'intent': 'FITNESS',
        'equipment': ['hands_free'],
        'duration': 1200, // 20 minutes
        'tags': ['full_body', 'strength'],
        'targetMuscles': ['full_body'],
        'isQuickStart': true,
      },
    );
  }

  /// 处理颈背训练
  void _handleNeckAndBack(BuildContext context) {
    AppRoutes.navigateToWorkoutResult(
      context,
      recommendationParams: {
        'intent': 'THERAPY',
        'equipment': ['hands_free', 'wall'],
        'duration': 480, // 8 minutes
        'tags': ['pain_relief', 'therapeutic'],
        'targetMuscles': ['neck_shoulder', 'back_spine'],
        'isQuickStart': true,
      },
    );
  }

  /// 处理重复上次训练
  void _handleLastWorkout(BuildContext context) {
    // 导航到我的页面的历史Tab
    AppRoutes.navigateToMyPage(
      context,
      initialTabIndex: 1, // History tab
    );
  }
}
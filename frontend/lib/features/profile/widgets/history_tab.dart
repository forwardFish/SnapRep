import 'package:flutter/material.dart';

/// 历史Tab - 显示训练历史记录
class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  // Mock数据 - 实际应用中从API获取
  final List<Map<String, dynamic>> _mockWorkoutHistory = [
    {
      'id': '1',
      'title': 'Chair & Full Body Master',
      'date': DateTime.now().subtract(const Duration(hours: 2)),
      'duration': Duration(minutes: 15, seconds: 30),
      'completedExercises': 8,
      'totalExercises': 8,
      'caloriesBurned': 95,
      'difficulty': 'Intermediate',
      'status': 'completed',
    },
    {
      'id': '2',
      'title': 'Office Stretching Routine',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'duration': Duration(minutes: 12, seconds: 45),
      'completedExercises': 6,
      'totalExercises': 6,
      'caloriesBurned': 65,
      'difficulty': 'Beginner',
      'status': 'completed',
    },
    {
      'id': '3',
      'title': 'Core Strength Workout',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'duration': Duration(minutes: 8, seconds: 20),
      'completedExercises': 4,
      'totalExercises': 10,
      'caloriesBurned': 45,
      'difficulty': 'Advanced',
      'status': 'cancelled',
    },
    {
      'id': '4',
      'title': 'Morning Energy Booster',
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'duration': Duration(minutes: 18, seconds: 10),
      'completedExercises': 9,
      'totalExercises': 9,
      'caloriesBurned': 110,
      'difficulty': 'Intermediate',
      'status': 'completed',
    },
    {
      'id': '5',
      'title': 'Quick Desk Break',
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'duration': Duration(minutes: 5, seconds: 0),
      'completedExercises': 3,
      'totalExercises': 3,
      'caloriesBurned': 25,
      'difficulty': 'Beginner',
      'status': 'completed',
    },
  ];

  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Completed', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    final filteredHistory = _getFilteredHistory();

    return Column(
      children: [
        // 统计卡片
        _buildStatsSection(),

        // 筛选器
        _buildFilterSection(),

        // 历史记录列表
        Expanded(
          child: filteredHistory.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredHistory.length,
                  itemBuilder: (context, index) {
                    final workout = filteredHistory[index];
                    return _buildHistoryCard(workout);
                  },
                ),
        ),
      ],
    );
  }

  /// 构建统计区域
  Widget _buildStatsSection() {
    final totalWorkouts = _mockWorkoutHistory.where((w) => w['status'] == 'completed').length;
    final totalDuration = _mockWorkoutHistory
        .where((w) => w['status'] == 'completed')
        .map((w) => w['duration'] as Duration)
        .fold(Duration.zero, (sum, duration) => sum + duration);
    final totalCalories = _mockWorkoutHistory
        .where((w) => w['status'] == 'completed')
        .map((w) => w['caloriesBurned'] as int)
        .fold(0, (sum, calories) => sum + calories);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4CAF50),
            Color(0xFF388E3C),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Your Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  totalWorkouts.toString(),
                  'Workouts',
                  Icons.fitness_center,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '${totalDuration.inMinutes}m',
                  'Total Time',
                  Icons.timer,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  totalCalories.toString(),
                  'Calories',
                  Icons.local_fire_department,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFFFFD700),
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 构建筛选区域
  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text(
            'Filter:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterOptions.map((option) {
                  final isSelected = _selectedFilter == option;
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(option),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = option;
                        });
                      },
                      selectedColor: const Color(0xFF4CAF50).withOpacity(0.2),
                      checkmarkColor: const Color(0xFF4CAF50),
                      labelStyle: TextStyle(
                        color: isSelected ? const Color(0xFF4CAF50) : Colors.black54,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建历史记录卡片
  Widget _buildHistoryCard(Map<String, dynamic> workout) {
    final isCompleted = workout['status'] == 'completed';
    final completionRate = workout['completedExercises'] / workout['totalExercises'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? Colors.green.shade100 : Colors.red.shade100,
        ),
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
          onTap: () => _handleHistoryTap(workout),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 标题行
                Row(
                  children: [
                    // 状态图标
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isCompleted ? Icons.check_circle : Icons.cancel,
                        color: isCompleted ? Colors.green : Colors.red.shade400,
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 标题和时间
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workout['title'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(workout['date']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 时长
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _formatDuration(workout['duration']),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 进度条
                if (isCompleted)
                  LinearProgressIndicator(
                    value: 1.0,
                    backgroundColor: Colors.green.shade100,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                    minHeight: 4,
                  )
                else
                  LinearProgressIndicator(
                    value: completionRate,
                    backgroundColor: Colors.red.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade300),
                    minHeight: 4,
                  ),

                const SizedBox(height: 8),

                // 统计信息
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${workout['completedExercises']}/${workout['totalExercises']} exercises',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (isCompleted)
                      Text(
                        '${workout['caloriesBurned']} cal',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF9800),
                        ),
                      )
                    else
                      Text(
                        'Cancelled',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade400,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No workout history yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your first workout to see it here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 获取过滤后的历史记录
  List<Map<String, dynamic>> _getFilteredHistory() {
    switch (_selectedFilter) {
      case 'Completed':
        return _mockWorkoutHistory.where((w) => w['status'] == 'completed').toList();
      case 'Cancelled':
        return _mockWorkoutHistory.where((w) => w['status'] == 'cancelled').toList();
      default:
        return _mockWorkoutHistory;
    }
  }

  /// 格式化时长
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  /// 处理历史记录点击
  void _handleHistoryTap(Map<String, dynamic> workout) {
    debugPrint('Tapped workout history: ${workout['title']}');
    // TODO: 显示训练详情弹窗或导航到详情页

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(workout['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${_formatDate(workout['date'])}'),
            Text('Duration: ${_formatDuration(workout['duration'])}'),
            Text('Exercises: ${workout['completedExercises']}/${workout['totalExercises']}'),
            if (workout['status'] == 'completed')
              Text('Calories: ${workout['caloriesBurned']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (workout['status'] == 'completed')
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                debugPrint('Repeat workout: ${workout['title']}');
                // TODO: 重新开始这个训练
              },
              child: const Text('Repeat'),
            ),
        ],
      ),
    );
  }
}
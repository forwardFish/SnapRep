import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/my_page_provider.dart';
import '../../../core/models/workout_session.dart';

/// Workout Details Page - 运动详情页面
/// 显示某一天的运动详情，包括运动内容、时长、完成情况等
/// 使用真实后端数据，不再使用 mock 数据
class WorkoutDetailsPage extends StatefulWidget {
  const WorkoutDetailsPage({super.key});

  @override
  State<WorkoutDetailsPage> createState() => _WorkoutDetailsPageState();
}

class _WorkoutDetailsPageState extends State<WorkoutDetailsPage> {
  late DateTime selectedDate;
  late bool isToday;
  bool isLoading = true;
  List<WorkoutSession> workoutSessions = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get arguments from navigation
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    selectedDate = arguments?['date'] ?? DateTime.now();
    isToday = arguments?['isToday'] ?? false;

    // Load workout sessions for this date
    _loadWorkoutSessionsForDate();
  }

  /// 加载指定日期的训练会话
  Future<void> _loadWorkoutSessionsForDate() async {
    setState(() {
      isLoading = true;
    });

    try {
      final provider = Provider.of<MyPageProvider>(context, listen: false);

      // 从 provider 的历史数据中筛选指定日期的训练
      final dateKey = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final sessions = provider.calendarData[dateKey] ?? [];

      setState(() {
        workoutSessions = sessions;
        isLoading = false;
      });

      debugPrint('📅 Loaded ${sessions.length} workout sessions for ${selectedDate.toString()}');
    } catch (e) {
      debugPrint('❌ Failed to load workout sessions: $e');
      setState(() {
        isLoading = false;
      });
    }
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
        title: Text(
          isToday ? 'Today\'s Workout' : 'Workout Details',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFD700),
              ),
            )
          : workoutSessions.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Header
                      _buildDateHeader(selectedDate, isToday),

                      const SizedBox(height: 24),

                      // Workout Sessions List (从后端获取的真实数据)
                      ...workoutSessions.map((session) => _buildWorkoutSessionCard(session)),
                    ],
                  ),
                ),
    );
  }

  /// Build empty state when no workouts on this date
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              'No Workouts on This Day',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You didn\'t complete any workouts on this date.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Go Back',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build workout session card (使用真实数据)
  Widget _buildWorkoutSessionCard(WorkoutSession session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Session header
          Row(
            children: [
              Icon(
                session.status == WorkoutSessionStatus.completed
                    ? Icons.check_circle
                    : Icons.fitness_center,
                color: session.status == WorkoutSessionStatus.completed
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFFFD700),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.scenarioCode ?? 'Workout Session',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    if (session.completedAt != null)
                      Text(
                        'Completed at ${_formatTime(session.completedAt!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: session.status == WorkoutSessionStatus.completed
                      ? const Color(0xFFE8F5E8)
                      : const Color(0xFFFFF9E6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  session.status.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: session.status == WorkoutSessionStatus.completed
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFFD700),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Stats
          Row(
            children: [
              _buildStatChip(
                Icons.timer,
                'Duration',
                session.actualDurationSec != null
                    ? '${(session.actualDurationSec! / 60).toStringAsFixed(0)} min'
                    : 'N/A',
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                Icons.fitness_center,
                'Exercises',
                '${session.exercises.length}',
              ),
            ],
          ),

          if (session.exercises.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            // Exercise list
            ...session.exercises.take(3).map((exercise) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFD700),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          exercise.name,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                      Text(
                        '${exercise.sets} sets × ${exercise.repetitions ?? 0} reps',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ],
                  ),
                )),
            if (session.exercises.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+${session.exercises.length - 3} more exercises',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// Build stat chip
  Widget _buildStatChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF666666)),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }

  /// Format time
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Build date header
  Widget _buildDateHeader(DateTime date, bool isToday) {
    final dayNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFD700),
            Color(0xFFFFC107),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isToday ? Icons.today : Icons.calendar_today,
                color: Colors.black,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                isToday ? 'Today' : 'Workout Date',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${dayNames[date.weekday]}, ${monthNames[date.month]} ${date.day}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

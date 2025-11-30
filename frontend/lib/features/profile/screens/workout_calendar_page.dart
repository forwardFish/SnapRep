import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/my_page_provider.dart';
import '../../../core/models/workout_session.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/bottom_navigation_bar.dart';

/// Workout Calendar 明细页面
/// 显示月历视图和每日锻炼详情
class WorkoutCalendarPage extends StatefulWidget {
  const WorkoutCalendarPage({super.key});

  @override
  State<WorkoutCalendarPage> createState() => _WorkoutCalendarPageState();
}

class _WorkoutCalendarPageState extends State<WorkoutCalendarPage> {
  int _currentNavIndex = 2; // Profile section
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();

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
          'Workout Calendar',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<MyPageProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Month Navigation
              _buildMonthNavigation(),

              // Calendar Grid
              Expanded(
                flex: 3,
                child: _buildCalendarGrid(provider),
              ),

              // Selected Date Workouts
              Expanded(
                flex: 2,
                child: _buildSelectedDateWorkouts(provider),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }

  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });

    switch (index) {
      case 0:
        // Navigate to home page
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        // Navigate to camera page (workout guide)
        debugPrint('Navigate to camera page');
        AppRoutes.navigateToWorkoutGuideStep1(context);
        break;
      case 2:
        // Already on profile section
        Navigator.pushReplacementNamed(context, '/my-page');
        break;
    }
  }

  /// Month Navigation Header
  Widget _buildMonthNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 28),
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
              });
            },
          ),
          Text(
            _formatMonthYear(_currentMonth),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 28),
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
              });
            },
          ),
        ],
      ),
    );
  }

  /// Full Calendar Grid
  Widget _buildCalendarGrid(MyPageProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Week headers
          _buildWeekHeaders(),

          const SizedBox(height: 8),

          // Calendar days
          Expanded(
            child: _buildCalendarDays(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekHeaders() {
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      children: weekDays.map((day) {
        return Expanded(
          child: Container(
            height: 40,
            alignment: Alignment.center,
            child: Text(
              day,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarDays(MyPageProvider provider) {
    // Calculate first day of month and number of days
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startWeekday = firstDay.weekday; // 1 = Monday, 7 = Sunday

    // Calculate previous month's trailing days
    final previousMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    final daysInPreviousMonth = DateTime(_currentMonth.year, _currentMonth.month, 0).day;

    List<Widget> dayWidgets = [];

    // Previous month's days
    for (int i = startWeekday - 1; i > 0; i--) {
      final day = daysInPreviousMonth - i + 1;
      dayWidgets.add(_buildCalendarDay(
        day,
        false, // not current month
        false, // not selected
        false, // no workout
      ));
    }

    // Current month's days
    final workoutDays = provider.workoutDates.toList(); // Real data from backend
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final isSelected = _isSameDay(date, _selectedDate);
      final hasWorkout = workoutDays.any((workoutDate) => _isSameDay(date, workoutDate));
      final isToday = _isSameDay(date, DateTime.now());

      dayWidgets.add(_buildCalendarDay(
        day,
        true, // current month
        isSelected,
        hasWorkout,
        isToday: isToday,
        onTap: () {
          setState(() {
            _selectedDate = date;
          });
        },
      ));
    }

    // Next month's days to fill the grid
    final totalCells = 42; // 6 weeks × 7 days
    final remainingCells = totalCells - dayWidgets.length;
    for (int day = 1; day <= remainingCells; day++) {
      dayWidgets.add(_buildCalendarDay(
        day,
        false, // not current month
        false, // not selected
        false, // no workout
      ));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
      ),
      itemCount: dayWidgets.length,
      itemBuilder: (context, index) => dayWidgets[index],
    );
  }

  Widget _buildCalendarDay(
    int day,
    bool isCurrentMonth,
    bool isSelected,
    bool hasWorkout, {
    bool isToday = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: isCurrentMonth ? onTap : null,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFD700)
              : hasWorkout
                  ? const Color(0xFFFFD700).withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(color: const Color(0xFFFFD700), width: 2)
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isCurrentMonth
                      ? isSelected
                          ? Colors.black
                          : const Color(0xFF2C3E50)
                      : Colors.grey[400],
                ),
              ),
            ),
            if (hasWorkout && !isSelected)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD700),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Selected Date Workouts Section
  Widget _buildSelectedDateWorkouts(MyPageProvider provider) {
    final workoutDays = provider.workoutDates.toList();
    final hasWorkout = workoutDays.any((date) => _isSameDay(date, _selectedDate));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _formatSelectedDate(_selectedDate),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const Spacer(),
              if (hasWorkout)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Workout Day',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          if (hasWorkout) ...[
            Expanded(
              child: _buildWorkoutDetails(provider),
            ),
          ] else ...[
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fitness_center_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No workout scheduled',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to workout planner (same as camera button)
                            AppRoutes.navigateToWorkoutGuideStep1(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD700),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Plan a Workout'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkoutDetails(MyPageProvider provider) {
    // Get workout sessions for the selected date
    final dateKey = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final sessions = provider.calendarData[dateKey] ?? [];

    if (sessions.isEmpty) {
      return const Center(
        child: Text(
          'No workout details available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Show the first session for the selected date
    final session = sessions.first;
    final durationMin = (session.actualDurationSec ?? session.plannedDurationSec) ~/ 60;
    final calories = session.actualCalories ?? session.estimatedCalories ?? 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workout Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${session.intent.displayName} Workout',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                // Flexible Row to prevent overflow
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '$durationMin min',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '$calories cal',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: session.status == WorkoutSessionStatus.completed
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        session.status.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: session.status == WorkoutSessionStatus.completed
                              ? Colors.green[700]
                              : Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Exercise List
          const Text(
            'Exercises',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),

          const SizedBox(height: 12),

          // Exercise Items from real session data
          ...session.exercises.map((exercise) {
            final isCompleted = session.status == WorkoutSessionStatus.completed;
            final details = exercise.repetitions != null
                ? '${exercise.sets} sets × ${exercise.repetitions} reps'
                : '${exercise.sets} sets × ${exercise.durationSeconds}s';

            return _buildExerciseItem(exercise.name, details, isCompleted);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildExerciseItem(String name, String details, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFFFFD700)
              : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted
                ? const Color(0xFFFFD700)
                : Colors.grey[400],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF2C3E50),
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  details,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _formatMonthYear(DateTime date) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month]} ${date.year}';
  }

  String _formatSelectedDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const weekdays = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[date.weekday]}, ${months[date.month]} ${date.day}';
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}
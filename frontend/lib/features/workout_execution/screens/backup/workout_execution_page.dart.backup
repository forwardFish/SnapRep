import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/workout_execution_provider.dart';
import '../../../core/models/workout_session.dart';
import '../../../routes/app_routes.dart';

/// 训练执行页面
/// 显示当前动作、计时器、进度等
class WorkoutExecutionPage extends StatefulWidget {
  final WorkoutSession workoutSession;

  const WorkoutExecutionPage({
    super.key,
    required this.workoutSession,
  });

  @override
  State<WorkoutExecutionPage> createState() => _WorkoutExecutionPageState();
}

class _WorkoutExecutionPageState extends State<WorkoutExecutionPage>
    with TickerProviderStateMixin {
  late WorkoutExecutionProvider _executionProvider;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // 初始化动画控制器
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // 循环动画
    _pulseController.repeat(reverse: true);

    // 初始化执行provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _executionProvider = Provider.of<WorkoutExecutionProvider>(context, listen: false);
      _executionProvider.initializeWorkout(widget.workoutSession);

      // 监听状态变化
      _executionProvider.addListener(_onExecutionStateChanged);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _executionProvider.removeListener(_onExecutionStateChanged);
    super.dispose();
  }

  /// 监听执行状态变化
  void _onExecutionStateChanged() {
    final state = _executionProvider.state;

    switch (state) {
      case WorkoutExecutionState.completed:
        _handleWorkoutCompleted();
        break;
      case WorkoutExecutionState.cancelled:
        _handleWorkoutCancelled();
        break;
      default:
        break;
    }
  }

  /// 处理训练完成
  void _handleWorkoutCompleted() {
    // 导航到结果页
    AppRoutes.navigateToResultCard(
      context,
      sessionId: widget.workoutSession.id,
    );
  }

  /// 处理训练取消
  void _handleWorkoutCancelled() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<WorkoutExecutionProvider>(
        builder: (context, provider, child) {
          return SafeArea(
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(provider),

                // Main Content
                Expanded(
                  child: _buildMainContent(provider),
                ),

                // Bottom Controls
                _buildBottomControls(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 构建顶部状态栏
  Widget _buildTopBar(WorkoutExecutionProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 返回按钮
          IconButton(
            onPressed: () => _showExitDialog(),
            icon: const Icon(
              Icons.close,
              color: Colors.white,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          // 进度条
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Exercise ${provider.getCurrentExerciseProgressText()}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      provider.getFormattedTime(provider.totalElapsedTime),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: provider.completionProgress,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                  minHeight: 4,
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // 设置按钮
          IconButton(
            onPressed: () => _showSettingsDialog(),
            icon: const Icon(
              Icons.settings,
              color: Colors.white70,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建主要内容区域
  Widget _buildMainContent(WorkoutExecutionProvider provider) {
    switch (provider.state) {
      case WorkoutExecutionState.ready:
        return _buildReadyState(provider);
      case WorkoutExecutionState.countdown:
        return _buildCountdownState(provider);
      case WorkoutExecutionState.exercising:
        return _buildExercisingState(provider);
      case WorkoutExecutionState.resting:
        return _buildRestingState(provider);
      case WorkoutExecutionState.paused:
        return _buildPausedState(provider);
      case WorkoutExecutionState.completed:
        return _buildCompletedState(provider);
      case WorkoutExecutionState.cancelled:
        return _buildCancelledState(provider);
    }
  }

  /// 构建准备状态
  Widget _buildReadyState(WorkoutExecutionProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.fitness_center,
            color: Color(0xFFFFD700),
            size: 80,
          ),
          const SizedBox(height: 24),
          const Text(
            'Ready to Start?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${provider.totalExercises} exercises • ${provider.workoutSession?.primaryMuscleDescription ?? "Full body"}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => provider.startWorkout(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'START WORKOUT',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建倒计时状态
  Widget _buildCountdownState(WorkoutExecutionProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Get Ready!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 40),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFD700),
                      width: 4,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${provider.currentCountdown}',
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 72,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 构建运动状态
  Widget _buildExercisingState(WorkoutExecutionProvider provider) {
    final exercise = provider.currentExercise;
    if (exercise == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 动作名称
          Text(
            exercise.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // 组数信息
          Text(
            'Set ${provider.getCurrentSetProgressText()}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 40),

          // 计时器
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFFD700),
                width: 6,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${provider.currentExerciseRemainingSeconds}',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 64,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'seconds',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // 动作描述
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              exercise.benefits,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建休息状态
  Widget _buildRestingState(WorkoutExecutionProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.local_cafe,
            color: Color(0xFFFFD700),
            size: 60,
          ),
          const SizedBox(height: 24),
          const Text(
            'Rest Time',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            '${provider.currentCountdown}',
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 72,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'seconds',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建暂停状态
  Widget _buildPausedState(WorkoutExecutionProvider provider) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pause_circle_outline,
            color: Color(0xFFFFD700),
            size: 80,
          ),
          SizedBox(height: 24),
          Text(
            'Workout Paused',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Take your time',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建完成状态
  Widget _buildCompletedState(WorkoutExecutionProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.celebration,
            color: Color(0xFFFFD700),
            size: 80,
          ),
          const SizedBox(height: 24),
          const Text(
            'Workout Complete!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Total time: ${provider.getFormattedTime(provider.totalElapsedTime)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建取消状态
  Widget _buildCancelledState(WorkoutExecutionProvider provider) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cancel_outlined,
            color: Colors.white54,
            size: 80,
          ),
          SizedBox(height: 24),
          Text(
            'Workout Cancelled',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建底部控制按钮
  Widget _buildBottomControls(WorkoutExecutionProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 跳过按钮
          if (provider.canSkip)
            _buildControlButton(
              icon: Icons.skip_next,
              label: 'Skip',
              onPressed: () => provider.skipCurrentExercise(),
              color: Colors.white54,
            ),

          // 暂停/恢复按钮
          if (provider.canPause)
            _buildControlButton(
              icon: Icons.pause,
              label: 'Pause',
              onPressed: () => provider.pauseWorkout(),
              color: const Color(0xFFFFD700),
            )
          else if (provider.canResume)
            _buildControlButton(
              icon: Icons.play_arrow,
              label: 'Resume',
              onPressed: () => provider.resumeWorkout(),
              color: const Color(0xFFFFD700),
            ),

          // 停止按钮
          if (provider.state != WorkoutExecutionState.ready &&
              provider.state != WorkoutExecutionState.completed &&
              provider.state != WorkoutExecutionState.cancelled)
            _buildControlButton(
              icon: Icons.stop,
              label: 'Stop',
              onPressed: () => _showStopDialog(),
              color: Colors.red.shade400,
            ),
        ],
      ),
    );
  }

  /// 构建控制按钮
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2),
            border: Border.all(color: color, width: 2),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 显示退出对话框
  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'Exit Workout?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Your progress will be lost if you exit now.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _executionProvider.cancelWorkout();
            },
            child: Text(
              'Exit',
              style: TextStyle(color: Colors.red.shade400),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示停止对话框
  void _showStopDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'Stop Workout?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to stop the current workout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _executionProvider.cancelWorkout();
            },
            child: Text(
              'Stop',
              style: TextStyle(color: Colors.red.shade400),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示设置对话框
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'Workout Settings',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.volume_up, color: Colors.white70),
              title: const Text(
                'Sound Effects',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
                activeColor: const Color(0xFFFFD700),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.vibration, color: Colors.white70),
              title: const Text(
                'Vibration',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
                activeColor: const Color(0xFFFFD700),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
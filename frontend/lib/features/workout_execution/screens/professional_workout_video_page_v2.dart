import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import '../../../core/models/exercise.dart';
import '../../../core/models/reward_card.dart';
import '../../result_card/screens/premium_achievement_card_page.dart';

/// 专业训练视频页面 - Windows兼容版本
/// 包含模拟视频播放、动作指导、计时器和奖励卡片功能
class ProfessionalWorkoutVideoPageV2 extends StatefulWidget {
  final Exercise exercise;
  final List<Exercise> exercises;
  final int currentExerciseIndex;

  const ProfessionalWorkoutVideoPageV2({
    super.key,
    required this.exercise,
    required this.exercises,
    this.currentExerciseIndex = 0,
  });

  @override
  State<ProfessionalWorkoutVideoPageV2> createState() => _ProfessionalWorkoutVideoPageV2State();
}

class _ProfessionalWorkoutVideoPageV2State extends State<ProfessionalWorkoutVideoPageV2>
    with TickerProviderStateMixin {
  late AnimationController _timerController;
  late AnimationController _pulseController;
  late AnimationController _videoAnimationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _videoScaleAnimation;
  late Animation<Color?> _videoColorAnimation;

  // 训练状态
  bool _isPlaying = false;
  bool _isPaused = false;
  bool _isVideoLoaded = true; // Windows平台直接设为已加载
  int _currentSet = 1;
  int _totalSets = 1; // 改为1组，更容易看到奖励卡片
  int _exerciseTimeSeconds = 10; // 改为10秒，更快演示
  int _restTimeSeconds = 5; // 改为5秒休息
  int _currentTimeRemaining = 10; // 对应练习时间
  bool _isRestTime = false;
  bool _showingRewardCard = false;

  // 训练统计
  late DateTime _workoutStartTime;
  int _totalExerciseTime = 0;

  @override
  void initState() {
    super.initState();
    _workoutStartTime = DateTime.now();
    _initializeAnimations();
    _startTimer();
    debugPrint('✅ Video page initialized for Windows platform');
  }

  void _initializeAnimations() {
    _timerController = AnimationController(
      duration: Duration(seconds: _exerciseTimeSeconds),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _videoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _videoScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _videoAnimationController,
      curve: Curves.easeInOut,
    ));

    _videoColorAnimation = ColorTween(
      begin: const Color(0xFF1A1A1A),
      end: const Color(0xFF2A2A2A),
    ).animate(CurvedAnimation(
      parent: _videoAnimationController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
    _videoAnimationController.repeat(reverse: true);
  }

  void _startTimer() {
    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _handleTimerComplete();
      }
    });

    _timerController.addListener(() {
      setState(() {
        final progress = _timerController.value;
        _currentTimeRemaining = (_exerciseTimeSeconds * (1 - progress)).ceil();
      });
    });
  }

  void _handleTimerComplete() {
    debugPrint('🔄 Timer completed: _isRestTime=$_isRestTime, _currentSet=$_currentSet, _totalSets=$_totalSets');

    if (_isRestTime) {
      // 休息完成，开始下一组或下一个动作
      setState(() {
        _isRestTime = false;
        _currentTimeRemaining = _exerciseTimeSeconds;

        if (_currentSet < _totalSets) {
          _currentSet++;
          debugPrint('⚡ Starting set $_currentSet of $_totalSets');
          _timerController.reset();
          _timerController.duration = Duration(seconds: _exerciseTimeSeconds);
        } else {
          // 完成当前动作，跳转到下一个动作或结束训练
          debugPrint('🎉 All sets completed! Triggering reward...');
          _completeExerciseWithReward();
        }
      });
    } else {
      // 动作完成，开始休息
      debugPrint('⏸️ Exercise set completed, starting rest time');
      setState(() {
        _isRestTime = true;
        _currentTimeRemaining = _restTimeSeconds;
        _timerController.reset();
        _timerController.duration = Duration(seconds: _restTimeSeconds);
        _timerController.forward();
      });
    }
  }

  void _completeExerciseWithReward() {
    debugPrint('🏆 _completeExerciseWithReward called');

    // 计算训练时间
    _totalExerciseTime = DateTime.now().difference(_workoutStartTime).inSeconds;

    // 创建奖励卡片
    final rewardCard = RewardCard.workoutCompletion(
      exerciseName: widget.exercise.name,
      setsCompleted: _totalSets,
      totalTime: Duration(seconds: _totalExerciseTime),
    );

    debugPrint('🎁 Created reward card: ${rewardCard.title}, Points: ${rewardCard.points}');

    // 显示奖励卡片
    setState(() {
      _showingRewardCard = true;
    });

    // 震动反馈
    HapticFeedback.heavyImpact();

    debugPrint('🚀 Navigating to reward card page...');

    // 跳转到高级奖励卡片页面
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PremiumAchievementCardPage(
          rewardCard: rewardCard,
          scenarioName: "办公室", // 可以从上下文获取
          equipmentUsed: "椅子", // 可以从上下文获取
          onContinue: () {
            debugPrint('✅ Reward card completed, returning...');
            Navigator.pop(context); // 关闭奖励页面
            _nextExercise(); // 继续下一个动作
          },
        ),
      ),
    ).then((value) {
      debugPrint('📱 Returned from reward card page');
    });
  }

  void _nextExercise() {
    if (widget.currentExerciseIndex < widget.exercises.length - 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProfessionalWorkoutVideoPageV2(
            exercise: widget.exercises[widget.currentExerciseIndex + 1],
            exercises: widget.exercises,
            currentExerciseIndex: widget.currentExerciseIndex + 1,
          ),
        ),
      );
    } else {
      // 完成所有训练
      _showWorkoutCompleteDialog();
    }
  }

  void _startExercise() {
    setState(() {
      _isPlaying = true;
      _isPaused = false;
    });
    _timerController.forward();
    HapticFeedback.lightImpact();
    debugPrint('🎬 Exercise started: ${widget.exercise.name}');
  }

  void _pauseExercise() {
    setState(() {
      _isPaused = true;
    });
    _timerController.stop();
    HapticFeedback.lightImpact();
  }

  void _resumeExercise() {
    setState(() {
      _isPaused = false;
    });
    _timerController.forward();
    HapticFeedback.lightImpact();
  }

  void _stopExercise() {
    _timerController.stop();
    _timerController.reset();
    setState(() {
      _isPlaying = false;
      _isPaused = false;
      _currentTimeRemaining = _exerciseTimeSeconds; // 使用正确的练习时间
      _currentSet = 1;
      _isRestTime = false;
    });
  }

  void _showWorkoutCompleteDialog() {
    // 创建完整训练奖励卡片
    final completionReward = RewardCard.milestone(
      milestone: 'Workout Master',
      totalWorkouts: widget.exercises.length,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Color(0xFFFFD700), size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Workout Complete!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Congratulations! You have completed your workout session.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD700), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars, color: Color(0xFFFFD700)),
                  const SizedBox(width: 8),
                  Text(
                    'Earned ${completionReward.points} bonus points!',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              // 显示完整训练奖励卡片
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PremiumAchievementCardPage(
                    rewardCard: completionReward,
                    scenarioName: "训练完成",
                    equipmentUsed: "全能训练",
                    onContinue: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                  ),
                ),
              );
            },
            child: const Text(
              'Claim Reward',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timerController.dispose();
    _pulseController.dispose();
    _videoAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 改为白色背景，与APP其他页面一致
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(),

            // Main scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Video Player Section
                    _buildVideoSection(),

                    // Exercise Info Section
                    _buildExerciseInfoSection(),

                    // Timer Section
                    _buildTimerSection(),

                    // Controls Section
                    _buildControlsSection(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black, // 改为黑色以配合白色背景
              size: 24,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  widget.exercise.name, // 直接显示动作名称，不显示Exercise 1 of 3
                  style: const TextStyle(
                    color: Colors.black, // 改为黑色文字
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Training Session', // 简化显示
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // 移除设置按钮
          const SizedBox(width: 48), // 保持布局平衡
        ],
      ),
    );
  }

  Widget _buildVideoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[100], // 改为浅灰色背景，保持与白色主题的一致性
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _buildSimulatedVideoPlayer(),
      ),
    );
  }

  Widget _buildSimulatedVideoPlayer() {
    return AnimatedBuilder(
      animation: Listenable.merge([_videoScaleAnimation, _videoColorAnimation]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey[50]!, // 浅灰色渐变
                Colors.grey[100]!,
              ],
            ),
          ),
          child: Stack(
            children: [
              // 视频内容区域
              if (_isPlaying)
                _buildAnimatedVideoContent()
              else
                _buildVideoThumbnail(),

              // 播放控制覆盖层
              if (!_isPlaying || _isPaused)
                _buildVideoOverlay(),

              // Windows平台提示
              if (Platform.isWindows)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Demo Mode',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedVideoContent() {
    return AnimatedBuilder(
      animation: _videoScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _videoScaleAnimation.value,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  Color(0xFFF5F5F5), // 浅灰色中心
                  Color(0xFFE0E0E0), // 稍深的灰色边缘
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.fitness_center,
                  color: Colors.grey[700], // 深灰色图标
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.exercise.name,
                  style: TextStyle(
                    color: Colors.grey[800], // 深灰色文字
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_arrow, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      const Text(
                        'PLAYING',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoThumbnail() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[100]!,
            Colors.grey[200]!,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
              border: Border.all(color: Colors.grey[400]!, width: 2),
            ),
            child: Icon(
              Icons.fitness_center,
              color: Colors.grey[700],
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.exercise.name,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Target: ${widget.exercise.primaryMuscle.displayName}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoOverlay() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.6),
            border: Border.all(color: const Color(0xFFFFD700), width: 2),
          ),
          child: Icon(
            _isPaused ? Icons.play_arrow : Icons.play_arrow,
            color: const Color(0xFFFFD700),
            size: 40,
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise Name
          Text(
            widget.exercise.name,
            style: TextStyle(
              color: Colors.grey[800], // 深灰色文字
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // Simplified info - just show current training
          Text(
            'Training Session', // 简化显示，不显示Set 1 of 3
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          // Target Muscles
          Row(
            children: [
              Icon(
                Icons.center_focus_strong,
                color: Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Target: ${widget.exercise.primaryMuscle.displayName}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Exercise Benefits
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[200]!,
              ),
            ),
            child: Text(
              widget.exercise.benefits,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          // Status Text
          Text(
            _isRestTime ? 'Rest Time' : _isPlaying ? 'Exercise Time' : 'Ready to Start',
            style: TextStyle(
              color: _isRestTime
                ? Colors.blue.shade600
                : _isPlaying
                  ? const Color(0xFFFFD700)
                  : Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 20),

          // Timer Circle
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isPlaying ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isRestTime
                        ? Colors.blue.shade300
                        : const Color(0xFFFFD700),
                      width: 4,
                    ),
                    color: Colors.grey[50],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$_currentTimeRemaining',
                          style: TextStyle(
                            color: _isRestTime
                              ? Colors.blue.shade600
                              : const Color(0xFFFFD700),
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'seconds',
                          style: TextStyle(
                            color: _isRestTime
                              ? Colors.blue.shade400
                              : Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
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

  Widget _buildControlsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 只保留主要控制按钮：播放/暂停和停止
              // Main Control Button
              _buildMainControlButton(),

              // Stop Button
              _buildControlButton(
                icon: Icons.stop,
                label: 'Stop',
                onPressed: _stopExercise,
                color: Colors.red.shade400,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Reward Preview - 简化为单次训练完成
          if (_isPlaying)
            _buildRewardPreview(),
        ],
      ),
    );
  }

  Widget _buildRewardPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD700).withOpacity(0.1),
            const Color(0xFFFFA500).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_giftcard,
            color: Color(0xFFFFD700),
            size: 20,
          ),
          SizedBox(width: 8),
          Text(
            'Complete this set to earn a reward card!',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainControlButton() {
    IconData icon;
    String label;
    VoidCallback onPressed;

    if (!_isPlaying) {
      icon = Icons.play_arrow;
      label = 'Start';
      onPressed = _startExercise;
    } else if (_isPaused) {
      icon = Icons.play_arrow;
      label = 'Resume';
      onPressed = _resumeExercise;
    } else {
      icon = Icons.pause;
      label = 'Pause';
      onPressed = _pauseExercise;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(35),
              onTap: onPressed,
              child: Center(
                child: Icon(
                  icon,
                  color: Colors.black,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFFFD700),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

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
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
            border: Border.all(color: color, width: 2),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: color, size: 20),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
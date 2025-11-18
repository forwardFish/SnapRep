import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../core/models/exercise.dart';
import 'professional_workout_video_page_v2.dart';

/// 专业训练视频页面
/// 包含视频播放、动作指导、计时器等功能
class ProfessionalWorkoutVideoPage extends StatefulWidget {
  final Exercise exercise;
  final List<Exercise> exercises;
  final int currentExerciseIndex;

  const ProfessionalWorkoutVideoPage({
    super.key,
    required this.exercise,
    required this.exercises,
    this.currentExerciseIndex = 0,
  });

  @override
  State<ProfessionalWorkoutVideoPage> createState() => _ProfessionalWorkoutVideoPageState();
}

class _ProfessionalWorkoutVideoPageState extends State<ProfessionalWorkoutVideoPage>
    with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  late AnimationController _timerController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // 训练状态
  bool _isPlaying = false;
  bool _isPaused = false;
  bool _isVideoLoaded = false;
  int _currentSet = 1;
  int _totalSets = 3;
  int _exerciseTimeSeconds = 30;
  int _restTimeSeconds = 10;
  int _currentTimeRemaining = 30;
  bool _isRestTime = false;

  // 模拟视频URL列表 - 实际项目中应该从exercise.videoUrl获取
  final List<String> _sampleVideoUrls = [
    'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
  ];

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _initializeAnimations();
    _startTimer();
  }

  void _initializeVideo() {
    // 使用示例视频URL，实际项目中应该使用 widget.exercise.videoUrl
    final videoUrl = _sampleVideoUrls[widget.currentExerciseIndex % _sampleVideoUrls.length];

    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

    _videoController.initialize().then((_) {
      setState(() {
        _isVideoLoaded = true;
      });

      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: false,
        looping: true,
        showControls: true,
        showOptions: false,
        showControlsOnInitialize: false,
        aspectRatio: 16 / 9,
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
            ),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Video loading error:\n$errorMessage',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      );
    }).catchError((error) {
      debugPrint('Video initialization error: $error');
      setState(() {
        _isVideoLoaded = false;
      });
    });
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

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
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
    if (_isRestTime) {
      // 休息完成，开始下一组或下一个动作
      setState(() {
        _isRestTime = false;
        _currentTimeRemaining = _exerciseTimeSeconds;

        if (_currentSet < _totalSets) {
          _currentSet++;
          _timerController.reset();
          _timerController.duration = Duration(seconds: _exerciseTimeSeconds);
        } else {
          // 完成当前动作，跳转到下一个动作或结束训练
          _nextExercise();
        }
      });
    } else {
      // 动作完成，开始休息
      setState(() {
        _isRestTime = true;
        _currentTimeRemaining = _restTimeSeconds;
        _timerController.reset();
        _timerController.duration = Duration(seconds: _restTimeSeconds);
        _timerController.forward();
      });
    }
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
    _videoController.play();
    HapticFeedback.lightImpact();
  }

  void _pauseExercise() {
    setState(() {
      _isPaused = true;
    });
    _timerController.stop();
    _videoController.pause();
    HapticFeedback.lightImpact();
  }

  void _resumeExercise() {
    setState(() {
      _isPaused = false;
    });
    _timerController.forward();
    _videoController.play();
    HapticFeedback.lightImpact();
  }

  void _stopExercise() {
    _timerController.stop();
    _timerController.reset();
    _videoController.pause();
    setState(() {
      _isPlaying = false;
      _isPaused = false;
      _currentTimeRemaining = _exerciseTimeSeconds;
      _currentSet = 1;
      _isRestTime = false;
    });
  }

  void _showWorkoutCompleteDialog() {
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
            Text(
              'Workout Complete!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Congratulations! You have completed your workout session.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to previous screen
            },
            child: const Text(
              'Done',
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
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(),

            // Video Player Section
            _buildVideoSection(),

            // Exercise Info Section
            _buildExerciseInfoSection(),

            // Timer Section
            _buildTimerSection(),

            // Controls Section
            _buildControlsSection(),
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
              color: Colors.white,
              size: 24,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Exercise ${widget.currentExerciseIndex + 1} of ${widget.exercises.length}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: (widget.currentExerciseIndex + 1) / widget.exercises.length,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                  minHeight: 3,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.settings,
              color: Colors.white70,
              size: 24,
            ),
          ),
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
        color: Colors.black,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _isVideoLoaded && _chewieController != null
            ? Chewie(controller: _chewieController!)
            : Container(
                color: Colors.black,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading exercise video...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildExerciseInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise Name
          Text(
            widget.exercise.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // Set Info
          Text(
            'Set $_currentSet of $_totalSets',
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          // Target Muscles
          Row(
            children: [
              const Icon(
                Icons.center_focus_strong,
                color: Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Target: ${widget.exercise.primaryMuscle.displayName}',
                style: const TextStyle(
                  color: Colors.white70,
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
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Text(
              widget.exercise.benefits,
              style: const TextStyle(
                color: Colors.white70,
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
                ? Colors.blue.shade300
                : _isPlaying
                  ? const Color(0xFFFFD700)
                  : Colors.white70,
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
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isRestTime
                        ? Colors.blue.shade300
                        : const Color(0xFFFFD700),
                      width: 4,
                    ),
                    color: Colors.white.withOpacity(0.05),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$_currentTimeRemaining',
                          style: TextStyle(
                            color: _isRestTime
                              ? Colors.blue.shade300
                              : const Color(0xFFFFD700),
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'seconds',
                          style: TextStyle(
                            color: _isRestTime
                              ? Colors.blue.shade300
                              : Colors.white70,
                            fontSize: 16,
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
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Previous Exercise Button
          if (widget.currentExerciseIndex > 0)
            _buildControlButton(
              icon: Icons.skip_previous,
              label: 'Previous',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfessionalWorkoutVideoPageV2(
                      exercise: widget.exercises[widget.currentExerciseIndex - 1],
                      exercises: widget.exercises,
                      currentExerciseIndex: widget.currentExerciseIndex - 1,
                    ),
                  ),
                );
              },
              color: Colors.white54,
            ),

          // Main Control Button
          _buildMainControlButton(),

          // Next Exercise Button
          if (widget.currentExerciseIndex < widget.exercises.length - 1)
            _buildControlButton(
              icon: Icons.skip_next,
              label: 'Next',
              onPressed: _nextExercise,
              color: Colors.white54,
            ),

          // Stop Button
          _buildControlButton(
            icon: Icons.stop,
            label: 'Stop',
            onPressed: _stopExercise,
            color: Colors.red.shade400,
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

    return Container(
      width: 80,
      height: 80,
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
          borderRadius: BorderRadius.circular(40),
          onTap: onPressed,
          child: Center(
            child: Icon(
              icon,
              color: Colors.black,
              size: 36,
            ),
          ),
        ),
      ),
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
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
            border: Border.all(color: color, width: 2),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: color, size: 24),
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
}
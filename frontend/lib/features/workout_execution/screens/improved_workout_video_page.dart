import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../core/models/exercise.dart';
import '../../../core/config/api_config.dart';

/// 改进版视频播放页面
/// 特性：
/// - 显示视频缩略图（第一帧）
/// - 大播放按钮覆盖层
/// - 点击后开始播放
/// - 使用 video_filename 从后端加载
class ImprovedWorkoutVideoPage extends StatefulWidget {
  final Exercise exercise;
  final List<Exercise> exercises;
  final int currentExerciseIndex;

  const ImprovedWorkoutVideoPage({
    super.key,
    required this.exercise,
    required this.exercises,
    this.currentExerciseIndex = 0,
  });

  @override
  State<ImprovedWorkoutVideoPage> createState() => _ImprovedWorkoutVideoPageState();
}

class _ImprovedWorkoutVideoPageState extends State<ImprovedWorkoutVideoPage>
    with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  late AnimationController _timerController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // 视频播放状态
  bool _isVideoInitialized = false;
  bool _isVideoPlaying = false;
  bool _showPlayButton = true;
  bool _isLoading = true;
  String? _errorMessage;

  // 训练状态
  int _currentSet = 1;
  int _totalSets = 3;
  int _exerciseTimeSeconds = 30;
  int _restTimeSeconds = 10;
  int _currentTimeRemaining = 30;
  bool _isRestTime = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _initializeAnimations();
  }

  void _initializeVideo() {
    // 从 Exercise 模型获取视频信息
    // demoVideoUrl 可能是:
    // 1. 完整URL (https://...)
    // 2. 相对路径 (/api/v1/assets/videos/xxx.mp4)
    // 3. 仅文件名 (neck_stretch.mp4)
    final demoVideoUrl = widget.exercise.demoVideoUrl;

    if (demoVideoUrl == null || demoVideoUrl.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No video available for this exercise';
      });
      return;
    }

    // 构建完整视频URL
    String videoUrl;
    if (demoVideoUrl.startsWith('http://') || demoVideoUrl.startsWith('https://')) {
      // 已经是完整URL
      videoUrl = demoVideoUrl;
    } else if (demoVideoUrl.startsWith('/api/')) {
      // 相对路径,添加baseUrl
      videoUrl = '${ApiConfig.baseUrl}$demoVideoUrl';
    } else {
      // 仅文件名,构建完整API路径
      videoUrl = '${ApiConfig.baseUrl}/api/v1/assets/videos/$demoVideoUrl';
    }

    debugPrint('📹 Loading video from: $videoUrl');

    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

    _videoController.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _isLoading = false;
        });

        // 创建 Chewie 控制器
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: false, // 不自动播放，等用户点击
          looping: true,
          showControls: true,
          showOptions: false,
          aspectRatio: _videoController.value.aspectRatio,
          placeholder: _buildThumbnailWithPlayButton(), // 显示缩略图
          materialProgressColors: ChewieProgressColors(
            playedColor: const Color(0xFFFFD700),
            handleColor: const Color(0xFFFFD700),
            backgroundColor: Colors.grey.shade800,
            bufferedColor: Colors.grey.shade700,
          ),
        );

        // 监听播放状态
        _videoController.addListener(_videoListener);

        debugPrint('✅ Video initialized successfully');
      }
    }).catchError((error) {
      debugPrint('❌ Video initialization error: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load video: $error';
        });
      }
    });
  }

  void _videoListener() {
    if (_videoController.value.isPlaying != _isVideoPlaying) {
      setState(() {
        _isVideoPlaying = _videoController.value.isPlaying;
        _showPlayButton = !_isVideoPlaying;
      });
    }
  }

  void _initializeAnimations() {
    _timerController = AnimationController(
      duration: Duration(seconds: _exerciseTimeSeconds),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  /// 构建缩略图 + 播放按钮覆盖层
  Widget _buildThumbnailWithPlayButton() {
    return Container(
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 缩略图显示 - 优先级：视频第一帧 > thumbnailUrl > demoImageUrl > 占位符
          if (_isVideoInitialized)
            // 使用视频第一帧
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: VideoPlayer(_videoController),
              ),
            )
          else if (widget.exercise.thumbnailUrl != null && widget.exercise.thumbnailUrl!.isNotEmpty)
            // 使用缩略图URL
            Image.network(
              widget.exercise.thumbnailUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                // 如果缩略图加载失败，尝试使用示例图片
                if (widget.exercise.demoImageUrl != null && widget.exercise.demoImageUrl!.isNotEmpty) {
                  return Image.network(
                    widget.exercise.demoImageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) => _buildPlaceholderThumbnail(),
                  );
                }
                return _buildPlaceholderThumbnail();
              },
            )
          else if (widget.exercise.demoImageUrl != null && widget.exercise.demoImageUrl!.isNotEmpty)
            // 使用示例图片
            Image.network(
              widget.exercise.demoImageUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) => _buildPlaceholderThumbnail(),
            )
          else
            // 使用占位符
            _buildPlaceholderThumbnail(),

          // 半透明黑色遮罩
          if (_showPlayButton)
            Container(
              color: Colors.black.withOpacity(0.3),
            ),

          // 大播放按钮
          if (_showPlayButton)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      size: 48,
                      color: Colors.black,
                    ),
                  ),
                );
              },
            ),

          // 点击区域
          if (_showPlayButton)
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _playVideo,
                  child: Container(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _playVideo() {
    if (_isVideoInitialized && !_isVideoPlaying) {
      _videoController.play();
      setState(() {
        _showPlayButton = false;
        _isVideoPlaying = true;
      });
      _startTimer();
    }
  }

  void _pauseVideo() {
    if (_isVideoInitialized && _isVideoPlaying) {
      _videoController.pause();
      _timerController.stop();
    }
  }

  void _startTimer() {
    _timerController.forward(from: 0);
    _timerController.addListener(() {
      if (mounted) {
        setState(() {
          final progress = _timerController.value;
          _currentTimeRemaining =
              (_exerciseTimeSeconds * (1 - progress)).ceil();
        });
      }
    });

    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _handleSetComplete();
      }
    });
  }

  void _handleSetComplete() {
    if (_currentSet < _totalSets) {
      setState(() {
        _currentSet++;
        _isRestTime = true;
        _currentTimeRemaining = _restTimeSeconds;
      });
      _pauseVideo();
      _startRestTimer();
    } else {
      _handleWorkoutComplete();
    }
  }

  void _startRestTimer() {
    // 休息计时逻辑
    Future.delayed(Duration(seconds: _restTimeSeconds), () {
      if (mounted) {
        setState(() {
          _isRestTime = false;
          _currentTimeRemaining = _exerciseTimeSeconds;
        });
        _playVideo();
      }
    });
  }

  void _handleWorkoutComplete() {
    debugPrint('✅ Workout completed!');
    _pauseVideo();
    // TODO: 显示完成页面或奖励
  }

  @override
  void dispose() {
    _videoController.removeListener(_videoListener);
    _videoController.dispose();
    _chewieController?.dispose();
    _timerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.exercise.name,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return Column(
      children: [
        // 视频播放区域
        Expanded(
          flex: 3,
          child: Container(
            color: Colors.black,
            child: _chewieController != null
                ? Chewie(controller: _chewieController!)
                : _buildThumbnailWithPlayButton(),
          ),
        ),

        // 训练信息区域
        Expanded(
          flex: 1,
          child: Container(
            color: const Color(0xFF1A1A1A),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 组数显示
                Text(
                  'Set $_currentSet / $_totalSets',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // 倒计时
                Text(
                  _isRestTime ? 'Rest: $_currentTimeRemaining"' : '$_currentTimeRemaining"',
                  style: TextStyle(
                    color: _isRestTime ? Colors.orange : const Color(0xFFFFD700),
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // 进度条
                LinearProgressIndicator(
                  value: 1 - (_timerController.value),
                  backgroundColor: Colors.grey.shade800,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFFFD700),
                  ),
                  minHeight: 8,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
          ),
          SizedBox(height: 24),
          Text(
            'Loading video...',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _initializeVideo();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建占位符缩略图（当视频和图片都不可用时）
  Widget _buildPlaceholderThumbnail() {
    return Container(
      color: Colors.grey.shade900,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 80,
              color: Colors.grey.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              widget.exercise.name,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

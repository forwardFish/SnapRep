import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class FullscreenVideoPlayer extends StatefulWidget {
  final String videoPath;
  final String title;

  const FullscreenVideoPlayer({
    super.key,
    required this.videoPath,
    required this.title,
  });

  @override
  State<FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<FullscreenVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _showControls = true;
  String? _errorMessage;
  bool _isWindows = false;

  @override
  void initState() {
    super.initState();
    _isWindows = !kIsWeb && Platform.isWindows;

    // Force landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Hide system UI for fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    if (_isWindows) {
      // Windows: Use system player
      _launchSystemPlayer();
    } else {
      // Mobile: Use in-app video player
      _initializeVideoPlayer();
    }
  }

  // For Windows: Launch video with system player
  Future<void> _launchSystemPlayer() async {
    try {
      // Copy asset to temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = widget.videoPath.split('/').last;
      final tempVideoPath = '${tempDir.path}/$fileName';

      debugPrint('Copying video from ${widget.videoPath} to $tempVideoPath');

      // Load asset and write to temp file
      final byteData = await rootBundle.load(widget.videoPath);
      final buffer = byteData.buffer;
      await File(tempVideoPath).writeAsBytes(
        buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
      );

      debugPrint('Video copied successfully. Opening with system player...');

      // Launch video file with system default player
      final uri = Uri.file(tempVideoPath);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        // Go back after launching
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Could not launch video player';
          });
        }
      }
    } catch (e) {
      debugPrint('Error launching video: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  // For Mobile: Initialize in-app video player
  Future<void> _initializeVideoPlayer() async {
    try {
      debugPrint('Initializing video from: ${widget.videoPath}');

      _controller = VideoPlayerController.asset(widget.videoPath);

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // Auto-play
        _controller!.play();

        // Auto-hide controls after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _controller!.value.isPlaying) {
            setState(() {
              _showControls = false;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    // Restore portrait orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls && _controller != null && _controller!.value.isPlaying) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _controller!.value.isPlaying) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // Windows: Show loading/launching screen
    if (_isWindows) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(widget.title, style: const TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: _errorMessage != null
              ? _buildErrorWidget()
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Opening video in system player...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '(Windows does not support in-app video playback)',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
        ),
      );
    }

    // Mobile: Show in-app video player
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video Player
            if (_isInitialized && _controller != null)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              )
            else if (_errorMessage != null)
              _buildErrorWidget()
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Controls overlay
            if (_showControls && _isInitialized) ...[
              // Top bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Center play/pause button
              Center(
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _controller!.value.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 50,
                      color: const Color(0xFF2C2C2E),
                    ),
                  ),
                ),
              ),

              // Bottom progress bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: ValueListenableBuilder(
                      valueListenable: _controller!,
                      builder: (context, VideoPlayerValue value, child) {
                        final position = value.position;
                        final duration = value.duration;
                        final durationMs = duration.inMilliseconds.toDouble();
                        final positionMs = position.inMilliseconds.toDouble();

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (durationMs > 0)
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor: Colors.white.withOpacity(0.3),
                                  thumbColor: Colors.white,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  trackHeight: 3,
                                ),
                                child: Slider(
                                  value: positionMs.clamp(0, durationMs),
                                  min: 0,
                                  max: durationMs,
                                  onChanged: (value) {
                                    _controller!.seekTo(Duration(milliseconds: value.toInt()));
                                  },
                                ),
                              ),
                            if (durationMs > 0)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(position),
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                    ),
                                    Text(
                                      _formatDuration(duration),
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Failed to load video',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

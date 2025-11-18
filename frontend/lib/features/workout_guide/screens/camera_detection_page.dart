import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/workout_guide_provider.dart';
import '../../../routes/app_routes.dart';

/// Scene Detection Page - New Step 1
/// Users can choose between AI camera detection or manual selection
class CameraDetectionPage extends StatefulWidget {
  const CameraDetectionPage({super.key});

  @override
  State<CameraDetectionPage> createState() => _CameraDetectionPageState();
}

class _CameraDetectionPageState extends State<CameraDetectionPage>
    with TickerProviderStateMixin {
  // Detection mode
  String _detectionMode = 'selection'; // 'camera' or 'selection'

  // Camera related
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isAnalyzing = false;
  bool _analysisComplete = false;
  String? _detectedScene;
  List<String> _detectedEquipment = [];

  // Manual selection related
  String? _selectedScenario;
  List<String> _selectedEquipment = [];

  // Animation controllers
  late AnimationController _scanAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _scanAnimation;
  late Animation<double> _pulseAnimation;

  // Mock AI detection results for demo
  final Map<String, Map<String, dynamic>> _mockDetectionResults = {
    'home': {
      'scene': 'home',
      'sceneName': 'Living Space',
      'sceneDescription': 'Comfortable home environment detected',
      'equipment': ['chair', 'wall', 'yoga_mat'],
      'confidence': 0.94,
    },
    'gym': {
      'scene': 'gym',
      'sceneName': 'Fitness Center',
      'sceneDescription': 'Professional gym environment detected',
      'equipment': ['dumbbells', 'resistance_band', 'yoga_mat'],
      'confidence': 0.89,
    },
    'office': {
      'scene': 'office',
      'sceneName': 'Workplace',
      'sceneDescription': 'Office environment detected',
      'equipment': ['chair', 'wall'],
      'confidence': 0.87,
    },
  };

  // Manual selection data
  final List<Map<String, dynamic>> _scenarios = [
    {
      'id': 'home',
      'badge': 'HOME',
      'title': 'Living Space',
      'description': 'Comfortable environment\nPersonal space workout',
      'color': Color(0xFF3498DB),
      'imageUrl': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
    },
    {
      'id': 'office',
      'badge': 'OFFICE',
      'title': 'Workplace',
      'description': 'Professional setting\nQuick desk exercises',
      'color': Color(0xFF9B59B6),
      'imageUrl': 'https://images.unsplash.com/photo-1497366216548-37526070297c?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
    },
    {
      'id': 'gym',
      'badge': 'GYM',
      'title': 'Fitness Center',
      'description': 'Professional equipment\nFull workout space',
      'color': Color(0xFF27AE60),
      'imageUrl': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
    },
    {
      'id': 'travel',
      'badge': 'TRAVEL',
      'title': 'On the Go',
      'description': 'Hotel or limited space\nBodyweight exercises',
      'color': Color(0xFFE67E22),
      'imageUrl': 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
    },
  ];

  final List<Map<String, dynamic>> _equipment = [
    {
      'id': 'chair',
      'title': 'Chair',
      'description': 'Office or dining chair',
      'icon': '🪑',
      'color': const Color(0xFF8E44AD),
      'imageUrl': 'https://images.unsplash.com/photo-1506439773649-6e0eb8cfb237?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
    },
    {
      'id': 'wall',
      'title': 'Wall Space',
      'description': 'Clear wall area',
      'icon': '🧱',
      'color': const Color(0xFF34495E),
      'imageUrl': 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
    },
    {
      'id': 'hands_free',
      'title': 'Bodyweight',
      'description': 'No equipment needed',
      'icon': '💪',
      'color': const Color(0xFF27AE60),
      'imageUrl': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
    },
    {
      'id': 'resistance_band',
      'title': 'Resistance Band',
      'description': 'Elastic exercise band',
      'icon': '🎯',
      'color': const Color(0xFFE74C3C),
      'imageUrl': 'https://images.unsplash.com/photo-1598300042247-d088f8ab3a91?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
    },
    {
      'id': 'dumbbells',
      'title': 'Dumbbells',
      'description': 'Free weights',
      'icon': '🏋️',
      'color': const Color(0xFF2C3E50),
      'imageUrl': 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
    },
    {
      'id': 'yoga_mat',
      'title': 'Yoga Mat',
      'description': 'Exercise mat',
      'icon': '🧘',
      'color': const Color(0xFF9B59B6),
      'imageUrl': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _setupAnimations();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _scanAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanAnimationController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseAnimationController, curve: Curves.easeInOut),
    );

    _pulseAnimationController.repeat(reverse: true);
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _controller = CameraController(
          _cameras[0],
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      // For simulator/desktop testing, show mock interface
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _detectionMode == 'camera' ? Colors.black : Colors.white,
      body: _detectionMode == 'camera' ? _buildCameraMode() : _buildSelectionMode(),
    );
  }

  Widget _buildCameraMode() {
    return Stack(
      children: [
        // Camera preview or mock interface
        _buildCameraPreview(),

        // UI Overlay
        _buildCameraUIOverlay(),
      ],
    );
  }

  Widget _buildSelectionMode() {
    return SafeArea(
      child: Column(
        children: [
          // App bar
          _buildSelectionAppBar(),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress indicator
                  _buildProgressIndicator(),

                  const SizedBox(height: 24),

                  // Title section
                  _buildSelectionTitleSection(),

                  const SizedBox(height: 32),

                  // Content sections
                  Expanded(
                    child: _buildSelectionContent(),
                  ),
                ],
              ),
            ),
          ),

          // Bottom button area
          _buildSelectionBottomButton(),
        ],
      ),
    );
  }

  Widget _buildSelectionAppBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),

          const Spacer(),

          // Title
          const Text(
            'Workout Guide',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const Spacer(),

          // Mode switch button
          GestureDetector(
            onTap: () {
              setState(() {
                _detectionMode = 'camera';
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFFD700),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.camera_alt,
                    color: Color(0xFFFFD700),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'AI Scan',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
        ),
      );
    }

    if (_controller != null && _controller!.value.isInitialized) {
      return SizedBox.expand(
        child: CameraPreview(_controller!),
      );
    }

    // Mock camera view for testing
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF2D2D2D),
            const Color(0xFF1A1A1A),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam,
              size: 120,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Camera Preview',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '(Demo Mode)',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraUIOverlay() {
    return SafeArea(
      child: Column(
        children: [
          // Top app bar
          _buildCameraTopAppBar(),

          // Main content
          Expanded(
            child: _buildCameraMainContent(),
          ),

          // Bottom controls
          _buildCameraBottomControls(),
        ],
      ),
    );
  }

  Widget _buildCameraTopAppBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),

          const Spacer(),

          // Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Text(
              'AI Scene Detection',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const Spacer(),

          // Mode switch button
          GestureDetector(
            onTap: () {
              setState(() {
                _detectionMode = 'selection';
                _isAnalyzing = false;
                _analysisComplete = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFD700),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.touch_app,
                color: Color(0xFFFFD700),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraMainContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),

          const SizedBox(height: 32),

          // Step info
          _buildCameraStepInfo(),

          const SizedBox(height: 40),

          // Detection viewfinder
          Expanded(
            child: _buildDetectionViewfinder(),
          ),

          const SizedBox(height: 20),

          // Analysis results
          if (_analysisComplete) _buildAnalysisResults(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: const Color(0xFFFFD700),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: const Color(0xFFE0E0E0),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: const Color(0xFFE0E0E0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFFFD700),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '1',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'STEP 1',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Choose your\nworkout space',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            height: 1.2,
            color: Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select your location and available equipment',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCameraStepInfo() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFFFD700),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '1',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'STEP 1',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Scan your\nenvironment',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            height: 1.2,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Point your camera around to detect your workout space and available equipment',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scenarios',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _scenarios.length,
              itemBuilder: (context, index) {
                final scenario = _scenarios[index];
                return Container(
                  width: 140,
                  margin: EdgeInsets.only(
                    right: index < _scenarios.length - 1 ? 16 : 0,
                  ),
                  child: _buildScenarioCard(scenario),
                );
              },
            ),
          ),

          const SizedBox(height: 40),

          // Equipment Section
          const Text(
            'Equipment',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _equipment.length,
              itemBuilder: (context, index) {
                final equipment = _equipment[index];
                return Container(
                  width: 120,
                  margin: EdgeInsets.only(
                    right: index < _equipment.length - 1 ? 12 : 0,
                  ),
                  child: _buildEquipmentCard(equipment),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionViewfinder() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Scanning frame
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              border: Border.all(
                color: _isAnalyzing
                    ? const Color(0xFFFFD700)
                    : Colors.white.withOpacity(0.5),
                width: 3,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                // Corner indicators
                _buildCornerIndicator(Alignment.topLeft),
                _buildCornerIndicator(Alignment.topRight),
                _buildCornerIndicator(Alignment.bottomLeft),
                _buildCornerIndicator(Alignment.bottomRight),

                // Scanning line animation
                if (_isAnalyzing) _buildScanLine(),

                // Center AI icon
                Center(
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isAnalyzing ? _pulseAnimation.value : 1.0,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: const Color(0xFFFFD700),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.smart_toy,
                            color: Color(0xFFFFD700),
                            size: 40,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Analysis overlay
          if (_isAnalyzing)
            Positioned(
              bottom: -50,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'AI Analyzing...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCornerIndicator(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFFFD700),
            width: 3,
          ),
        ),
      ),
    );
  }

  Widget _buildScanLine() {
    return AnimatedBuilder(
      animation: _scanAnimation,
      builder: (context, child) {
        return Positioned(
          top: _scanAnimation.value * 250,
          left: 10,
          right: 10,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.5),
                  blurRadius: 6,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalysisResults() {
    if (_detectedScene == null) return const SizedBox.shrink();

    final result = _mockDetectionResults[_detectedScene]!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFFFFD700),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Detection Complete',
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            'Scene: ${result['sceneName']}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),

          Text(
            result['sceneDescription'],
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Confidence: ${(result['confidence'] * 100).toInt()}%',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Detected Equipment:',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _detectedEquipment.map((equipment) =>
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFD700),
                    width: 1,
                  ),
                ),
                child: Text(
                  equipment,
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraBottomControls() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Capture button
          if (!_isAnalyzing && !_analysisComplete)
            GestureDetector(
              onTap: _startAnalysis,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Continue button
          if (_analysisComplete)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onContinuePressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: const Color(0xFFFFD700).withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  minimumSize: const Size(0, 56),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Help text
          Text(
            _isAnalyzing
                ? 'Analyzing your environment...'
                : _analysisComplete
                    ? 'Tap Continue to proceed with your detected setup'
                    : 'Tap the camera button to analyze your workout space',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBottomButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_selectedScenario != null) ? _onSelectionContinuePressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: (_selectedScenario != null) ? const Color(0xFFFFD700) : Colors.grey.shade300,
              foregroundColor: (_selectedScenario != null) ? Colors.white : Colors.grey.shade500,
              elevation: (_selectedScenario != null) ? 8 : 0,
              shadowColor: (_selectedScenario != null) ? const Color(0xFFFFD700).withOpacity(0.3) : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              minimumSize: const Size(0, 56),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScenarioCard(Map<String, dynamic> scenario) {
    final isSelected = _selectedScenario == scenario['id'];

    return GestureDetector(
      onTap: () => _onScenarioSelected(scenario['id']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD700) : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(scenario['imageUrl']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: scenario['color'].withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          scenario['badge'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Title
                      Text(
                        scenario['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 6,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 2),

                      // Description
                      Text(
                        scenario['description'],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 10,
                          height: 1.3,
                          shadows: const [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEquipmentCard(Map<String, dynamic> equipment) {
    final isSelected = _selectedEquipment.contains(equipment['id']);

    return GestureDetector(
      onTap: () => _onEquipmentToggled(equipment['id']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD700) : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(equipment['imageUrl']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: equipment['color'].withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          equipment['icon'],
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Title
                      Text(
                        equipment['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 6,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 2),

                      // Description
                      Text(
                        equipment['description'],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 9,
                          height: 1.3,
                          shadows: const [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _switchCamera() async {
    if (_cameras.length > 1) {
      final currentCamera = _controller?.description;
      final newCamera = _cameras.firstWhere(
        (camera) => camera != currentCamera,
        orElse: () => _cameras[0],
      );

      await _controller?.dispose();
      _controller = CameraController(newCamera, ResolutionPreset.high);
      await _controller!.initialize();

      if (mounted) {
        setState(() {});
      }
    }
  }

  void _startAnalysis() {
    if (_isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _analysisComplete = false;
    });

    _scanAnimationController.repeat();

    // Simulate AI analysis
    Future.delayed(const Duration(seconds: 3), () {
      // Mock detection results - in real app this would be AI analysis
      final scenes = ['home', 'gym', 'office'];
      final randomScene = scenes[DateTime.now().millisecond % scenes.length];
      final result = _mockDetectionResults[randomScene]!;

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _analysisComplete = true;
          _detectedScene = result['scene'];
          _detectedEquipment = List<String>.from(result['equipment']);
        });

        _scanAnimationController.stop();
        _scanAnimationController.reset();
      }
    });
  }

  void _onScenarioSelected(String scenarioId) {
    setState(() {
      _selectedScenario = scenarioId;
    });
  }

  void _onEquipmentToggled(String equipmentId) {
    setState(() {
      if (_selectedEquipment.contains(equipmentId)) {
        _selectedEquipment.remove(equipmentId);
      } else {
        _selectedEquipment.add(equipmentId);
      }
    });
  }

  void _onContinuePressed() {
    if (_detectedScene != null && _detectedEquipment.isNotEmpty) {
      // Navigate to step 2 with AI detection data
      AppRoutes.navigateToWorkoutGuideStep2(
        context,
        guideData: {
          'detectionMethod': 'ai_camera',
          'detectedScene': _detectedScene,
          'detectedEquipment': _detectedEquipment,
        },
      );
    }
  }

  void _onSelectionContinuePressed() {
    if (_selectedScenario != null) {
      // Navigate to step 2 with manual selection data
      AppRoutes.navigateToWorkoutGuideStep2(
        context,
        guideData: {
          'detectionMethod': 'manual_selection',
          'detectedScene': _selectedScenario,
          'detectedEquipment': _selectedEquipment,
        },
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'dart:async';

/// SnapRep 启动页面
/// 高级UI设计，包含品牌动画和加载进度
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _loadingController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _loadingProgress;

  String _loadingText = '正在初始化健身引擎...';
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startLoadingSequence();
  }

  void _setupAnimations() {
    // Logo动画控制器 (1.5秒)
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    // 文字动画控制器 (1.2秒)
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    // 加载进度动画控制器 (3秒)
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _loadingProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeOut),
    );

    _loadingProgress.addListener(() {
      setState(() {
        _currentProgress = _loadingProgress.value;
      });
    });

    // 启动动画
    Future.delayed(const Duration(milliseconds: 300), () {
      _logoController.forward();
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      _textController.forward();
    });
  }

  void _startLoadingSequence() async {
    // 延迟2秒后开始加载动画
    await Future.delayed(const Duration(milliseconds: 2000));
    _loadingController.forward();

    // 模拟加载过程中的文字变化
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _loadingText = '正在加载运动数据库...';
        });
      }
    });

    Timer(const Duration(milliseconds: 4500), () {
      if (mounted) {
        setState(() {
          _loadingText = '准备就绪！';
        });
      }
    });

    // 5秒后跳转到主页
    Timer(const Duration(milliseconds: 5000), () {
      if (mounted) {
        _navigateToHome();
      }
    });
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFFf093fb),
              Color(0xFFf5576c),
              Color(0xFF4facfe),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // 浮动粒子背景
            _buildFloatingParticles(),

            // 主内容
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo区域
                  _buildLogoSection(),

                  const SizedBox(height: 48),

                  // 品牌文字
                  _buildBrandText(),

                  const SizedBox(height: 60),

                  // 加载指示器
                  _buildLoadingIndicator(),
                ],
              ),
            ),

            // 版本号
            _buildVersionInfo(),

            // 底部品牌标识
            _buildBottomBranding(),
          ],
        ),
      ),
    );
  }

  // 浮动粒子效果
  Widget _buildFloatingParticles() {
    return Stack(
      children: List.generate(5, (index) {
        return Positioned(
          top: (index * 137) % MediaQuery.of(context).size.height,
          left: (index * 89) % MediaQuery.of(context).size.width,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 6000 + index * 500),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -20 * (value > 0.5 ? 1 - value : value) * 2),
                child: Opacity(
                  opacity: value > 0.5 ? 1 - value : value,
                  child: Container(
                    width: 4 - index * 0.5,
                    height: 4 - index * 0.5,
                    decoration: BoxDecoration(
                      color: index % 2 == 0
                          ? const Color(0x4DFFD700)
                          : const Color(0x33FFFFFF),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
            onEnd: () {
              // 循环动画 - 这里可以添加循环逻辑
            },
          ),
        );
      }),
    );
  }

  // Logo区域
  Widget _buildLogoSection() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Opacity(
          opacity: _logoOpacity.value,
          child: Transform.scale(
            scale: _logoScale.value,
            child: Column(
              children: [
                // Logo图标
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: 1.05),
                  duration: const Duration(milliseconds: 3000),
                  curve: Curves.easeInOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFFD700),
                              Color(0xFFFFA500),
                              Color(0xFFFF7F50),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.3),
                              blurRadius: 40,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            '⚡',
                            style: TextStyle(
                              fontSize: 36,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 品牌文字
  Widget _buildBrandText() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return SlideTransition(
          position: _textSlide,
          child: Opacity(
            opacity: _textOpacity.value,
            child: Column(
              children: [
                // 品牌名称
                const Text(
                  'SnapRep',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 主标语
                const Text(
                  '随时随地健身',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // 副标语
                Text(
                  '60秒快拍锻炼，把身边物品变健身器材',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.7),
                    shadows: const [
                      Shadow(
                        color: Colors.black12,
                        blurRadius: 5,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 加载指示器
  Widget _buildLoadingIndicator() {
    return AnimatedOpacity(
      opacity: _currentProgress > 0 ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Column(
        children: [
          // 加载文字
          Text(
            _loadingText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 20),

          // 加载进度条
          Container(
            width: 240,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 240 * _currentProgress,
                height: 4,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFD700),
                      Color(0xFFFFA500),
                      Color(0xFFFF7F50),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 版本信息
  Widget _buildVersionInfo() {
    return Positioned(
      top: 40,
      right: 40,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 2000),
        builder: (context, value, child) {
          return Opacity(
            opacity: value * 0.5,
            child: const Text(
              'v1.0.0',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }

  // 底部品牌标识
  Widget _buildBottomBranding() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1800),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Column(
                children: [
                  Text(
                    'POWERED BY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.6),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 60,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'SNAPREP',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1a1a1a),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

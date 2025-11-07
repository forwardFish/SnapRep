import 'package:flutter/material.dart';
import 'dart:async';

/// SnapRep 启动页面 - 简洁版本
/// 参考HTML设计：上方"Fitness Anywhere"，下方Logo + SnapRep
/// 停留3秒后自动跳转到首页
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _topTextController;
  late AnimationController _logoController;
  late Animation<double> _topTextOpacity;
  late Animation<Offset> _topTextSlide;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _logoSlide;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAutoNavigation();
  }

  void _setupAnimations() {
    // 上方文字动画控制器
    _topTextController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _topTextOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _topTextController, curve: Curves.easeOut),
    );

    _topTextSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _topTextController, curve: Curves.easeOut));

    // Logo动画控制器
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    // 启动动画
    _topTextController.forward();

    Future.delayed(const Duration(milliseconds: 200), () {
      _logoController.forward();
    });
  }

  void _startAutoNavigation() {
    // 3秒后自动跳转到首页
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  @override
  void dispose() {
    _topTextController.dispose();
    _logoController.dispose();
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
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 上方区域 - "Fitness Anywhere"
                Expanded(
                  flex: 1,
                  child: _buildTopSection(),
                ),

                // 下方区域 - Logo + SnapRep
                Expanded(
                  flex: 1,
                  child: _buildBottomSection(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 上方区域 - "Fitness Anywhere"
  Widget _buildTopSection() {
    return AnimatedBuilder(
      animation: _topTextController,
      builder: (context, child) {
        return SlideTransition(
          position: _topTextSlide,
          child: Opacity(
            opacity: _topTextOpacity.value,
            child: const Center(
              child: Text(
                'Fitness Anywhere',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }

  // 下方区域 - Logo + SnapRep
  Widget _buildBottomSection() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return SlideTransition(
          position: _logoSlide,
          child: Opacity(
            opacity: _logoOpacity.value,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo容器
                  _buildSnapRepLogo(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // SnapRep Logo (SVG绘制版本)
  Widget _buildSnapRepLogo() {
    return SizedBox(
      width: 140,
      height: 42, // 根据SVG比例调整
      child: CustomPaint(
        painter: SnapRepLogoPainter(),
      ),
    );
  }
}

/// 自定义Logo绘制器
/// 绘制SnapRep Logo，包含圆形图标和文字
class SnapRepLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Logo图标部分 (左侧圆形)
    final iconCenter = Offset(size.height / 2, size.height / 2);
    final iconRadius = size.height * 0.43; // 稍小一点的半径

    // 绘制圆形背景渐变
    paint.shader = const LinearGradient(
      colors: [
        Color(0xFFFFD700), // 金黄色
        Color(0xFFFFA500), // 橙色
        Color(0xFFFF7F50), // 珊瑚色
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromCircle(center: iconCenter, radius: iconRadius));

    canvas.drawCircle(iconCenter, iconRadius, paint);

    // 绘制闪电符号
    paint.shader = null;
    paint.color = Colors.white;
    paint.style = PaintingStyle.fill;

    final lightningPath = Path();
    final centerX = iconCenter.dx;
    final centerY = iconCenter.dy;
    final scale = iconRadius / 18; // 缩放因子

    // 闪电路径 (参考SVG路径)
    lightningPath.moveTo(centerX - 8 * scale, centerY - 10 * scale);
    lightningPath.lineTo(centerX + 2 * scale, centerY - 2 * scale);
    lightningPath.lineTo(centerX - 2 * scale, centerY - 2 * scale);
    lightningPath.lineTo(centerX + 8 * scale, centerY + 10 * scale);
    lightningPath.lineTo(centerX - 2 * scale, centerY + 2 * scale);
    lightningPath.lineTo(centerX + 2 * scale, centerY + 2 * scale);
    lightningPath.close();

    canvas.drawPath(lightningPath, paint);

    // 绘制小圆点 (运动轨迹)
    paint.color = Colors.white.withOpacity(0.7);
    canvas.drawCircle(Offset(centerX + 10 * scale, centerY - 8 * scale), 1.5 * scale, paint);

    paint.color = Colors.white.withOpacity(0.5);
    canvas.drawCircle(Offset(centerX + 8 * scale, centerY + 8 * scale), 1 * scale, paint);

    paint.color = Colors.white.withOpacity(0.6);
    canvas.drawCircle(Offset(centerX - 10 * scale, centerY + 6 * scale), 1.2 * scale, paint);

    // 绘制"SnapRep"文字
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'SnapRep',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          fontFamily: 'SF Pro Display',
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    final textX = size.height + 20; // Logo右侧留出间距
    final textY = (size.height - textPainter.height) / 2 - 5; // 稍微上移
    textPainter.paint(canvas, Offset(textX, textY));

    // 绘制"FITNESS ANYWHERE"小标语
    final taglinePainter = TextPainter(
      text: TextSpan(
        text: 'FITNESS ANYWHERE',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w500,
          color: Colors.white.withOpacity(0.8),
          letterSpacing: 1,
          fontFamily: 'SF Pro Display',
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    taglinePainter.layout();
    final taglineX = textX;
    final taglineY = textY + textPainter.height + 2;
    taglinePainter.paint(canvas, Offset(taglineX, taglineY));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
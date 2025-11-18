import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/reward_card.dart';
import '../../../routes/app_routes.dart';

/// 奖励卡片展示页面
/// 当用户完成训练时显示的奖励卡片
class RewardCardDisplayPage extends StatefulWidget {
  final RewardCard rewardCard;
  final VoidCallback? onContinue;

  const RewardCardDisplayPage({
    super.key,
    required this.rewardCard,
    this.onContinue,
  });

  @override
  State<RewardCardDisplayPage> createState() => _RewardCardDisplayPageState();
}

class _RewardCardDisplayPageState extends State<RewardCardDisplayPage>
    with TickerProviderStateMixin {
  late AnimationController _cardController;
  late AnimationController _sparkleController;
  late AnimationController _bounceController;

  late Animation<double> _cardScale;
  late Animation<double> _cardOpacity;
  late Animation<double> _sparkleRotation;
  late Animation<double> _bounceAnimation;

  bool _showShareOptions = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();

    // 触发震动反馈
    HapticFeedback.heavyImpact();
  }

  void _initializeAnimations() {
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _cardScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.elasticOut,
    ));

    _cardOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _sparkleRotation = Tween<double>(
      begin: 0.0,
      end: 2.0,
    ).animate(_sparkleController);

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimations() {
    _cardController.forward();
    _sparkleController.repeat();

    // 延迟启动弹跳动画
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _bounceController.forward();
      }
    });
  }

  void _shareCard() {
    setState(() {
      _showShareOptions = true;
    });
    HapticFeedback.lightImpact();
  }

  void _hideShareOptions() {
    setState(() {
      _showShareOptions = false;
    });
  }

  void _shareToSocialMedia(String platform) {
    // 模拟分享功能
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Shared to $platform!'),
        backgroundColor: const Color(0xFFFFD700),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    _hideShareOptions();
    HapticFeedback.lightImpact();
  }

  void _downloadCard() {
    // 模拟下载功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Card saved to gallery!'),
        backgroundColor: Color(0xFFFFD700),
        behavior: SnackBarBehavior.floating,
      ),
    );
    HapticFeedback.lightImpact();
  }

  void _continue() {
    if (widget.onContinue != null) {
      widget.onContinue!();
    } else {
      AppRoutes.navigateToHome(context);
    }
  }

  @override
  void dispose() {
    _cardController.dispose();
    _sparkleController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 背景粒子效果
          _buildBackgroundParticles(),

          // 主要内容
          _buildMainContent(),

          // 分享选项覆盖层
          if (_showShareOptions) _buildShareOverlay(),
        ],
      ),
    );
  }

  Widget _buildBackgroundParticles() {
    return AnimatedBuilder(
      animation: _sparkleController,
      builder: (context, child) {
        return CustomPaint(
          painter: SparklesPainter(_sparkleRotation.value),
          size: MediaQuery.of(context).size,
        );
      },
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(),

            const SizedBox(height: 40),

            // Congratulations Text
            _buildCongratsText(),

            const SizedBox(height: 30),

            // Reward Card
            Expanded(
              child: Center(
                child: _buildRewardCard(),
              ),
            ),

            const SizedBox(height: 30),

            // Action Buttons
            _buildActionButtons(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: _continue,
          icon: const Icon(
            Icons.close,
            color: Colors.white,
            size: 28,
          ),
        ),
        const Text(
          'Reward Earned!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 48), // 平衡布局
      ],
    );
  }

  Widget _buildCongratsText() {
    return FadeTransition(
      opacity: _cardOpacity,
      child: Column(
        children: [
          const Text(
            '🎉 Congratulations! 🎉',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ve earned ${widget.rewardCard.points} points!',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard() {
    return AnimatedBuilder(
      animation: Listenable.merge([_cardScale, _cardOpacity, _bounceAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _cardScale.value * _bounceAnimation.value,
          child: Opacity(
            opacity: _cardOpacity.value,
            child: Container(
              width: 300,
              height: 400,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getCardColor(),
                    _getCardColor().withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getCardColor().withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // 卡片类型图标
                    _buildCardIcon(),

                    const SizedBox(height: 20),

                    // 卡片标题
                    Text(
                      widget.rewardCard.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // 分割线
                    Container(
                      width: 60,
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 卡片描述
                    Expanded(
                      child: Center(
                        child: Text(
                          widget.rewardCard.description,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    // 积分显示
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.stars,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.rewardCard.points} Points',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardIcon() {
    IconData icon;
    switch (widget.rewardCard.cardType) {
      case 'completion':
        icon = Icons.check_circle_outline;
        break;
      case 'achievement':
        icon = Icons.emoji_events_outlined;
        break;
      case 'milestone':
        icon = Icons.flag_outlined;
        break;
      default:
        icon = Icons.star_outline;
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 40,
      ),
    );
  }

  Widget _buildActionButtons() {
    return FadeTransition(
      opacity: _cardOpacity,
      child: Row(
        children: [
          // 分享按钮
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFFFFD700),
                  width: 2,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: _shareCard,
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.share,
                          color: Color(0xFFFFD700),
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Share',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // 继续按钮
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: _continue,
                  child: const Center(
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareOverlay() {
    return GestureDetector(
      onTap: _hideShareOptions,
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(40),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Share Your Achievement',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                // 分享选项
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildShareOption(
                      icon: Icons.download,
                      label: 'Download',
                      onTap: _downloadCard,
                    ),
                    _buildShareOption(
                      icon: Icons.facebook,
                      label: 'Facebook',
                      onTap: () => _shareToSocialMedia('Facebook'),
                    ),
                    _buildShareOption(
                      icon: Icons.share,
                      label: 'Instagram',
                      onTap: () => _shareToSocialMedia('Instagram'),
                    ),
                    _buildShareOption(
                      icon: Icons.message,
                      label: 'Twitter',
                      onTap: () => _shareToSocialMedia('Twitter'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 关闭按钮
                TextButton(
                  onPressed: _hideShareOptions,
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFD700).withOpacity(0.1),
              border: Border.all(
                color: const Color(0xFFFFD700),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFFD700),
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCardColor() {
    switch (widget.rewardCard.cardType) {
      case 'completion':
        return const Color(0xFF4CAF50);
      case 'achievement':
        return const Color(0xFFFF9800);
      case 'milestone':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFFFFD700);
    }
  }
}

/// 粒子背景画笔
class SparklesPainter extends CustomPainter {
  final double rotationValue;

  SparklesPainter(this.rotationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final sparkles = [
      Offset(size.width * 0.1, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.1),
      Offset(size.width * 0.2, size.height * 0.8),
      Offset(size.width * 0.9, size.height * 0.7),
      Offset(size.width * 0.15, size.height * 0.5),
      Offset(size.width * 0.85, size.height * 0.4),
    ];

    for (int i = 0; i < sparkles.length; i++) {
      final offset = sparkles[i];
      final sparkleSize = (i % 3 + 1) * 2.0;

      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.rotate(rotationValue * 3.14159 + i);

      // 绘制星星形状
      _drawStar(canvas, paint, sparkleSize);

      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, Paint paint, double size) {
    final path = Path();
    final centerX = 0.0;
    final centerY = 0.0;

    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * 3.14159) / 5 - 3.14159 / 2;
      final outerRadius = size;
      final innerRadius = size * 0.4;

      if (i == 0) {
        path.moveTo(
          centerX + outerRadius * cos(angle),
          centerY + outerRadius * sin(angle),
        );
      } else {
        path.lineTo(
          centerX + outerRadius * cos(angle),
          centerY + outerRadius * sin(angle),
        );
      }

      final innerAngle = angle + 3.14159 / 5;
      path.lineTo(
        centerX + innerRadius * cos(innerAngle),
        centerY + innerRadius * sin(innerAngle),
      );
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SparklesPainter oldDelegate) {
    return oldDelegate.rotationValue != rotationValue;
  }

  double cos(double angle) => cosLookupTable[(angle * 180 / 3.14159).round() % 360];
  double sin(double angle) => sinLookupTable[(angle * 180 / 3.14159).round() % 360];

  static const List<double> cosLookupTable = [
    1.0, 0.9998, 0.9994, 0.9986, 0.9976, 0.9962, 0.9945, 0.9925, 0.9903, 0.9877,
    0.9848, 0.9816, 0.9781, 0.9744, 0.9703, 0.9659, 0.9613, 0.9563, 0.9511, 0.9455,
    // ... (简化版，实际应包含360个值)
  ];

  static const List<double> sinLookupTable = [
    0.0, 0.0175, 0.0349, 0.0523, 0.0698, 0.0872, 0.1045, 0.1219, 0.1392, 0.1564,
    0.1736, 0.1908, 0.2079, 0.2250, 0.2419, 0.2588, 0.2756, 0.2924, 0.3090, 0.3256,
    // ... (简化版，实际应包含360个值)
  ];
}
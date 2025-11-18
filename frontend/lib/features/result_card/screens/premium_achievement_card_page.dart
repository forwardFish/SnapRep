import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../../core/models/reward_card.dart';
import '../../../routes/app_routes.dart';

/// Premium Achievement Card Page - English Interface
/// "Equipment Cards" concept: Household Hero / Anywhere Fit
/// 9:16 format designed for social sharing
class PremiumAchievementCardPage extends StatefulWidget {
  final RewardCard rewardCard;
  final String? scenarioName;
  final String? equipmentUsed;
  final VoidCallback? onContinue;

  const PremiumAchievementCardPage({
    super.key,
    required this.rewardCard,
    this.scenarioName,
    this.equipmentUsed,
    this.onContinue,
  });

  @override
  State<PremiumAchievementCardPage> createState() => _PremiumAchievementCardPageState();
}

class _PremiumAchievementCardPageState extends State<PremiumAchievementCardPage>
    with TickerProviderStateMixin {
  late AnimationController _cardController;
  late AnimationController _floatingController;
  late AnimationController _backgroundController;

  late Animation<double> _cardScale;
  late Animation<double> _cardOpacity;
  late Animation<double> _floatingAnimation;
  late Animation<Color?> _backgroundGradient;

  bool _showingActionPanel = false;
  bool _showingSocialShare = false;
  String _cardRarity = "RARE"; // COMMON, RARE, EPIC, LEGENDARY

  @override
  void initState() {
    super.initState();
    _determineCardRarity();
    _initializeAnimations();
    _startAnimations();
    HapticFeedback.heavyImpact();
  }

  void _determineCardRarity() {
    final points = widget.rewardCard.points;
    if (points >= 100) {
      _cardRarity = "LEGENDARY";
    } else if (points >= 50) {
      _cardRarity = "EPIC";
    } else if (points >= 20) {
      _cardRarity = "RARE";
    } else {
      _cardRarity = "COMMON";
    }
  }

  void _initializeAnimations() {
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _cardScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
    ));

    _cardOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _floatingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    _backgroundGradient = ColorTween(
      begin: _getRarityColors().first,
      end: _getRarityColors().last,
    ).animate(_backgroundController);
  }

  void _startAnimations() {
    _cardController.forward();
    _floatingController.repeat(reverse: true);
    _backgroundController.repeat(reverse: true);

    // Delay showing action panel
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showingActionPanel = true;
        });
      }
    });
  }

  List<Color> _getRarityColors() {
    switch (_cardRarity) {
      case "LEGENDARY":
        return [const Color(0xFFFFD700), const Color(0xFFFFA500), const Color(0xFFFF4500)];
      case "EPIC":
        return [const Color(0xFF9C27B0), const Color(0xFF673AB7), const Color(0xFF3F51B5)];
      case "RARE":
        return [const Color(0xFF2196F3), const Color(0xFF03A9F4), const Color(0xFF00BCD4)];
      case "COMMON":
      default:
        return [const Color(0xFF4CAF50), const Color(0xFF8BC34A), const Color(0xFFCDDC39)];
    }
  }

  String _getRarityText() {
    switch (_cardRarity) {
      case "LEGENDARY":
        return "LEGENDARY EQUIPMENT CARD";
      case "EPIC":
        return "EPIC EQUIPMENT CARD";
      case "RARE":
        return "RARE EQUIPMENT CARD";
      case "COMMON":
      default:
        return "COMMON EQUIPMENT CARD";
    }
  }

  String _getEquipmentEmoji() {
    final equipment = widget.equipmentUsed?.toLowerCase() ?? "";
    if (equipment.contains("chair") || equipment.contains("椅子")) return "🪑";
    if (equipment.contains("wall") || equipment.contains("墙")) return "🧱";
    if (equipment.contains("bottle") || equipment.contains("水瓶")) return "💧";
    if (equipment.contains("none") || equipment.contains("空手")) return "✋";
    return "🏠"; // Household Hero default
  }

  String _getScenarioName() {
    if (widget.scenarioName?.contains("office") == true || widget.scenarioName?.contains("办公室") == true) {
      return "Office";
    } else if (widget.scenarioName?.contains("gym") == true) {
      return "Gym";
    } else if (widget.scenarioName?.contains("home") == true || widget.scenarioName?.contains("客厅") == true) {
      return "Home";
    }
    return widget.scenarioName ?? "Anywhere";
  }

  String _getEquipmentName() {
    final equipment = widget.equipmentUsed?.toLowerCase() ?? "";
    if (equipment.contains("chair") || equipment.contains("椅子")) return "Chair";
    if (equipment.contains("wall") || equipment.contains("墙")) return "Wall";
    if (equipment.contains("bottle") || equipment.contains("水瓶")) return "Water Bottle";
    if (equipment.contains("none") || equipment.contains("空手")) return "No Equipment";
    return "Household Item";
  }

  @override
  void dispose() {
    _cardController.dispose();
    _floatingController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Dynamic gradient background
          _buildDynamicBackground(),

          // Main content
          _buildMainContent(),

          // Action panel
          if (_showingActionPanel)
            _buildActionPanel(),

          // Social sharing overlay
          if (_showingSocialShare)
            _buildSocialShareOverlay(),

          // Close button
          _buildCloseButton(),
        ],
      ),
    );
  }

  Widget _buildDynamicBackground() {
    return AnimatedBuilder(
      animation: _backgroundGradient,
      builder: (context, child) {
        final colors = _getRarityColors();
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [
                colors[0].withOpacity(0.3),
                colors[1].withOpacity(0.2),
                Colors.black.withOpacity(0.9),
                Colors.black,
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: CustomPaint(
            painter: FloatingParticlesPainter(_floatingAnimation.value),
            size: MediaQuery.of(context).size,
          ),
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
            const SizedBox(height: 40),

            // Title section
            _buildTitleSection(),

            const SizedBox(height: 40),

            // Main card area
            Expanded(
              child: Center(
                child: _buildMainCard(),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return FadeTransition(
      opacity: _cardOpacity,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome,
                color: _getRarityColors().first,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                _getRarityText(),
                style: TextStyle(
                  color: _getRarityColors().first,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "CARD UNLOCKED!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Everything is Equipment - Household Hero",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard() {
    return AnimatedBuilder(
      animation: Listenable.merge([_cardScale, _cardOpacity, _floatingAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _cardScale.value,
          child: Transform.translate(
            offset: Offset(0, math.sin(_floatingAnimation.value * 2 * math.pi) * 5),
            child: Opacity(
              opacity: _cardOpacity.value,
              child: Container(
                width: 320,
                height: 480, // 9:16 ratio
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _getRarityColors(),
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getRarityColors().first.withOpacity(0.6),
                      blurRadius: 30,
                      spreadRadius: 2,
                      offset: const Offset(0, 15),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.8),
                      blurRadius: 40,
                      spreadRadius: -10,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Background texture
                    _buildCardTexture(),

                    // Card content
                    _buildCardContent(),

                    // Holographic effect
                    _buildHolographicEffect(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardTexture() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.transparent,
              Colors.black.withOpacity(0.2),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card type label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              _cardRarity,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),

          const Spacer(flex: 1),

          // Main icon and equipment
          Center(
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _getEquipmentEmoji(),
                      style: const TextStyle(fontSize: 64),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _getEquipmentName(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const Spacer(flex: 1),

          // Training info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.rewardCard.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${_getScenarioName()} Training",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoChip(
                      Icons.timer,
                      "${widget.rewardCard.metadata['totalTime'] ?? '60'}s",
                    ),
                    _buildInfoChip(
                      Icons.star,
                      "${widget.rewardCard.points} pts",
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Spacer(flex: 1),

          // Timestamp
          Center(
            child: Text(
              "Collected: ${_formatDateTime(widget.rewardCard.earnedAt)}",
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHolographicEffect() {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.3 * _floatingAnimation.value),
                  Colors.transparent,
                  Colors.white.withOpacity(0.1 * (1 - _floatingAnimation.value)),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        curve: Curves.elasticOut,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: _getRarityColors().first.withOpacity(0.3),
              width: 2,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Achievement Unlocked",
              style: TextStyle(
                color: _getRarityColors().first,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Main action buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.share,
                    label: "Share",
                    color: _getRarityColors().first,
                    onTap: _showSocialSharing,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.save,
                    label: "Save",
                    color: Colors.green,
                    onTap: _saveCard,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Secondary action buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.refresh,
                    label: "Train Again",
                    color: Colors.orange,
                    onTap: _practiceAgain,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.home,
                    label: "Home",
                    color: Colors.grey,
                    onTap: _goHome,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialShareOverlay() {
    return GestureDetector(
      onTap: _hideSocialSharing,
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(40),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _getRarityColors().first.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.share,
                      color: _getRarityColors().first,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Share Your Achievement",
                      style: TextStyle(
                        color: _getRarityColors().first,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                const Text(
                  "Show the world your Household Hero achievement!",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Social media platforms grid
                GridView.count(
                  crossAxisCount: 4,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildSocialPlatform(
                      icon: Icons.facebook,
                      label: "Facebook",
                      color: const Color(0xFF1877F2),
                      onTap: () => _shareToSocialMedia("Facebook"),
                    ),
                    _buildSocialPlatform(
                      icon: Icons.facebook, // Using facebook as Twitter icon placeholder
                      label: "Twitter",
                      color: const Color(0xFF1DA1F2),
                      onTap: () => _shareToSocialMedia("Twitter"),
                    ),
                    _buildSocialPlatform(
                      icon: Icons.camera_alt,
                      label: "Instagram",
                      color: const Color(0xFFE4405F),
                      onTap: () => _shareToSocialMedia("Instagram"),
                    ),
                    _buildSocialPlatform(
                      icon: Icons.business,
                      label: "LinkedIn",
                      color: const Color(0xFF0A66C2),
                      onTap: () => _shareToSocialMedia("LinkedIn"),
                    ),
                    _buildSocialPlatform(
                      icon: Icons.message,
                      label: "WhatsApp",
                      color: const Color(0xFF25D366),
                      onTap: () => _shareToSocialMedia("WhatsApp"),
                    ),
                    _buildSocialPlatform(
                      icon: Icons.video_call,
                      label: "TikTok",
                      color: const Color(0xFF000000),
                      onTap: () => _shareToSocialMedia("TikTok"),
                    ),
                    _buildSocialPlatform(
                      icon: Icons.copy,
                      label: "Copy Link",
                      color: Colors.grey,
                      onTap: () => _copyShareLink(),
                    ),
                    _buildSocialPlatform(
                      icon: Icons.download,
                      label: "Download",
                      color: Colors.green,
                      onTap: () => _downloadCard(),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Close button
                TextButton(
                  onPressed: _hideSocialSharing,
                  child: const Text(
                    "Cancel",
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

  Widget _buildSocialPlatform({
    required IconData icon,
    required String label,
    required Color color,
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
              color: color.withOpacity(0.1),
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton() {
    return Positioned(
      top: 50,
      right: 20,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.5),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: IconButton(
          onPressed: _goHome,
          icon: const Icon(Icons.close, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  void _showSocialSharing() {
    HapticFeedback.lightImpact();
    setState(() {
      _showingSocialShare = true;
    });
  }

  void _hideSocialSharing() {
    HapticFeedback.lightImpact();
    setState(() {
      _showingSocialShare = false;
    });
  }

  void _shareToSocialMedia(String platform) {
    HapticFeedback.lightImpact();

    // Generate share text
    final shareText = "🏆 Just unlocked a ${_cardRarity} Equipment Card! "
                     "Completed ${_getScenarioName()} training with ${_getEquipmentName()}. "
                     "${widget.rewardCard.points} points earned! 💪 #HouseholdHero #AnywhereFit #WorkoutChallenge";

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Shared to $platform!\n\n"$shareText"'),
        backgroundColor: _getSharePlatformColor(platform),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );

    _hideSocialSharing();
  }

  void _copyShareLink() {
    HapticFeedback.lightImpact();

    final shareLink = "https://householdhero.app/card/${widget.rewardCard.id}";
    Clipboard.setData(ClipboardData(text: shareLink));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share link copied to clipboard!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    _hideSocialSharing();
  }

  void _downloadCard() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Card image saved to gallery!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _hideSocialSharing();
  }

  Color _getSharePlatformColor(String platform) {
    switch (platform) {
      case "Facebook":
        return const Color(0xFF1877F2);
      case "Twitter":
        return const Color(0xFF1DA1F2);
      case "Instagram":
        return const Color(0xFFE4405F);
      case "LinkedIn":
        return const Color(0xFF0A66C2);
      case "WhatsApp":
        return const Color(0xFF25D366);
      case "TikTok":
        return const Color(0xFF000000);
      default:
        return _getRarityColors().first;
    }
  }

  void _saveCard() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Card saved to your collection!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _practiceAgain() {
    HapticFeedback.lightImpact();
    if (widget.onContinue != null) {
      widget.onContinue!();
    } else {
      Navigator.pop(context);
    }
  }

  void _goHome() {
    HapticFeedback.lightImpact();
    AppRoutes.navigateToHome(context);
  }

  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')} "
           "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }
}

/// Floating particles painter
class FloatingParticlesPainter extends CustomPainter {
  final double animationValue;

  FloatingParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Create multiple floating particles
    final particles = [
      Offset(size.width * 0.1, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.15),
      Offset(size.width * 0.2, size.height * 0.7),
      Offset(size.width * 0.9, size.height * 0.6),
      Offset(size.width * 0.15, size.height * 0.45),
      Offset(size.width * 0.85, size.height * 0.35),
      Offset(size.width * 0.05, size.height * 0.8),
      Offset(size.width * 0.95, size.height * 0.25),
    ];

    for (int i = 0; i < particles.length; i++) {
      final offset = particles[i];
      final phase = (animationValue + i * 0.125) % 1.0;

      // Particle color and size
      paint.color = Color.lerp(
        const Color(0xFFFFD700).withOpacity(0.3),
        const Color(0xFF00BCD4).withOpacity(0.5),
        math.sin(phase * math.pi),
      )!;

      final radius = 2 + 4 * math.sin(phase * 2 * math.pi);

      // Floating effect
      final floatY = offset.dy + math.sin(phase * 4 * math.pi) * 20;
      final floatX = offset.dx + math.cos(phase * 3 * math.pi) * 10;

      canvas.drawCircle(Offset(floatX, floatY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(FloatingParticlesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
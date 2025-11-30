import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/challenge_item_dto.dart';
import '../../../core/services/challenges_service.dart';
import '../../../routes/app_routes.dart';

// Helper function to validate and sanitize image URLs
bool _isValidImageUrl(String? url) {
  if (url == null || url.isEmpty) return false;

  // Check if URL is well-formed
  try {
    final uri = Uri.parse(url);
    if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) return false;
  } catch (e) {
    return false;
  }

  // Blacklist known problematic domains
  const problematicDomains = ['cdn.snaprep.com'];
  for (final domain in problematicDomains) {
    if (url.contains(domain)) return false;
  }

  return true;
}

class ChallengesPage extends StatefulWidget {
  const ChallengesPage({super.key});

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  List<ChallengeItemDto> challenges = [];
  bool isLoading = false;
  String? error;

  // Parameters received from navigation
  String? exerciseId;
  String? exerciseName;
  bool fromRecommended = false;

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get navigation arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      exerciseId = args['exerciseId'] as String?;
      exerciseName = args['exerciseName'] as String?;
      fromRecommended = args['fromRecommended'] as bool? ?? false;

      if (fromRecommended && exerciseId != null) {
        debugPrint('📍 Challenges page loaded with exercise: $exerciseName (ID: $exerciseId)');
        // TODO: Load specific exercise details or create workout session
      }
    }
  }

  Future<void> _loadChallenges() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final service = ChallengesService();
      final challengeList = await service.getChallenges(
        page: 1,
        pageSize: 12,
        isActive: true,
      );
      setState(() {
        challenges = challengeList;
        isLoading = false;
      });
      debugPrint('✅ Challenges loaded from API: ${challengeList.length} items');
    } catch (e) {
      debugPrint('❌ Failed to load challenges from API: $e');
      setState(() {
        error = 'Failed to load challenges: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _buildErrorState()
              : fromRecommended && exerciseId != null
                  ? _buildSingleExerciseView()
                  : _buildChallengeContent(),
    );
  }

  Widget _buildSingleExerciseView() {
    // Display a message when coming from recommended exercises
    return Scaffold(
      appBar: AppBar(
        title: Text(exerciseName ?? 'Exercise Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.fitness_center,
                size: 64,
                color: Color(0xFF6C5CE7),
              ),
              const SizedBox(height: 24),
              Text(
                exerciseName ?? 'Exercise',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                '🚧 This feature is coming soon!\n\nFor now, explore our Challenge Items below.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    fromRecommended = false;
                    exerciseId = null;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('View Challenge Items'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            error!,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadChallenges,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeContent() {
    return Stack(
      children: [
        // Background Image - Fixed background (won't change)
        Positioned.fill(
          child: CachedNetworkImage(
            imageUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2070&q=80',
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF6366F1),
                    Color(0xFF8B5CF6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF6366F1),
                    Color(0xFF8B5CF6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ),

        // Dark overlay for readability
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),
        ),

        // Content
        SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadChallenges,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Custom App Bar
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  floating: true,
                  pinned: false,
                  leading: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  title: const Text(
                    'Challenge Arena',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.share, color: Colors.white, size: 20),
                        onPressed: () {
                          // Share functionality
                        },
                      ),
                    ),
                  ],
                ),

                // Header Section
                SliverToBoxAdapter(
                  child: _buildHeaderSection(),
                ),

                // Challenge Grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 20,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final challenge = challenges[index];
                        return _buildChallengeCard(challenge, index);
                      },
                      childCount: challenges.length,
                    ),
                  ),
                ),

                // Bottom Info Section
                SliverToBoxAdapter(
                  child: _buildBottomInfoSection(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Featured badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.amber,
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  'FEATURED CHALLENGES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Choose Your Challenge',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),

          const Text(
            'Turn everyday objects into your fitness equipment',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white,
              height: 1.4,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),

          // Stats row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '8.5K ACTIVE',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '• 12 unique challenges',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(ChallengeItemDto challenge, int index) {
    // Use data from the API
    final participantCount = challenge.totalParticipants;
    final emoji = challenge.emoji;

    // Use image from API or fallback to gradient
    final backgroundImage = _isValidImageUrl(challenge.imageUrl) ? challenge.imageUrl : null;
    final difficulties = challenge.difficulty; // Use difficulty from API
    final rarity = _getRarityFromString(challenge.baseRarity); // Convert string to enum

    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(16),
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onChallengePressed(challenge),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _getRarityColor(rarity).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Background Image or Gradient
                Positioned.fill(
                  child: backgroundImage != null
                      ? CachedNetworkImage(
                          imageUrl: backgroundImage,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getRarityColor(rarity).withOpacity(0.8),
                                  _getRarityColor(rarity).withOpacity(0.6),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) {
                            // Debug logging
                            debugPrint('🔥 Image loading failed for URL: $url');
                            debugPrint('🔥 Error: $error');
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _getRarityColor(rarity).withOpacity(0.8),
                                    _getRarityColor(rarity).withOpacity(0.6),
                                  ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ));
                          },
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getRarityColor(rarity).withOpacity(0.8),
                                _getRarityColor(rarity).withOpacity(0.6),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                ),

                // Dark gradient overlay for text readability
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ),

                // Rarity border glow effect
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getRarityColor(rarity).withOpacity(0.6),
                        width: 2,
                      ),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top section with emoji and rarity badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Emoji icon with enhanced styling
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          ),

                          // Rarity badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getRarityColor(rarity).withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: _getRarityColor(rarity).withOpacity(0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              _getRarityName(rarity).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Bottom section with title and stats
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title with enhanced styling
                          Text(
                            _getDisplayTitle(challenge.name), // Use 'name' instead of 'title'
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                              height: 1.1,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 6),

                          // Stats row with participants and difficulty
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Participants count
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '${participantCount >= 1000 ? '${(participantCount / 1000).toStringAsFixed(1)}K' : participantCount}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),

                              // Difficulty stars
                              Row(
                                children: List.generate(3, (starIndex) {
                                  return Icon(
                                    starIndex < difficulties ? Icons.star : Icons.star_border,
                                    color: Colors.amber,
                                    size: 12,
                                  );
                                }),
                              ),
                            ],
                          ),
                        ],
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
  }

  Widget _buildBottomInfoSection() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and title row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'How It Works',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rules list
          const Text(
            '• Pick any everyday object around you\n'
            '• Complete 3-5 creative exercises with it\n'
            '• Earn exclusive badges based on rarity\n'
            '• Share your achievements with friends',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),

          // Badge levels section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Rarity Levels',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Badge examples with enhanced design
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildGlowingBadgeExample('COMMON', Colors.grey),
              _buildGlowingBadgeExample('RARE', Colors.blue),
              _buildGlowingBadgeExample('EPIC', Colors.purple),
              _buildGlowingBadgeExample('LEGENDARY', Colors.orange),
            ],
          ),

          const SizedBox(height: 16),
          Text(
            'Fewer participants = rarer badge rewards!',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowingBadgeExample(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        '🎁 $name',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // Helper Methods

  String _getDisplayTitle(String title) {
    return title.replaceAll(' Challenge', '');
  }

  RarityLevel _getRarityFromString(String rarityStr) {
    switch (rarityStr.toUpperCase()) {
      case 'LEGENDARY':
        return RarityLevel.legendary;
      case 'EPIC':
        return RarityLevel.epic;
      case 'RARE':
        return RarityLevel.rare;
      case 'COMMON':
      default:
        return RarityLevel.common;
    }
  }

  Color _getRarityColor(RarityLevel rarity) {
    switch (rarity) {
      case RarityLevel.common:
        return Colors.grey;
      case RarityLevel.rare:
        return Colors.blue;
      case RarityLevel.epic:
        return Colors.purple;
      case RarityLevel.legendary:
        return Colors.orange;
    }
  }

  String _getRarityName(RarityLevel rarity) {
    switch (rarity) {
      case RarityLevel.common:
        return 'common';
      case RarityLevel.rare:
        return 'rare';
      case RarityLevel.epic:
        return 'epic';
      case RarityLevel.legendary:
        return 'legendary';
    }
  }

  void _onChallengePressed(ChallengeItemDto challenge) {
    debugPrint('Challenge pressed: ${challenge.name}');

    // Use AppRoutes to navigate directly to workout result page with challenge configuration
    AppRoutes.challengeQuickJoin(
      context,
      challengeId: challenge.id,
      equipmentCode: challenge.code.replaceAll('_challenge', ''), // Extract equipment code from challenge code
    );
  }

}

enum RarityLevel { common, rare, epic, legendary }
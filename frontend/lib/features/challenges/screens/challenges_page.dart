import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/challenge_item.dart';
import '../../../core/models/exercise.dart';
import '../../../core/models/target_muscle.dart';
import '../../../core/models/workout_intent.dart';
import '../../../core/services/challenges_service.dart';
import '../../../routes/app_routes.dart';

class ChallengesPage extends StatefulWidget {
  const ChallengesPage({super.key});

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  List<ChallengeItem> challenges = [];
  bool isLoading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      // TODO: Replace with actual API call
      final mockChallenges = _generateMockChallenges();
      setState(() {
        challenges = mockChallenges;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load challenges: $e';
        isLoading = false;
      });
    }
  }

  List<ChallengeItem> _generateMockChallenges() {
    final now = DateTime.now();
    return [
      ChallengeItem(
        id: '1',
        code: 'umbrella_challenge',
        title: 'Umbrella Challenge',
        equipmentId: 'umbrella_eq_id',
        timeLimit: 10,
        targetCount: 3,
        description: 'Complete workouts using an umbrella as your fitness tool',
        instructions: 'Use the umbrella for resistance training and balance exercises',
        isPopular: true,
        trendingScore: 0.85,
        isActive: true,
        displayOrder: 1,
        createdAt: now,
        updatedAt: now,
      ),
      ChallengeItem(
        id: '2',
        code: 'water_bottle_challenge',
        title: 'Water Bottle Challenge',
        equipmentId: 'bottle_eq_id',
        timeLimit: 15,
        targetCount: 3,
        description: 'Turn your water bottle into a weight for strength training',
        instructions: 'Use filled water bottle as resistance for arm and shoulder exercises',
        isPopular: true,
        trendingScore: 0.76,
        isActive: true,
        displayOrder: 2,
        createdAt: now,
        updatedAt: now,
      ),
      ChallengeItem(
        id: '3',
        code: 'chair_challenge',
        title: 'Chair Challenge',
        equipmentId: 'chair_eq_id',
        timeLimit: 12,
        targetCount: 3,
        description: 'Transform your chair into a complete fitness station',
        instructions: 'Use the chair for support, resistance, and strength training',
        isPopular: true,
        trendingScore: 0.89,
        isActive: true,
        displayOrder: 3,
        createdAt: now,
        updatedAt: now,
      ),
      ChallengeItem(
        id: '4',
        code: 'backpack_challenge',
        title: 'Backpack Challenge',
        equipmentId: 'backpack_eq_id',
        timeLimit: 20,
        targetCount: 4,
        description: 'Use your backpack for a traveling fitness routine',
        instructions: 'Perfect for travelers. Use the backpack weight for full body exercises',
        isPopular: false,
        trendingScore: 0.65,
        isActive: true,
        displayOrder: 4,
        createdAt: now,
        updatedAt: now,
      ),
      ChallengeItem(
        id: '5',
        code: 'broom_challenge',
        title: 'Broom Challenge',
        equipmentId: 'broom_eq_id',
        timeLimit: 15,
        targetCount: 3,
        description: 'Creative workout using a household broom',
        instructions: 'Use the broom as a balance bar and resistance tool',
        isPopular: false,
        trendingScore: 0.42,
        isActive: true,
        displayOrder: 5,
        createdAt: now,
        updatedAt: now,
      ),
      ChallengeItem(
        id: '6',
        code: 'book_challenge',
        title: 'Book Challenge',
        equipmentId: 'book_eq_id',
        timeLimit: 8,
        targetCount: 3,
        description: 'Use a book as workout equipment for strength training',
        instructions: 'Hold the book for resistance exercises. Perfect for office workouts',
        isPopular: false,
        trendingScore: 0.72,
        isActive: true,
        displayOrder: 6,
        createdAt: now,
        updatedAt: now,
      ),
      ChallengeItem(
        id: '7',
        code: 'towel_challenge',
        title: 'Towel Challenge',
        equipmentId: 'towel_eq_id',
        timeLimit: 12,
        targetCount: 3,
        description: 'Enhance your flexibility using a simple towel',
        instructions: 'Great for stretching and resistance exercises',
        isPopular: false,
        trendingScore: 0.32,
        isActive: true,
        displayOrder: 7,
        createdAt: now,
        updatedAt: now,
      ),
      ChallengeItem(
        id: '8',
        code: 'luggage_challenge',
        title: 'Luggage Challenge',
        equipmentId: 'luggage_eq_id',
        timeLimit: 25,
        targetCount: 4,
        description: 'Heavy-duty workout with your suitcase',
        instructions: 'Use your luggage for strength and stability training',
        isPopular: false,
        trendingScore: 0.18,
        isActive: true,
        displayOrder: 8,
        createdAt: now,
        updatedAt: now,
      ),
      ChallengeItem(
        id: '9',
        code: 'guitar_challenge',
        title: 'Guitar Challenge',
        equipmentId: 'guitar_eq_id',
        timeLimit: 15,
        targetCount: 5,
        description: 'Musical instrument workout challenge',
        instructions: 'Use the guitar as a prop for creative exercises',
        isPopular: false,
        trendingScore: 0.023,
        isActive: true,
        displayOrder: 9,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _buildErrorState()
              : _buildChallengeContent(),
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
        // Background Image
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

  Widget _buildChallengeCard(ChallengeItem challenge, int index) {
    // Generate mock data based on challenge properties
    final participantCounts = [1200, 800, 2100, 650, 420, 890, 320, 180, 23];
    final participantCount = participantCounts[index % participantCounts.length];

    final emojis = ['🌂', '🧃', '🪑', '🎒', '🧹', '📚', '🧺', '🧳', '🎸'];
    final emoji = emojis[index % emojis.length];

    // Background images for each challenge type
    final backgroundImages = [
      'https://images.unsplash.com/photo-1520970014086-2208d157c9e2?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80', // Umbrella/rain workout
      'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80', // Hydration/water theme
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80', // Office/chair workout
      'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80', // Travel/backpack fitness
      'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80', // Home cleaning workout
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80', // Study/reading fitness
      'https://images.unsplash.com/photo-1584464491033-06628f3a6b7b?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80', // Laundry/basket workout
      'https://images.unsplash.com/photo-1488646953014-85cb44e25828?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80', // Luggage/travel fitness
      'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80', // Music/guitar workout
    ];

    final backgroundImage = backgroundImages[index % backgroundImages.length];
    final difficulties = _getDifficultyStars(challenge.trendingScore);
    final rarity = _getRarityLevel(participantCount);

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
                // Background Image
                Positioned.fill(
                  child: CachedNetworkImage(
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
                    errorWidget: (context, url, error) => Container(
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
                            _getDisplayTitle(challenge.title),
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

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  int _getDifficultyStars(double trendingScore) {
    if (trendingScore >= 0.8) return 2;
    if (trendingScore >= 0.6) return 3;
    if (trendingScore >= 0.4) return 4;
    return 5;
  }

  RarityLevel _getRarityLevel(int participantCount) {
    if (participantCount >= 1000) return RarityLevel.common;
    if (participantCount >= 200) return RarityLevel.rare;
    if (participantCount >= 50) return RarityLevel.epic;
    return RarityLevel.legendary;
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

  void _onChallengePressed(ChallengeItem challenge) {
    debugPrint('Challenge pressed: ${challenge.title}');

    // 为挑战创建模拟的动作训练数据
    final exercises = _createMockExercisesForChallenge(challenge);

    if (exercises.isNotEmpty) {
      // 直接跳转到动作训练页面
      AppRoutes.navigateToProfessionalWorkoutVideo(
        context,
        exercise: exercises.first,
        exercises: exercises,
        currentExerciseIndex: 0,
      );
    } else {
      // 如果没有找到对应的动作，显示提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${challenge.title} training exercises are under development'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // 为挑战创建模拟动作数据
  List<Exercise> _createMockExercisesForChallenge(ChallengeItem challenge) {
    final exerciseTemplates = {
      'towel_challenge': [
        {
          'name': 'Towel Rowing',
          'description': 'Back muscle training using towel resistance',
          'videoUrl': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
          'duration': 45,
          'reps': 12,
        },
        {
          'name': 'Towel Stretching',
          'description': 'Shoulder stretching exercise with towel assistance',
          'videoUrl': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_2mb.mp4',
          'duration': 30,
          'reps': 8,
        },
      ],
      'water_bottle_challenge': [
        {
          'name': 'Water Bottle Press',
          'description': 'Arm strength training using water bottles as weights',
          'videoUrl': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
          'duration': 40,
          'reps': 15,
        },
        {
          'name': 'Water Bottle Squats',
          'description': 'Weighted squats for leg muscle development',
          'videoUrl': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_2mb.mp4',
          'duration': 50,
          'reps': 12,
        },
      ],
      'chair_challenge': [
        {
          'name': 'Chair Dips',
          'description': 'Upper body strength training using chair support',
          'videoUrl': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
          'duration': 35,
          'reps': 10,
        },
        {
          'name': 'Chair Squats',
          'description': 'Chair-assisted squats for leg strength',
          'videoUrl': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_2mb.mp4',
          'duration': 45,
          'reps': 15,
        },
      ],
    };

    final templates = exerciseTemplates[challenge.code] ?? [
      {
        'name': '${challenge.title} Basic Training',
        'description': '${challenge.description}',
        'videoUrl': 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
        'duration': 45,
        'reps': 10,
      }
    ];

    return templates.asMap().entries.map<Exercise>((entry) {
      final index = entry.key;
      final template = entry.value;
      return Exercise(
        id: '${challenge.id}_exercise_$index',
        code: '${challenge.code}_ex_$index',
        name: template['name'] as String,
        description: template['description'] as String,
        primaryMuscle: TargetMuscle.fullBody,
        secondaryMuscles: const [TargetMuscle.core],
        intentType: WorkoutIntent.strength,
        difficulty: ExerciseDifficulty.intermediate,
        durationSeconds: template['duration'] as int,
        sets: challenge.targetCount,
        repetitions: template['reps'] as int,
        demoVideoUrl: template['videoUrl'] as String,
        thumbnailUrl: 'https://via.placeholder.com/400x300/6366F1/FFFFFF?text=${Uri.encodeComponent(template['name'] as String)}',
        keyPoints: const ['Prepare related items', 'Follow movement demonstration', 'Maintain proper form', 'Control breathing rhythm'],
        safetyWarnings: const ['Ensure safe surroundings', 'Be mindful of range of motion', 'Stop immediately if you feel discomfort'],
        benefits: 'Improve physical fitness and exercise skills through challenge training',
        tags: const [ExerciseTag.strength],
      );
    }).toList();
  }
}

enum RarityLevel { common, rare, epic, legendary }
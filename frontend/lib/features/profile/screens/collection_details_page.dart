import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/my_page_provider.dart';
import '../../../core/models/share_card.dart';

/// My Collection Details Page - 收藏卡片详情页面
/// 显示用户收集的所有运动卡片，支持筛选和搜索
class CollectionDetailsPage extends StatefulWidget {
  const CollectionDetailsPage({super.key});

  @override
  State<CollectionDetailsPage> createState() => _CollectionDetailsPageState();
}

class _CollectionDetailsPageState extends State<CollectionDetailsPage> {
  RarityLevel? _selectedRarity;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyPageProvider>(
      builder: (context, provider, child) {
        final filteredCards = _getFilteredCards(provider.allCards);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'My Collection',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // Search and Filter Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Search Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search cards...',
                          hintStyle: TextStyle(color: Color(0xFF9E9E9E)),
                          prefixIcon: Icon(Icons.search, color: Color(0xFF9E9E9E)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(null, 'All'),
                          const SizedBox(width: 8),
                          _buildFilterChip(RarityLevel.common, 'Common'),
                          const SizedBox(width: 8),
                          _buildFilterChip(RarityLevel.uncommon, 'Uncommon'),
                          const SizedBox(width: 8),
                          _buildFilterChip(RarityLevel.rare, 'Rare'),
                          const SizedBox(width: 8),
                          _buildFilterChip(RarityLevel.epic, 'Epic'),
                          const SizedBox(width: 8),
                          _buildFilterChip(RarityLevel.legendary, 'Legendary'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Collection Stats
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(
                      '${filteredCards.length} Cards Found',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const Spacer(),
                    _buildStatsChip(provider),
                  ],
                ),
              ),

              // Loading/Error/Empty States
              Expanded(
                child: provider.isLoadingCards
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                        ),
                      )
                    : provider.cardsError != null
                        ? _buildErrorState(provider.cardsError!, () => provider.loadCardCollection())
                        : filteredCards.isEmpty
                            ? _buildEmptyState()
                            : GridView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.75,
                                ),
                                itemCount: filteredCards.length,
                                itemBuilder: (context, index) {
                                  final card = filteredCards[index];
                                  return _buildCollectionCard(card);
                                },
                              ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build filter chip
  Widget _buildFilterChip(RarityLevel? value, String label) {
    final isSelected = _selectedRarity == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRarity = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFD700) : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD700) : const Color(0xFFE0E0E0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.black : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }

  /// Build stats chip
  Widget _buildStatsChip(MyPageProvider provider) {
    final rareCount = provider.rareCards + provider.epicCards + provider.legendaryCards;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars, color: Color(0xFF4CAF50), size: 16),
          const SizedBox(width: 4),
          Text(
            '$rareCount Rare+',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load cards',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.collections_bookmark_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No cards in your collection',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete workouts to earn cards',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// Build collection card
  Widget _buildCollectionCard(ShareCard card) {
    final rarity = card.rarity.level;
    final rarityColors = _getRarityColors(rarity);

    return GestureDetector(
      onTap: () {
        _showCardDetails(card);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // Image Area (65%)
              Expanded(
                flex: 65,
                child: Stack(
                  children: [
                    // Background Image
                    Positioned.fill(
                      child: Image.network(
                        card.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 32,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Rarity Badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: rarityColors['bg'],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          rarity.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: rarityColors['text'],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content Area (35%)
              Expanded(
                flex: 35,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.displaySummary,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card.rarity.equipmentSeries.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
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

  /// Show card details modal
  void _showCardDetails(ShareCard card) {
    final rarity = card.rarity.level;
    final rarityColors = _getRarityColors(rarity);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Card details
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          card.imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.displaySummary.isNotEmpty
                                  ? card.displaySummary
                                  : 'Workout Card',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              card.rarity.equipmentSeries.displayName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: rarityColors['bg'],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                card.rarity.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: rarityColors['text'],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Card Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (card.totalDuration != null)
                    Text(
                      'Duration: ${(card.totalDuration! / 60).round()} minutes',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                    ),
                  if (card.exercisesCompleted != null)
                    Text(
                      'Exercises completed: ${card.exercisesCompleted}',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                    ),
                  if (card.equipmentUsed != null && card.equipmentUsed!.isNotEmpty)
                    Text(
                      'Equipment: ${card.equipmentUsed!.join(', ')}',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Created: ${card.createdAt.toString().substring(0, 16)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // TODO: Share card functionality
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFFFD700)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Share',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFFD700),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // TODO: View workout details
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD700),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'View Workout',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get filtered cards
  List<ShareCard> _getFilteredCards(List<ShareCard> cards) {
    return cards.where((card) {
      // Rarity filter
      final matchesRarity = _selectedRarity == null || card.rarity.level == _selectedRarity;

      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          card.displaySummary.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          card.rarity.equipmentSeries.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          card.shareText.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesRarity && matchesSearch;
    }).toList();
  }

  /// Get rarity colors
  Map<String, Color> _getRarityColors(RarityLevel rarity) {
    switch (rarity) {
      case RarityLevel.common:
        return {'bg': const Color(0xFFE8F5E8), 'text': const Color(0xFF2E7D32)};
      case RarityLevel.uncommon:
        return {'bg': const Color(0xFFE3F2FD), 'text': const Color(0xFF1565C0)};
      case RarityLevel.rare:
        return {'bg': const Color(0xFFF3E5F5), 'text': const Color(0xFF7B1FA2)};
      case RarityLevel.epic:
        return {'bg': const Color(0xFFFFF3E0), 'text': const Color(0xFFF57C00)};
      case RarityLevel.legendary:
        return {'bg': const Color(0xFFFFEBEE), 'text': const Color(0xFFD32F2F)};
    }
  }
}
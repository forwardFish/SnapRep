import 'package:flutter/material.dart';

/// My Collection Details Page - 收藏卡片详情页面
/// 显示用户收集的所有运动卡片，支持筛选和搜索
class CollectionDetailsPage extends StatefulWidget {
  const CollectionDetailsPage({super.key});

  @override
  State<CollectionDetailsPage> createState() => _CollectionDetailsPageState();
}

class _CollectionDetailsPageState extends State<CollectionDetailsPage> {
  String _selectedRarity = 'ALL';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Sample collection data - replace with actual provider data
  final List<Map<String, dynamic>> _allCards = [
    {'title': 'Chair Squats', 'rarity': 'FINE', 'category': 'Legs', 'imageUrl': 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80'},
    {'title': 'Push-ups', 'rarity': 'COMMON', 'category': 'Chest', 'imageUrl': 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80'},
    {'title': 'Bag Lifts', 'rarity': 'RARE', 'category': 'Arms', 'imageUrl': 'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80'},
    {'title': 'Wall Push', 'rarity': 'COMMON', 'category': 'Chest', 'imageUrl': 'https://images.unsplash.com/photo-1631679706909-1844bbd07221?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80'},
    {'title': 'Bottle Press', 'rarity': 'FINE', 'category': 'Arms', 'imageUrl': 'https://images.unsplash.com/photo-1523362628745-0c100150b504?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80'},
    {'title': 'Luggage Lift', 'rarity': 'EPIC', 'category': 'Back', 'imageUrl': 'https://images.unsplash.com/photo-1544427920-c49ccfb85579?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80'},
    {'title': 'Desk Stretch', 'rarity': 'COMMON', 'category': 'Flexibility', 'imageUrl': 'https://images.unsplash.com/photo-1588286840104-8957b019727f?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80'},
    {'title': 'Water Jug Curls', 'rarity': 'FINE', 'category': 'Arms', 'imageUrl': 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80'},
    {'title': 'Towel Resistance', 'rarity': 'RARE', 'category': 'Full Body', 'imageUrl': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80'},
    {'title': 'Book Balancing', 'rarity': 'EPIC', 'category': 'Core', 'imageUrl': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80'},
    {'title': 'Stair Climbs', 'rarity': 'COMMON', 'category': 'Cardio', 'imageUrl': 'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80'},
    {'title': 'Pillow Presses', 'rarity': 'FINE', 'category': 'Core', 'imageUrl': 'https://images.unsplash.com/photo-1520877880798-5ee002cf65d5?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&q=80'},
  ];

  @override
  Widget build(BuildContext context) {
    final filteredCards = _getFilteredCards();

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
                      hintText: 'Search exercises...',
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
                      _buildFilterChip('ALL', 'All'),
                      const SizedBox(width: 8),
                      _buildFilterChip('COMMON', 'Common'),
                      const SizedBox(width: 8),
                      _buildFilterChip('FINE', 'Fine'),
                      const SizedBox(width: 8),
                      _buildFilterChip('RARE', 'Rare'),
                      const SizedBox(width: 8),
                      _buildFilterChip('EPIC', 'Epic'),
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
                _buildStatsChip(),
              ],
            ),
          ),

          // Cards Grid
          Expanded(
            child: filteredCards.isEmpty
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
                      return _buildCollectionCard(
                        card['title'],
                        card['rarity'],
                        card['category'],
                        card['imageUrl'],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Build filter chip
  Widget _buildFilterChip(String value, String label) {
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
  Widget _buildStatsChip() {
    final rarityCount = _getRarityCount();
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
            '${rarityCount['RARE']! + rarityCount['EPIC']!} Rare+',
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

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No cards found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filter',
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
  Widget _buildCollectionCard(String title, String rarity, String category, String imageUrl) {
    final rarityColors = {
      'COMMON': {'bg': const Color(0xFFE8F5E8), 'text': const Color(0xFF2E7D32)},
      'FINE': {'bg': const Color(0xFFE3F2FD), 'text': const Color(0xFF1565C0)},
      'RARE': {'bg': const Color(0xFFF3E5F5), 'text': const Color(0xFF7B1FA2)},
      'EPIC': {'bg': const Color(0xFFFFF3E0), 'text': const Color(0xFFF57C00)},
    };

    final colors = rarityColors[rarity] ?? rarityColors['COMMON']!;

    return GestureDetector(
      onTap: () {
        _showCardDetails(title, rarity, category, imageUrl);
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
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Rarity Badge
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors['bg'],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            rarity,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: colors['text'],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                        title,
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
                        category,
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
  void _showCardDetails(String title, String rarity, String category, String imageUrl) {
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
                          imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              category,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getRarityColor(rarity)['bg'],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                rarity,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getRarityColor(rarity)['text'],
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
                    'Exercise Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This exercise helps strengthen your muscles and improve your overall fitness. Perfect for home workouts with minimal equipment.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Start exercise
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Start Exercise',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
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
  List<Map<String, dynamic>> _getFilteredCards() {
    var filtered = _allCards.where((card) {
      final matchesRarity = _selectedRarity == 'ALL' || card['rarity'] == _selectedRarity;
      final matchesSearch = _searchQuery.isEmpty ||
          card['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          card['category'].toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesRarity && matchesSearch;
    }).toList();

    return filtered;
  }

  /// Get rarity count
  Map<String, int> _getRarityCount() {
    final count = {'COMMON': 0, 'FINE': 0, 'RARE': 0, 'EPIC': 0};
    for (final card in _allCards) {
      final rarity = card['rarity'] as String;
      count[rarity] = (count[rarity] ?? 0) + 1;
    }
    return count;
  }

  /// Get rarity color
  Map<String, Color> _getRarityColor(String rarity) {
    final colors = {
      'COMMON': {'bg': const Color(0xFFE8F5E8), 'text': const Color(0xFF2E7D32)},
      'FINE': {'bg': const Color(0xFFE3F2FD), 'text': const Color(0xFF1565C0)},
      'RARE': {'bg': const Color(0xFFF3E5F5), 'text': const Color(0xFF7B1FA2)},
      'EPIC': {'bg': const Color(0xFFFFF3E0), 'text': const Color(0xFFF57C00)},
    };
    return colors[rarity] ?? colors['COMMON']!;
  }
}
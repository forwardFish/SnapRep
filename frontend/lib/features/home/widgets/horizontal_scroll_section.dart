import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HorizontalScrollSection<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) getTitle;
  final String? Function(T) getImageUrl;
  final VoidCallback? Function(T) onItemTap;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;

  const HorizontalScrollSection({
    super.key,
    required this.title,
    required this.items,
    required this.getTitle,
    required this.getImageUrl,
    required this.onItemTap,
    this.isLoading = false,
    this.error,
    this.onRetry,
  });

  @override
  State<HorizontalScrollSection<T>> createState() => _HorizontalScrollSectionState<T>();
}

class _HorizontalScrollSectionState<T> extends State<HorizontalScrollSection<T>> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Content
          if (widget.isLoading)
            _buildLoadingState()
          else if (widget.error != null)
            _buildErrorState()
          else if (widget.items.isEmpty)
            _buildEmptyState()
          else
            _buildItemsList(),

          // Indicators
          if (!widget.isLoading && widget.error == null && widget.items.isNotEmpty)
            _buildIndicators(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 140, // Updated to match new card height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: 3,
        itemBuilder: (context, index) => Container(
          width: 160, // Updated to match new card width
          height: 140, // Updated to match new card height
          margin: EdgeInsets.only(right: index < 2 ? 16 : 0),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 140, // Updated to match new card height
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[600]),
            const SizedBox(height: 4),
            Text(
              'Failed to load ${widget.title.toLowerCase()}',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 12,
              ),
            ),
            if (widget.onRetry != null)
              TextButton(
                onPressed: widget.onRetry,
                child: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 140, // Updated to match new card height
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          'No ${widget.title.toLowerCase()} available',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return SizedBox(
      height: 140, // Increased height to match HTML reference
      child: ListView.builder(
        controller: _scrollController, // Use scroll controller
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 24, right: 8), // Left align to match section title
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          final item = widget.items[index];
          return Container(
            margin: EdgeInsets.only(right: index < widget.items.length - 1 ? 16 : 16),
            child: _buildItemCard(item),
          );
        },
      ),
    );
  }

  Widget _buildItemCard(T item) {
    final imageUrl = widget.getImageUrl(item);
    final title = widget.getTitle(item);
    final onTap = widget.onItemTap(item);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160, // Increased width to match HTML reference
        height: 140, // Increased height to match HTML reference
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background Image
              if (imageUrl != null)
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                )
              else
                Positioned.fill(
                  child: Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                ),

              // White overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.2),
                      ],
                    ),
                  ),
                ),
              ),

              // Label
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700), // Yellow background
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A), // Premium black text
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicators() {
    if (widget.items.length <= 4) return const SizedBox.shrink(); // Only show indicators for more than 4 items

    return Container(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          (widget.items.length / 4).ceil(), // Show one indicator per group of 4 items
          (index) => Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == 0 ? const Color(0xFFFFD700) : const Color(0xFFE5E7EB),
            ),
          ),
        ),
      ),
    );
  }
}
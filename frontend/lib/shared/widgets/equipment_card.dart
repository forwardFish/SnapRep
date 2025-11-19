import 'package:flutter/material.dart';
import '../../core/models/equipment.dart';

/// 物品选择卡片组件
class EquipmentCard extends StatelessWidget {
  final Equipment equipment;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool isCompact;

  const EquipmentCard({
    super.key,
    required this.equipment,
    this.isSelected = false,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6C5CE7).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6C5CE7)
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 8 : 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 物品图标
              Container(
                width: isCompact ? 40 : 48,
                height: isCompact ? 40 : 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6C5CE7)
                      : Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: equipment.iconUrl != null
                    ? ClipOval(
                        child: Image.network(
                          equipment.iconUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            _getEquipmentIcon(equipment.category),
                            size: isCompact ? 20 : 24,
                            color: isSelected ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      )
                    : Icon(
                        _getEquipmentIcon(equipment.category),
                        size: isCompact ? 20 : 24,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
              ),

              SizedBox(height: isCompact ? 6 : 8),

              // 物品名称
              Text(
                equipment.name,
                style: TextStyle(
                  fontSize: isCompact ? 11 : 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF6C5CE7) : Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getEquipmentIcon(String category) {
    switch (category.toUpperCase()) {
      case 'NONE':
        return Icons.accessible;
      case 'FURNITURE':
        return Icons.chair;
      case 'WALL':
        return Icons.border_outer;
      case 'BOTTLE':
        return Icons.water_drop;
      case 'BAG':
        return Icons.backpack;
      case 'STAIRS':
        return Icons.stairs;
      case 'FABRIC':
        return Icons.dry_cleaning;
      case 'STICK':
        return Icons.straighten;
      case 'OUTDOOR':
        return Icons.nature;
      case 'CREATIVE':
        return Icons.lightbulb_outline;
      default:
        return Icons.fitness_center;
    }
  }
}

/// 已选择物品的芯片组件
class SelectedEquipmentChip extends StatelessWidget {
  final Equipment equipment;
  final VoidCallback? onRemove;

  const SelectedEquipmentChip({
    super.key,
    required this.equipment,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF6C5CE7).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6C5CE7).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getEquipmentIcon(equipment.category),
            size: 16,
            color: const Color(0xFF6C5CE7),
          ),
          const SizedBox(width: 6),
          Text(
            equipment.name,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6C5CE7),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(
                Icons.close,
                size: 16,
                color: Color(0xFF6C5CE7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getEquipmentIcon(String category) {
    switch (category.toUpperCase()) {
      case 'NONE':
        return Icons.accessible;
      case 'FURNITURE':
        return Icons.chair;
      case 'WALL':
        return Icons.border_outer;
      case 'BOTTLE':
        return Icons.water_drop;
      case 'BAG':
        return Icons.backpack;
      case 'STAIRS':
        return Icons.stairs;
      case 'FABRIC':
        return Icons.dry_cleaning;
      case 'STICK':
        return Icons.straighten;
      case 'OUTDOOR':
        return Icons.nature;
      case 'CREATIVE':
        return Icons.lightbulb_outline;
      default:
        return Icons.fitness_center;
    }
  }
}

/// 场景卡片组件
class ScenarioCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  const ScenarioCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withOpacity(0.3)
                  : Colors.black12,
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 图标
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected ? color : color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 30,
                color: isSelected ? Colors.white : color,
              ),
            ),

            const SizedBox(height: 12),

            // 标题
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 4),

            // 副标题
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// AI识别结果卡片
class AIRecognitionResultCard extends StatelessWidget {
  final Equipment equipment;
  final bool isSelected;
  final double confidence;
  final VoidCallback? onTap;

  const AIRecognitionResultCard({
    super.key,
    required this.equipment,
    this.isSelected = false,
    required this.confidence,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4CAF50).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4CAF50)
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // 置信度指示器
              Row(
                children: [
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getConfidenceColor(confidence).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(confidence * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 10,
                        color: _getConfidenceColor(confidence),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 物品图标
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF4CAF50)
                      : Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getEquipmentIcon(equipment.category),
                  size: 24,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
              ),

              const SizedBox(height: 8),

              // 物品名称
              Text(
                equipment.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? const Color(0xFF4CAF50)
                      : Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // AI识别标识
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.smart_toy,
                      size: 10,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 2),
                    const Text(
                      'AI识别',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return const Color(0xFF4CAF50);
    if (confidence >= 0.6) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  IconData _getEquipmentIcon(String category) {
    switch (category.toUpperCase()) {
      case 'NONE':
        return Icons.accessible;
      case 'FURNITURE':
        return Icons.chair;
      case 'WALL':
        return Icons.border_outer;
      case 'BOTTLE':
        return Icons.water_drop;
      case 'BAG':
        return Icons.backpack;
      case 'STAIRS':
        return Icons.stairs;
      case 'FABRIC':
        return Icons.dry_cleaning;
      case 'STICK':
        return Icons.straighten;
      case 'OUTDOOR':
        return Icons.nature;
      case 'CREATIVE':
        return Icons.lightbulb_outline;
      default:
        return Icons.fitness_center;
    }
  }
}
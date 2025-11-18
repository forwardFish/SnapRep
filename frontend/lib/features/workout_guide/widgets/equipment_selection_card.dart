import 'package:flutter/material.dart';
import '../../../core/models/equipment.dart';

/// 器材选择卡片组件
/// 用于显示可选运动器材
class EquipmentSelectionCard extends StatelessWidget {
  final Equipment equipment;
  final bool isSelected;
  final VoidCallback onTap;

  const EquipmentSelectionCard({
    super.key,
    required this.equipment,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getEquipmentGradientStart(),
              _getEquipmentGradientEnd(),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                ? const Color(0xFFFFD700).withOpacity(0.3)
                : Colors.black.withOpacity(0.06),
              blurRadius: isSelected ? 16 : 8,
              spreadRadius: 0,
              offset: Offset(0, isSelected ? 6 : 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 背景渐变覆盖
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.2),
                  ],
                ),
              ),
            ),

            // 内容
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge 标签
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      equipment.code.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // 器材名称
                  Text(
                    equipment.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 2),

                  // 器材描述
                  Text(
                    _getEquipmentDescription(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 10,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // 选中状态指示器
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD700),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 获取器材渐变起始色
  Color _getEquipmentGradientStart() {
    switch (equipment.category.toLowerCase()) {
      case 'furniture':
        return const Color(0xFF8E44AD); // 紫色 - 家具
      case 'wall':
        return const Color(0xFF34495E); // 深灰色 - 墙面
      case 'carry':
        return const Color(0xFF3498DB); // 蓝色 - 便携
      case 'bodyweight':
        return const Color(0xFF27AE60); // 绿色 - 徒手
      default:
        return const Color(0xFF95A5A6); // 默认灰色
    }
  }

  /// 获取器材渐变结束色
  Color _getEquipmentGradientEnd() {
    switch (equipment.category.toLowerCase()) {
      case 'furniture':
        return const Color(0xFF9B59B6); // 浅紫色
      case 'wall':
        return const Color(0xFF5D6D7E); // 浅灰色
      case 'carry':
        return const Color(0xFF5DADE2); // 浅蓝色
      case 'bodyweight':
        return const Color(0xFF58D68D); // 浅绿色
      default:
        return const Color(0xFFBDC3C7); // 浅灰色
    }
  }

  /// 获取器材描述
  String _getEquipmentDescription() {
    switch (equipment.code.toLowerCase()) {
      case 'chair':
        return 'Seated exercises\nSupport & stability';
      case 'wall':
        return 'Wall-assisted\nBalance training';
      case 'hands_free':
      case 'bodyweight':
        return 'Pure bodyweight\nAnywhere, anytime';
      case 'bottle':
      case 'water_bottle':
        return 'Light weights\nResistance training';
      default:
        return '${equipment.category}\ntraining';
    }
  }
}
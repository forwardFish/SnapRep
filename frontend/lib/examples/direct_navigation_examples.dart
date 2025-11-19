// ==========================================
// 示例：首页器材点击直接跳转配置
// ==========================================

import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

/// 首页器材九宫格示例
class HomeEquipmentGrid extends StatelessWidget {
  const HomeEquipmentGrid({super.key});

  // 器材数据
  static final List<Map<String, dynamic>> equipments = [
    {
      'code': 'chair',
      'name': '椅子',
      'icon': Icons.chair,
      'color': const Color(0xFF4A90E2),
    },
    {
      'code': 'wall',
      'name': '墙面',
      'icon': Icons.crop_din, // 使用矩形图标代替wall
      'color': const Color(0xFF7ED321),
    },
    {
      'code': 'sofa',
      'name': '沙发',
      'icon': Icons.weekend,
      'color': const Color(0xFFD0021B),
    },
    {
      'code': 'bottle',
      'name': '水瓶',
      'icon': Icons.water_drop,
      'color': const Color(0xFF50E3C2),
    },
    {
      'code': 'stairs',
      'name': '楼梯',
      'icon': Icons.stairs,
      'color': const Color(0xFF9013FE),
    },
    {
      'code': 'hands_free',
      'name': '空手',
      'icon': Icons.back_hand,
      'color': const Color(0xFFFF9800),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: equipments.length,
      itemBuilder: (context, index) {
        final equipment = equipments[index];
        return EquipmentTile(
          equipment: equipment,
          onTap: () => _onEquipmentTap(context, equipment['code']),
        );
      },
    );
  }

  /// 器材点击处理 - 直接跳转到动作结果页
  void _onEquipmentTap(BuildContext context, String equipmentCode) {
    // 使用配置好的直接跳转方法
    AppRoutes.equipmentQuickSelect(context, equipmentCode: equipmentCode);
  }
}

/// 器材瓦片组件
class EquipmentTile extends StatelessWidget {
  final Map<String, dynamic> equipment;
  final VoidCallback onTap;

  const EquipmentTile({
    super.key,
    required this.equipment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: equipment['color'].withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                equipment['icon'],
                color: equipment['color'],
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              equipment['name'],
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 示例：挑战页面器材点击直接跳转配置
// ==========================================

/// 挑战详情页面器材选择示例
class ChallengeDetailEquipmentList extends StatelessWidget {
  final String challengeId;

  const ChallengeDetailEquipmentList({
    super.key,
    required this.challengeId,
  });

  // 挑战器材数据
  static final List<Map<String, dynamic>> challengeEquipments = [
    {
      'code': 'chair',
      'name': '椅子挑战',
      'description': '3分钟椅子训练',
      'difficulty': 'BEGINNER',
      'duration': '3分钟',
    },
    {
      'code': 'wall',
      'name': '墙面挑战',
      'description': '5分钟墙面拉伸',
      'difficulty': 'INTERMEDIATE',
      'duration': '5分钟',
    },
    {
      'code': 'bottle',
      'name': '水瓶挑战',
      'description': '10分钟力量训练',
      'difficulty': 'ADVANCED',
      'duration': '10分钟',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '选择器材开始挑战',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ...challengeEquipments.map((equipment) =>
          ChallengeEquipmentCard(
            equipment: equipment,
            onTap: () => _onChallengeEquipmentTap(context, equipment['code']),
          ),
        ).toList(),
      ],
    );
  }

  /// 挑战器材点击处理 - 直接跳转到动作结果页
  void _onChallengeEquipmentTap(BuildContext context, String equipmentCode) {
    // 使用配置好的挑战直接跳转方法
    AppRoutes.challengeQuickJoin(
      context,
      challengeId: challengeId,
      equipmentCode: equipmentCode,
    );
  }
}

/// 挑战器材卡片组件
class ChallengeEquipmentCard extends StatelessWidget {
  final Map<String, dynamic> equipment;
  final VoidCallback onTap;

  const ChallengeEquipmentCard({
    super.key,
    required this.equipment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 器材图标
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: Color(0xFF6C5CE7),
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // 挑战信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        equipment['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        equipment['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildTag(equipment['difficulty']),
                          const SizedBox(width: 8),
                          _buildTag(equipment['duration']),
                        ],
                      ),
                    ],
                  ),
                ),

                // 箭头图标
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
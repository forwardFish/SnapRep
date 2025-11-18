import 'package:flutter/material.dart';
import '../../../core/models/scenario.dart';

/// 场景选择卡片组件
/// 用于显示运动场景选项（办公室、家庭、公园等）
class ScenarioSelectionCard extends StatelessWidget {
  final Scenario scenario;
  final bool isSelected;
  final VoidCallback onTap;

  const ScenarioSelectionCard({
    super.key,
    required this.scenario,
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
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getScenarioGradientStart(),
              _getScenarioGradientEnd(),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                ? const Color(0xFFFFD700).withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
              blurRadius: isSelected ? 20 : 12,
              spreadRadius: 0,
              offset: Offset(0, isSelected ? 8 : 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 背景渐变覆盖
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),

            // 内容
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge 标签
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      scenario.code.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // 场景名称
                  Text(
                    scenario.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // 场景描述
                  Text(
                    scenario.description ?? _getScenarioDescription(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      height: 1.3,
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
                top: 12,
                right: 12,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD700),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 获取场景渐变起始色
  Color _getScenarioGradientStart() {
    switch (scenario.code.toLowerCase()) {
      case 'office':
        return const Color(0xFF9B59B6); // 紫色 - 办公室
      case 'home':
      case 'living_room':
        return const Color(0xFF3498DB); // 蓝色 - 家
      case 'park':
        return const Color(0xFF27AE60); // 绿色 - 公园
      case 'gym':
        return const Color(0xFFE67E22); // 橙色 - 健身房
      default:
        return const Color(0xFF95A5A6); // 灰色 - 默认
    }
  }

  /// 获取场景渐变结束色
  Color _getScenarioGradientEnd() {
    switch (scenario.code.toLowerCase()) {
      case 'office':
        return const Color(0xFF8E44AD); // 深紫色
      case 'home':
      case 'living_room':
        return const Color(0xFF2980B9); // 深蓝色
      case 'park':
        return const Color(0xFF229954); // 深绿色
      case 'gym':
        return const Color(0xFFD35400); // 深橙色
      default:
        return const Color(0xFF7F8C8D); // 深灰色
    }
  }

  /// 获取场景描述
  String _getScenarioDescription() {
    switch (scenario.code.toLowerCase()) {
      case 'office':
        return 'Silent exercises\nNo equipment needed';
      case 'home':
      case 'living_room':
        return 'Comfortable space\nRelaxed training';
      case 'park':
        return 'Fresh air workout\nOutdoor activities';
      case 'gym':
        return 'Professional equipment\nFull body training';
      default:
        return 'Flexible training\nAdapt to environment';
    }
  }
}
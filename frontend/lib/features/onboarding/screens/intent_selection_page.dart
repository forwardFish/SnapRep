import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/workout_config_provider.dart';
import '../../../shared/widgets/step_progress_indicator.dart';

/// 运动意图选择页面
/// 实现完整引导路径的第三步：运动意图选择
class IntentSelectionPage extends StatelessWidget {
  const IntentSelectionPage({super.key});

  final List<IntentOption> intents = const [
    IntentOption(
      type: 'RELAX',
      title: '放松一下',
      subtitle: '缓解疲劳，轻松舒展',
      icon: Icons.spa,
      color: Color(0xFF9013FE),
      description: '适合工作间歇，缓解肌肉紧张和身心疲劳',
      benefits: ['缓解肌肉紧张', '减轻压力', '改善循环'],
      duration: '5-10分钟',
    ),
    IntentOption(
      type: 'STRETCH',
      title: '拉伸运动',
      subtitle: '增加柔韧性，改善姿态',
      icon: Icons.accessibility_new,
      color: Color(0xFF00BCD4),
      description: '改善身体柔韧性和活动范围，纠正不良姿态',
      benefits: ['提升柔韧性', '改善姿态', '增加活动度'],
      duration: '10-15分钟',
    ),
    IntentOption(
      type: 'MODERATE',
      title: '适度运动',
      subtitle: '提升心率，活跃身心',
      icon: Icons.directions_run,
      color: Color(0xFF4CAF50),
      description: '轻微提升心率，增加身体活力和代谢',
      benefits: ['提升心率', '增强体能', '燃烧卡路里'],
      duration: '15-20分钟',
    ),
    IntentOption(
      type: 'STRENGTH',
      title: '力量训练',
      subtitle: '增强肌肉，挑战自我',
      icon: Icons.fitness_center,
      color: Color(0xFFFF5722),
      description: '提升肌肉力量和身体素质，挑战身体极限',
      benefits: ['增强肌肉', '提升力量', '塑造体形'],
      duration: '20-30分钟',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // 自定义AppBar
            _buildCustomAppBar(context),

            // 主要内容区域
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // 页面标题和描述
                    const Text(
                      '今天想要什么样的训练？',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      '根据你的需求和状态，我们为你推荐最适合的动作组合',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 意图选择列表
                    Expanded(
                      child: ListView.builder(
                        itemCount: intents.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: IntentCard(
                            intent: intents[index],
                            isSelected: context.watch<WorkoutConfigProvider>()
                                .selectedIntent == intents[index].type,
                            onTap: () => _selectIntent(context, intents[index]),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 底部继续按钮
            _buildBottomContinueButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 导航栏
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text(
                  '运动意图',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // 平衡布局
            ],
          ),

          const SizedBox(height: 16),

          // 进度指示器
          const StepProgressIndicator(currentStep: 2, totalSteps: 3),
        ],
      ),
    );
  }

  Widget _buildBottomContinueButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Consumer<WorkoutConfigProvider>(
          builder: (context, provider, child) {
            final hasSelection = provider.selectedIntent != null;

            return SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: hasSelection ? () => _navigateToMuscleSelection(context) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasSelection
                      ? const Color(0xFF6C5CE7)
                      : Colors.grey[300],
                  foregroundColor: hasSelection
                      ? Colors.white
                      : Colors.grey[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: hasSelection ? 4 : 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      hasSelection ? '继续选择部位' : '请选择运动意图',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (hasSelection) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _selectIntent(BuildContext context, IntentOption intent) {
    // 触觉反馈
    // HapticFeedback.lightImpact();

    // 更新状态
    context.read<WorkoutConfigProvider>().setIntent(intent.type);

    // 显示选择反馈
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(intent.icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('已选择${intent.title}'),
          ],
        ),
        backgroundColor: intent.color,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _navigateToMuscleSelection(BuildContext context) {
    Navigator.pushNamed(context, '/muscle-selection');
  }
}

/// 运动意图选项数据模型
class IntentOption {
  final String type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String description;
  final List<String> benefits;
  final String duration;

  const IntentOption({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.description,
    required this.benefits,
    required this.duration,
  });
}

/// 意图选择卡片组件
class IntentCard extends StatelessWidget {
  final IntentOption intent;
  final bool isSelected;
  final VoidCallback onTap;

  const IntentCard({
    super.key,
    required this.intent,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected
              ? intent.color.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? intent.color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? intent.color.withOpacity(0.3)
                  : Colors.black.withOpacity(0.06),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // 左侧图标
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isSelected ? intent.color : intent.color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                intent.icon,
                size: 32,
                color: isSelected ? Colors.white : intent.color,
              ),
            ),

            const SizedBox(width: 20),

            // 右侧内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题和选择状态
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          intent.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? intent.color : Colors.black87,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: intent.color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                '已选择',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // 副标题
                  Text(
                    intent.subtitle,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 描述
                  Text(
                    intent.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // 好处标签和时长
                  Row(
                    children: [
                      // 好处标签
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: intent.benefits.take(2).map((benefit) =>
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: intent.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                benefit,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: intent.color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ).toList(),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // 预计时长
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              intent.duration,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
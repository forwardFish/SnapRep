import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/workout_config_provider.dart';
import '../../../shared/widgets/step_progress_indicator.dart';

/// 肌肉目标选择页面
/// 实现完整引导路径的最后一步：目标部位选择
class MuscleTargetPage extends StatelessWidget {
  const MuscleTargetPage({super.key});

  final List<MuscleGroup> muscleGroups = const [
    MuscleGroup(
      muscle: 'CHEST',
      name: '胸部',
      icon: Icons.favorite,
      color: Color(0xFFE91E63),
      benefits: ['改善体态', '增强上肢力量', '塑造胸肌线条'],
      description: '胸大肌训练，改善驼背，增强上肢推力',
      exerciseCount: 8,
    ),
    MuscleGroup(
      muscle: 'BACK',
      name: '背部',
      icon: Icons.accessibility,
      color: Color(0xFF3F51B5),
      benefits: ['缓解肩颈疲劳', '改善驼背', '增强拉力'],
      description: '背阔肌和菱形肌训练，改善姿态问题',
      exerciseCount: 12,
    ),
    MuscleGroup(
      muscle: 'LEGS',
      name: '腿部',
      icon: Icons.directions_walk,
      color: Color(0xFF4CAF50),
      benefits: ['提升下肢力量', '改善循环', '燃烧卡路里'],
      description: '腿部肌群综合训练，提升基础代谢',
      exerciseCount: 15,
    ),
    MuscleGroup(
      muscle: 'CORE',
      name: '核心',
      icon: Icons.center_focus_strong,
      color: Color(0xFFFF9800),
      benefits: ['稳定腰椎', '提升平衡', '改善体态'],
      description: '腹肌和深层核心肌群，身体稳定基础',
      exerciseCount: 10,
    ),
    MuscleGroup(
      muscle: 'ARMS',
      name: '手臂',
      icon: Icons.fitness_center,
      color: Color(0xFF9C27B0),
      benefits: ['增强臂力', '塑造线条', '提升握力'],
      description: '二头肌和三头肌训练，增强上肢力量',
      exerciseCount: 6,
    ),
    MuscleGroup(
      muscle: 'FULL_BODY',
      name: '全身',
      icon: Icons.accessibility_new,
      color: Color(0xFF607D8B),
      benefits: ['全面协调', '综合提升', '高效燃脂'],
      description: '多肌群复合动作，全身协调发展',
      exerciseCount: 20,
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
                      '选择重点锻炼部位',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      '可选择多个部位，我们会根据你的选择均衡安排训练动作',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 已选择部位展示
                    Consumer<WorkoutConfigProvider>(
                      builder: (context, provider, child) {
                        if (provider.targetMuscles.isNotEmpty) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '已选择 ${provider.targetMuscles.length} 个部位',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: provider.targetMuscles.map((muscle) {
                                  final group = muscleGroups.firstWhere(
                                    (g) => g.muscle == muscle,
                                    orElse: () => muscleGroups.first,
                                  );
                                  return _buildSelectedMuscleChip(group, () {
                                    provider.toggleMuscle(muscle);
                                  });
                                }).toList(),
                              ),
                              const SizedBox(height: 24),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    // 肌肉群选择列表
                    Expanded(
                      child: ListView.builder(
                        itemCount: muscleGroups.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Consumer<WorkoutConfigProvider>(
                            builder: (context, provider, child) {
                              final group = muscleGroups[index];
                              final isSelected = provider.targetMuscles.contains(group.muscle);

                              return MuscleGroupCard(
                                muscleGroup: group,
                                isSelected: isSelected,
                                onTap: () => _toggleMuscle(context, group.muscle),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 底部生成按钮
            _buildBottomGenerateButton(),
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
                  '目标部位',
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
          const StepProgressIndicator(currentStep: 3, totalSteps: 3),
        ],
      ),
    );
  }

  Widget _buildSelectedMuscleChip(MuscleGroup group, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: group.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: group.color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            group.icon,
            size: 16,
            color: group.color,
          ),
          const SizedBox(width: 6),
          Text(
            group.name,
            style: TextStyle(
              fontSize: 14,
              color: group.color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 16,
              color: group.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomGenerateButton() {
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
            final hasSelection = provider.targetMuscles.isNotEmpty;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 选择摘要
                if (hasSelection)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF6C5CE7).withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 20,
                              color: Color(0xFF6C5CE7),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '配置完成',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6C5CE7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.getSelectionSummary(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                // 生成训练按钮
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: hasSelection ? () => _generateWorkout(context) : null,
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
                        Icon(
                          hasSelection ? Icons.auto_awesome : Icons.help_outline,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasSelection ? '生成我的专属训练 🎯' : '请至少选择一个部位',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _toggleMuscle(BuildContext context, String muscle) {
    // 触觉反馈
    // HapticFeedback.lightImpact();

    // 更新状态
    context.read<WorkoutConfigProvider>().toggleMuscle(muscle);

    final provider = context.read<WorkoutConfigProvider>();
    final isSelected = provider.targetMuscles.contains(muscle);
    final group = muscleGroups.firstWhere((g) => g.muscle == muscle);

    // 显示选择反馈
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(group.icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(isSelected ? '已添加${group.name}' : '已移除${group.name}'),
          ],
        ),
        backgroundColor: group.color,
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _generateWorkout(BuildContext context) {
    // 显示加载提示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF6C5CE7)),
                SizedBox(height: 16),
                Text(
                  '正在生成专属训练...',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // 模拟生成过程
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // 关闭加载对话框
      Navigator.pushNamed(context, '/workout-result');
    });
  }
}

/// 肌肉群数据模型
class MuscleGroup {
  final String muscle;
  final String name;
  final IconData icon;
  final Color color;
  final List<String> benefits;
  final String description;
  final int exerciseCount;

  const MuscleGroup({
    required this.muscle,
    required this.name,
    required this.icon,
    required this.color,
    required this.benefits,
    required this.description,
    required this.exerciseCount,
  });
}

/// 肌肉群选择卡片组件
class MuscleGroupCard extends StatelessWidget {
  final MuscleGroup muscleGroup;
  final bool isSelected;
  final VoidCallback onTap;

  const MuscleGroupCard({
    super.key,
    required this.muscleGroup,
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? muscleGroup.color.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? muscleGroup.color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? muscleGroup.color.withOpacity(0.25)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // 左侧图标和选择状态
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? muscleGroup.color
                    : muscleGroup.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    muscleGroup.icon,
                    size: 28,
                    color: isSelected ? Colors.white : muscleGroup.color,
                  ),
                  if (isSelected)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          size: 12,
                          color: muscleGroup.color,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // 右侧内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题行
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          muscleGroup.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? muscleGroup.color : Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: muscleGroup.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${muscleGroup.exerciseCount}个动作',
                          style: TextStyle(
                            fontSize: 11,
                            color: muscleGroup.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // 描述
                  Text(
                    muscleGroup.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 好处标签
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: muscleGroup.benefits.take(3).map((benefit) =>
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: muscleGroup.color.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          benefit,
                          style: TextStyle(
                            fontSize: 11,
                            color: muscleGroup.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ).toList(),
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
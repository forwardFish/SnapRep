import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/workout_config_provider.dart';
import '../../../shared/widgets/step_progress_indicator.dart';

/// 场景选择页面
/// 实现完整引导路径的第一步：场景选择
class ScenarioSelectionPage extends StatelessWidget {
  const ScenarioSelectionPage({super.key});

  final List<ScenarioOption> scenarios = const [
    ScenarioOption(
      code: 'office',
      title: '办公室',
      subtitle: '工作间隙轻松运动',
      icon: Icons.business,
      color: Color(0xFF4A90E2),
      description: '适合有限空间的办公环境，专注缓解久坐疲劳',
    ),
    ScenarioOption(
      code: 'home',
      title: '居家',
      subtitle: '舒适家中健身',
      icon: Icons.home,
      color: Color(0xFF7ED321),
      description: '利用家居物品进行全面身体锻炼',
    ),
    ScenarioOption(
      code: 'travel',
      title: '出行',
      subtitle: '旅途中保持活力',
      icon: Icons.train,
      color: Color(0xFFD0021B),
      description: '适合酒店、车站等临时场所的便携运动',
    ),
    ScenarioOption(
      code: 'outdoor',
      title: '户外',
      subtitle: '自然环境中运动',
      icon: Icons.park,
      color: Color(0xFF50E3C2),
      description: '利用户外环境和设施进行多样化训练',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('选择你的场景'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 进度指示器
              const StepProgressIndicator(currentStep: 1, totalSteps: 3),

              const SizedBox(height: 24),

              // 页面标题和描述
              const Text(
                '选择你的运动场景',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                '选择最符合你当前环境的场景，我们会推荐适合的器材和动作',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 32),

              // 场景选择网格
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: scenarios.length,
                  itemBuilder: (context, index) => ScenarioCard(
                    scenario: scenarios[index],
                    isSelected: context.watch<WorkoutConfigProvider>().selectedScenario == scenarios[index].code,
                    onTap: () => _selectScenario(context, scenarios[index]),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 底部继续按钮
              Consumer<WorkoutConfigProvider>(
                builder: (context, provider, child) {
                  final hasSelection = provider.selectedScenario != null;

                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: hasSelection ? () => _navigateToEquipmentSelection(context) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasSelection ? const Color(0xFF6C5CE7) : Colors.grey[300],
                        foregroundColor: hasSelection ? Colors.white : Colors.grey[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: hasSelection ? 4 : 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            hasSelection ? '继续选择器材' : '请先选择场景',
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
            ],
          ),
        ),
      ),
    );
  }

  void _selectScenario(BuildContext context, ScenarioOption scenario) {
    // 触觉反馈
    _triggerHapticFeedback();

    // 更新状态
    context.read<WorkoutConfigProvider>().setScenario(scenario.code);

    // 显示选择反馈
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(scenario.icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('已选择${scenario.title}场景'),
          ],
        ),
        backgroundColor: scenario.color,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _navigateToEquipmentSelection(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/equipment-selection',
      arguments: {
        'scenarioCode': context.read<WorkoutConfigProvider>().selectedScenario,
      },
    );
  }

  void _triggerHapticFeedback() {
    // 轻微震动反馈
    // HapticFeedback.lightImpact();
  }
}

/// 场景选项数据模型
class ScenarioOption {
  final String code;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String description;

  const ScenarioOption({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.description,
  });
}

/// 场景选择卡片组件
class ScenarioCard extends StatelessWidget {
  final ScenarioOption scenario;
  final bool isSelected;
  final VoidCallback onTap;

  const ScenarioCard({
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
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? scenario.color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? scenario.color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? scenario.color.withOpacity(0.3) : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 12 : 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 场景图标
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected ? scenario.color : scenario.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                scenario.icon,
                size: 30,
                color: isSelected ? Colors.white : scenario.color,
              ),
            ),

            const SizedBox(height: 16),

            // 场景标题
            Text(
              scenario.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? scenario.color : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 6),

            // 场景副标题
            Text(
              scenario.subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            if (isSelected) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scenario.color,
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
          ],
        ),
      ),
    );
  }
}
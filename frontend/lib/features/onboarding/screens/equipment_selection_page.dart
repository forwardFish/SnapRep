import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/equipment.dart';
import '../../../core/providers/workout_config_provider.dart';
import '../../../core/services/equipment_service.dart';
import '../../../shared/widgets/step_progress_indicator.dart';
import '../../../shared/widgets/equipment_card.dart';

/// 器材选择页面
/// 实现完整引导路径的第二步：器材选择
class EquipmentSelectionPage extends StatefulWidget {
  final String? scenarioCode;

  const EquipmentSelectionPage({super.key, this.scenarioCode});

  @override
  State<EquipmentSelectionPage> createState() => _EquipmentSelectionPageState();
}

class _EquipmentSelectionPageState extends State<EquipmentSelectionPage> {
  final EquipmentService _equipmentService = EquipmentService();
  List<Equipment> _availableEquipment = [];
  List<Equipment> _selectedEquipment = [];
  bool _isLoading = true;
  String? _error;

  // 场景信息映射
  static const Map<String, ScenarioInfo> _scenarioInfoMap = {
    'office': ScenarioInfo(
      title: '办公室',
      subtitle: '工作环境中的可用物品',
      icon: Icons.business,
      color: Color(0xFF4A90E2),
    ),
    'home': ScenarioInfo(
      title: '居家',
      subtitle: '家中常见的生活用品',
      icon: Icons.home,
      color: Color(0xFF7ED321),
    ),
    'travel': ScenarioInfo(
      title: '出行',
      subtitle: '旅途中的便携物品',
      icon: Icons.train,
      color: Color(0xFFD0021B),
    ),
    'outdoor': ScenarioInfo(
      title: '户外',
      subtitle: '户外环境中的设施',
      icon: Icons.park,
      color: Color(0xFF50E3C2),
    ),
  };

  @override
  void initState() {
    super.initState();
    _loadEquipment();
    // 从Provider中获取已选择的器材
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<WorkoutConfigProvider>();
      setState(() {
        _selectedEquipment = List.from(provider.selectedEquipment);
      });
    });
  }

  Future<void> _loadEquipment() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // 根据场景获取推荐器材
      final equipment = await _equipmentService.getEquipmentByScenario(
        widget.scenarioCode ?? 'office',
      );

      setState(() {
        _availableEquipment = equipment;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scenarioInfo = _scenarioInfoMap[widget.scenarioCode] ??
        _scenarioInfoMap['office']!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // 自定义AppBar
            _buildCustomAppBar(context, scenarioInfo),

            // 场景头部信息
            _buildScenarioHeader(scenarioInfo),

            // 已选择器材横向滚动
            if (_selectedEquipment.isNotEmpty)
              _buildSelectedEquipmentBar(),

            // 主要内容区域
            Expanded(
              child: _buildMainContent(),
            ),

            // 底部继续按钮
            _buildBottomContinueButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context, ScenarioInfo scenarioInfo) {
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
                  '选择器材',
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

  Widget _buildScenarioHeader(ScenarioInfo scenarioInfo) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scenarioInfo.color.withOpacity(0.8),
            scenarioInfo.color,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              scenarioInfo.icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scenarioInfo.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  scenarioInfo.subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedEquipmentBar() {
    return Container(
      height: 100,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '已选择 (${_selectedEquipment.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _selectedEquipment.length,
              itemBuilder: (context, index) => SelectedEquipmentChip(
                equipment: _selectedEquipment[index],
                onRemove: () => _removeEquipment(_selectedEquipment[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF6C5CE7)),
            SizedBox(height: 16),
            Text(
              '正在加载器材...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadEquipment,
              child: const Text('重新加载'),
            ),
          ],
        ),
      );
    }

    if (_availableEquipment.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '暂无可用器材',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const Text(
            '可选器材',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: _availableEquipment.length,
            itemBuilder: (context, index) {
              final equipment = _availableEquipment[index];
              final isSelected = _selectedEquipment.any((e) => e.id == equipment.id);

              return EquipmentCard(
                equipment: equipment,
                isSelected: isSelected,
                onTap: () => _toggleEquipment(equipment),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomContinueButton() {
    return Container(
      padding: const EdgeInsets.all(16),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // AI识别按钮
            if (_selectedEquipment.isEmpty)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _openAIRecognition,
                  icon: const Icon(Icons.camera_alt, size: 20),
                  label: const Text('用AI识别器材'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF6C5CE7)),
                    foregroundColor: const Color(0xFF6C5CE7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            if (_selectedEquipment.isNotEmpty) const SizedBox(height: 12),

            // 继续按钮
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedEquipment.isNotEmpty ? _navigateToIntentSelection : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedEquipment.isNotEmpty
                      ? const Color(0xFF6C5CE7)
                      : Colors.grey[300],
                  foregroundColor: _selectedEquipment.isNotEmpty
                      ? Colors.white
                      : Colors.grey[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: _selectedEquipment.isNotEmpty ? 4 : 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _selectedEquipment.isEmpty
                          ? '请选择至少一个器材'
                          : '继续 (${_selectedEquipment.length}个器材)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_selectedEquipment.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleEquipment(Equipment equipment) {
    setState(() {
      final isSelected = _selectedEquipment.any((e) => e.id == equipment.id);

      if (isSelected) {
        _selectedEquipment.removeWhere((e) => e.id == equipment.id);
      } else {
        _selectedEquipment.add(equipment);
      }
    });

    // 更新Provider状态
    context.read<WorkoutConfigProvider>().setEquipment(_selectedEquipment);

    // 显示选择反馈
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _selectedEquipment.any((e) => e.id == equipment.id)
              ? '已添加 ${equipment.name}'
              : '已移除 ${equipment.name}',
        ),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _removeEquipment(Equipment equipment) {
    setState(() {
      _selectedEquipment.removeWhere((e) => e.id == equipment.id);
    });

    // 更新Provider状态
    context.read<WorkoutConfigProvider>().setEquipment(_selectedEquipment);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已移除 ${equipment.name}'),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _openAIRecognition() {
    Navigator.pushNamed(context, '/ai-recognition').then((result) {
      if (result != null && result is List<Equipment>) {
        setState(() {
          _selectedEquipment.addAll(result);
        });
        context.read<WorkoutConfigProvider>().setEquipment(_selectedEquipment);
      }
    });
  }

  void _navigateToIntentSelection() {
    Navigator.pushNamed(context, '/intent-selection');
  }
}

/// 场景信息模型
class ScenarioInfo {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const ScenarioInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/models/equipment.dart';
import '../../../core/providers/workout_config_provider.dart';
import '../../../core/services/equipment_service.dart';
import '../../../shared/widgets/equipment_card.dart';

/// AI识别页面
/// 实现AI识别路径：相机识别 → AI处理 → 结果确认
class AIRecognitionPage extends StatefulWidget {
  const AIRecognitionPage({super.key});

  @override
  State<AIRecognitionPage> createState() => _AIRecognitionPageState();
}

class _AIRecognitionPageState extends State<AIRecognitionPage> {
  final ImagePicker _picker = ImagePicker();
  final EquipmentService _equipmentService = EquipmentService();

  File? _selectedImage;
  List<Equipment> _recognizedEquipment = [];
  List<Equipment> _selectedEquipment = [];
  bool _isProcessing = false;
  String? _error;

  // 模拟识别置信度
  final Map<String, double> _confidenceMap = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AI识别器材',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          // 主要内容
          _buildMainContent(),

          // 加载遮罩
          if (_isProcessing) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_selectedImage == null) {
      return _buildImageSelectionView();
    }

    if (_recognizedEquipment.isEmpty && !_isProcessing) {
      return _buildImagePreviewView();
    }

    return _buildRecognitionResultView();
  }

  Widget _buildImageSelectionView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 主图标
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 60,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 32),

            // 标题
            const Text(
              'AI识别你的器材',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // 描述
            Text(
              '拍摄或选择包含运动器材的照片\n我们的AI会自动识别可用的器材',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 48),

            // 拍照按钮
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text(
                  '拍摄照片',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 相册选择按钮
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text(
                  '从相册选择',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 提示文字
            Row(
              children: [
                Icon(
                  Icons.tips_and_updates,
                  size: 20,
                  color: Colors.white.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '提示：确保器材在照片中清晰可见，光线充足效果更佳',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreviewView() {
    return Column(
      children: [
        // 图片预览
        Expanded(
          flex: 2,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: FileImage(_selectedImage!),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),

        // 底部控制区
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // 识别按钮
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _startRecognition,
                    icon: const Icon(Icons.smart_toy),
                    label: const Text(
                      '开始AI识别',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 重新选择按钮
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton.icon(
                    onPressed: _resetImage,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text(
                      '重新选择照片',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecognitionResultView() {
    return Column(
      children: [
        // 顶部成功提示
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI识别成功！',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '发现 ${_recognizedEquipment.length} 个可用器材',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 识别结果列表
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    '识别结果',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: _recognizedEquipment.length,
                    itemBuilder: (context, index) {
                      final equipment = _recognizedEquipment[index];
                      final isSelected = _selectedEquipment.any((e) => e.id == equipment.id);
                      final confidence = _confidenceMap[equipment.id] ?? 0.85;

                      return AIRecognitionResultCard(
                        equipment: equipment,
                        isSelected: isSelected,
                        confidence: confidence,
                        onTap: () => _toggleSelection(equipment),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // 底部按钮
        _buildBottomActions(),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 手动添加按钮
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _addManually,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  '手动添加其他器材',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 继续按钮
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedEquipment.isNotEmpty ? _continueWorkflow : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedEquipment.isNotEmpty
                      ? const Color(0xFF6C5CE7)
                      : Colors.grey[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _selectedEquipment.isEmpty
                      ? '请选择识别到的器材'
                      : '继续 (${_selectedEquipment.length}个器材)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF6C5CE7)),
                SizedBox(height: 20),
                Text(
                  'AI正在识别器材...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '这可能需要几秒钟时间',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
          _recognizedEquipment.clear();
          _selectedEquipment.clear();
          _error = null;
        });
      }
    } catch (e) {
      _showError('拍照失败: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _recognizedEquipment.clear();
          _selectedEquipment.clear();
          _error = null;
        });
      }
    } catch (e) {
      _showError('选择图片失败: $e');
    }
  }

  void _resetImage() {
    setState(() {
      _selectedImage = null;
      _recognizedEquipment.clear();
      _selectedEquipment.clear();
      _error = null;
    });
  }

  Future<void> _startRecognition() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      // 调用AI识别服务
      final recognizedEquipment = await _equipmentService
          .recognizeEquipmentFromImage(_selectedImage!.path);

      // 生成模拟置信度
      _confidenceMap.clear();
      for (final equipment in recognizedEquipment) {
        _confidenceMap[equipment.id] = 0.75 + (0.2 * (recognizedEquipment.indexOf(equipment) / recognizedEquipment.length));
      }

      setState(() {
        _recognizedEquipment = recognizedEquipment;
        _selectedEquipment = List.from(recognizedEquipment); // 默认全选
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _error = e.toString();
      });
      _showError('AI识别失败: $e');
    }
  }

  void _toggleSelection(Equipment equipment) {
    setState(() {
      final isSelected = _selectedEquipment.any((e) => e.id == equipment.id);

      if (isSelected) {
        _selectedEquipment.removeWhere((e) => e.id == equipment.id);
      } else {
        _selectedEquipment.add(equipment);
      }
    });

    // 显示反馈
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _selectedEquipment.any((e) => e.id == equipment.id)
              ? '已添加 ${equipment.name}'
              : '已移除 ${equipment.name}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black87,
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _addManually() {
    // 导航到手动选择器材页面
    Navigator.pushNamed(context, '/equipment-selection').then((result) {
      if (result != null && result is List<Equipment>) {
        setState(() {
          // 合并手动选择的器材
          for (final equipment in result) {
            if (!_selectedEquipment.any((e) => e.id == equipment.id)) {
              _selectedEquipment.add(equipment);
            }
          }
        });
      }
    });
  }

  void _continueWorkflow() {
    // 更新Provider状态
    context.read<WorkoutConfigProvider>().setEquipment(_selectedEquipment);

    // 返回选择的器材
    Navigator.pop(context, _selectedEquipment);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/workout_guide_provider.dart';
import '../../../core/services/equipment_service.dart';
import '../../../core/models/equipment.dart';
import '../../../routes/app_routes.dart';

/// Equipment Selection Page - Step 1b
/// Users select equipment based on their chosen scenario
class EquipmentSelectionPage extends StatefulWidget {
  final String? scenarioCode;

  const EquipmentSelectionPage({
    super.key,
    this.scenarioCode,
  });

  @override
  State<EquipmentSelectionPage> createState() => _EquipmentSelectionPageState();
}

class _EquipmentSelectionPageState extends State<EquipmentSelectionPage> {
  // Equipment selection related
  List<String> _selectedEquipment = [];

  // Backend data
  final EquipmentService _equipmentService = EquipmentService();
  List<Equipment> _availableEquipment = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEquipmentForScenario();
  }

  Future<void> _loadEquipmentForScenario() async {
    if (widget.scenarioCode == null) {
      setState(() {
        _error = 'No scenario selected';
        _isLoading = false;
      });
      return;
    }

    try {
      final equipment = await _equipmentService.getEquipmentByScenario(widget.scenarioCode!);
      if (mounted) {
        setState(() {
          _availableEquipment = equipment;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading equipment: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load equipment: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            _buildAppBar(),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress indicator
                    _buildProgressIndicator(),

                    const SizedBox(height: 24),

                    // Title section
                    _buildTitleSection(),

                    const SizedBox(height: 32),

                    // Content
                    Expanded(
                      child: _buildContent(),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom button area
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),

          const Spacer(),

          // Title
          const Text(
            'Workout Guide',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const Spacer(),

          // Placeholder for symmetry
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: const Color(0xFFFFD700),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: const Color(0xFFE0E0E0),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: const Color(0xFFE0E0E0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFFFD700),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '1',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'STEP 1',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Choose your\navailable equipment',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            height: 1.2,
            color: Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the equipment you have access to',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
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
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load equipment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    if (_availableEquipment.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No equipment available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No equipment found for this scenario',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Equipment',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),

          // Equipment horizontal list (matching original design)
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _availableEquipment.length,
              itemBuilder: (context, index) {
                final equipment = _availableEquipment[index];
                return Container(
                  width: 120,
                  margin: EdgeInsets.only(
                    right: index < _availableEquipment.length - 1 ? 12 : 0,
                  ),
                  child: _buildEquipmentCard(equipment),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedEquipment.isNotEmpty ? _onContinuePressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedEquipment.isNotEmpty ? const Color(0xFFFFD700) : Colors.grey.shade300,
              foregroundColor: _selectedEquipment.isNotEmpty ? Colors.white : Colors.grey.shade500,
              elevation: _selectedEquipment.isNotEmpty ? 8 : 0,
              shadowColor: _selectedEquipment.isNotEmpty ? const Color(0xFFFFD700).withOpacity(0.3) : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              minimumSize: const Size(0, 56),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEquipmentCard(Equipment equipment) {
    final isSelected = _selectedEquipment.contains(equipment.code);

    // Equipment data matching original design with emoji icons
    final equipmentIcons = {
      'chair': '🪑',
      'wall': '🧱',
      'hands_free': '💪',
      'resistance_band': '🎯',
      'dumbbells': '🏋️',
      'yoga_mat': '🧘',
      'kettlebell': '🏋️',
      'bench': '🪑',
      'pull_up_bar': '💪',
    };

    // Color mapping for equipment (matching original design)
    final colorMap = {
      'chair': const Color(0xFF8E44AD),
      'wall': const Color(0xFF34495E),
      'hands_free': const Color(0xFF27AE60),
      'resistance_band': const Color(0xFFE74C3C),
      'dumbbells': const Color(0xFF2C3E50),
      'yoga_mat': const Color(0xFF9B59B6),
      'kettlebell': const Color(0xFFE67E22),
      'bench': const Color(0xFF3498DB),
      'pull_up_bar': const Color(0xFF16A085),
    };

    final color = colorMap[equipment.code] ?? const Color(0xFF8E44AD);
    final icon = equipmentIcons[equipment.code] ?? '💪';

    return GestureDetector(
      onTap: () => _onEquipmentToggled(equipment.code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD700) : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    image: equipment.fullIconUrl != null && equipment.fullIconUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(equipment.fullIconUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: equipment.fullIconUrl == null || equipment.fullIconUrl!.isEmpty ? color.withOpacity(0.2) : null,
                  ),
                ),
              ),

              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon Badge (matching original design)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          icon,
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Title
                      Text(
                        equipment.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 6,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 2),

                      // Description (using category as fallback matching original design)
                      Text(
                        equipment.category.isNotEmpty ? equipment.category : 'Equipment',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 9,
                          height: 1.3,
                          shadows: const [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onEquipmentToggled(String equipmentCode) {
    setState(() {
      if (_selectedEquipment.contains(equipmentCode)) {
        _selectedEquipment.remove(equipmentCode);
      } else {
        _selectedEquipment.add(equipmentCode);
      }
    });

    // Save to Provider
    context.read<WorkoutGuideProvider>().toggleEquipmentByCode(equipmentCode);
    debugPrint('✅ Toggled equipment in Provider: $equipmentCode');
    debugPrint('✅ Current equipment list: $_selectedEquipment');
  }

  void _onContinuePressed() {
    if (_selectedEquipment.isNotEmpty) {
      // Data already saved to Provider by _onEquipmentToggled
      // Navigate to Step 3 (Intent Selection - 运动意图选择)
      Navigator.pushNamed(
        context,
        AppRoutes.intentSelection,
      );
    }
  }
}

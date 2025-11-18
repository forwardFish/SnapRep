import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/workout_guide_provider.dart';
import '../../../core/models/scenario.dart';
import '../../../core/models/equipment.dart';
import '../../../routes/app_routes.dart';

/// Training Environment Selection Page - Step 2
/// Matches HTML reference: 03-guide-step2.html
class WorkoutGuideStep2Page extends StatefulWidget {
  const WorkoutGuideStep2Page({super.key});

  @override
  State<WorkoutGuideStep2Page> createState() => _WorkoutGuideStep2PageState();
}

class _WorkoutGuideStep2PageState extends State<WorkoutGuideStep2Page> {
  String? _selectedScenario;
  List<String> _selectedEquipment = [];

  // Mock data matching HTML reference
  final List<Map<String, dynamic>> _scenarios = [
    {
      'id': 'home',
      'badge': 'HOME',
      'title': 'Living Space',
      'description': 'Comfortable environment\nPersonal space workout',
      'color': Color(0xFF3498DB),
      'imageUrl': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
    },
    {
      'id': 'office',
      'badge': 'OFFICE',
      'title': 'Workplace',
      'description': 'Professional setting\nQuick desk exercises',
      'color': Color(0xFF9B59B6),
      'imageUrl': 'https://images.unsplash.com/photo-1497366216548-37526070297c?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
    },
    {
      'id': 'gym',
      'badge': 'GYM',
      'title': 'Fitness Center',
      'description': 'Professional equipment\nFull workout space',
      'color': Color(0xFF27AE60),
      'imageUrl': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
    },
    {
      'id': 'travel',
      'badge': 'TRAVEL',
      'title': 'On the Go',
      'description': 'Hotel or limited space\nBodyweight exercises',
      'color': Color(0xFFE67E22),
      'imageUrl': 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
    },
  ];

  final List<Map<String, dynamic>> _equipment = [
    {
      'id': 'chair',
      'title': 'Chair',
      'description': 'Office or dining chair',
      'icon': '🪑',
      'color': const Color(0xFF8E44AD),
      'imageUrl': 'https://images.unsplash.com/photo-1506439773649-6e0eb8cfb237?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
    },
    {
      'id': 'wall',
      'title': 'Wall Space',
      'description': 'Clear wall area',
      'icon': '🧱',
      'color': const Color(0xFF34495E),
      'imageUrl': 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
    },
    {
      'id': 'hands_free',
      'title': 'Bodyweight',
      'description': 'No equipment needed',
      'icon': '💪',
      'color': const Color(0xFF27AE60),
      'imageUrl': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
    },
    {
      'id': 'resistance_band',
      'title': 'Resistance Band',
      'description': 'Elastic exercise band',
      'icon': '🎯',
      'color': const Color(0xFFE74C3C),
      'imageUrl': 'https://images.unsplash.com/photo-1598300042247-d088f8ab3a91?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
    },
    {
      'id': 'dumbbells',
      'title': 'Dumbbells',
      'description': 'Free weights',
      'icon': '🏋️',
      'color': const Color(0xFF2C3E50),
      'imageUrl': 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
    },
    {
      'id': 'yoga_mat',
      'title': 'Yoga Mat',
      'description': 'Exercise mat',
      'icon': '🧘',
      'color': const Color(0xFF9B59B6),
      'imageUrl': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutGuideProvider>().initializeStep2();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Workout Guide',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Content area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress indicator
                  _buildProgressIndicator(),

                  const SizedBox(height: 32),

                  // Title section
                  _buildTitleSection(),

                  const SizedBox(height: 32),

                  // Content sections
                  Expanded(
                    child: _buildContentSection(),
                  ),
                ],
              ),
            ),
          ),

          // Bottom button area
          _buildBottomButtonArea(),
        ],
      ),
    );
  }

  /// Build progress indicator
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
              color: const Color(0xFFE0E0E0), // Step 3 not completed yet
            ),
          ),
        ),
      ],
    );
  }

  /// Build title section
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
                  '2',
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
              'STEP 2',
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
          'Choose your\nworkout space',
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
          'Select your location and available equipment',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  /// Build content section
  Widget _buildContentSection() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scenarios',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _scenarios.length,
              itemBuilder: (context, index) {
                final scenario = _scenarios[index];
                return Container(
                  width: 140,
                  margin: EdgeInsets.only(
                    right: index < _scenarios.length - 1 ? 16 : 0,
                  ),
                  child: _buildScenarioCard(scenario),
                );
              },
            ),
          ),

          const SizedBox(height: 40),

          // Equipment Section
          const Text(
            'Equipment',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _equipment.length,
              itemBuilder: (context, index) {
                final equipment = _equipment[index];
                return Container(
                  width: 120,
                  margin: EdgeInsets.only(
                    right: index < _equipment.length - 1 ? 12 : 0,
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

  /// Build bottom button area
  Widget _buildBottomButtonArea() {
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
            onPressed: (_selectedScenario != null) ? _onContinuePressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: (_selectedScenario != null) ? const Color(0xFFFFD700) : Colors.grey.shade300,
              foregroundColor: (_selectedScenario != null) ? Colors.white : Colors.grey.shade500,
              elevation: (_selectedScenario != null) ? 8 : 0,
              shadowColor: (_selectedScenario != null) ? const Color(0xFFFFD700).withOpacity(0.3) : null,
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

  Widget _buildScenarioCard(Map<String, dynamic> scenario) {
    final isSelected = _selectedScenario == scenario['id'];

    return GestureDetector(
      onTap: () => _onScenarioSelected(scenario['id']),
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
                    image: DecorationImage(
                      image: NetworkImage(scenario['imageUrl']),
                      fit: BoxFit.cover,
                    ),
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
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: scenario['color'].withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          scenario['badge'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Title
                      Text(
                        scenario['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 6,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 2),

                      // Description
                      Text(
                        scenario['description'],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 10,
                          height: 1.3,
                          shadows: const [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
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

  Widget _buildEquipmentCard(Map<String, dynamic> equipment) {
    final isSelected = _selectedEquipment.contains(equipment['id']);

    return GestureDetector(
      onTap: () => _onEquipmentToggled(equipment['id']),
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
                    image: DecorationImage(
                      image: NetworkImage(equipment['imageUrl']),
                      fit: BoxFit.cover,
                    ),
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
                      // Icon Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: equipment['color'].withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          equipment['icon'],
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Title
                      Text(
                        equipment['title'],
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
                      ),

                      const SizedBox(height: 2),

                      // Description
                      Text(
                        equipment['description'],
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

  void _onScenarioSelected(String scenarioId) {
    setState(() {
      _selectedScenario = scenarioId;
    });

    // Note: This would need the actual scenario object in a real implementation
    debugPrint('Selected scenario: $scenarioId');
  }

  void _onEquipmentToggled(String equipmentId) {
    setState(() {
      if (_selectedEquipment.contains(equipmentId)) {
        _selectedEquipment.remove(equipmentId);
      } else {
        _selectedEquipment.add(equipmentId);
      }
    });

    // Update provider
    debugPrint('Selected equipment: $_selectedEquipment');
  }

  void _onContinuePressed() {
    if (_selectedScenario != null) {
      debugPrint('Continue to Step 3');
      debugPrint('Selected scenario: $_selectedScenario');
      debugPrint('Selected equipment: $_selectedEquipment');

      // Navigate to step 3
      AppRoutes.navigateToWorkoutGuideStep3(
        context,
        guideData: {
          'selectedScenario': _selectedScenario,
          'selectedEquipment': _selectedEquipment,
        },
      );
    }
  }
}
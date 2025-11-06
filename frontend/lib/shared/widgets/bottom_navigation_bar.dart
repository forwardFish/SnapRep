import 'package:flutter/material.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavigationBarWidget({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: const Border(
          top: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: _buildHomeIcon(),
                label: 'Home',
                isActive: currentIndex == 0,
              ),
              _buildNavItem(
                index: 1,
                icon: _buildCameraIcon(),
                label: 'Camera',
                isActive: currentIndex == 1,
              ),
              _buildNavItem(
                index: 2,
                icon: _buildProfileIcon(),
                label: 'Profile',
                isActive: currentIndex == 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required Widget icon,
    required String label,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFFFFD700).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: icon,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive
                    ? const Color(0xFFFFD700)
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeIcon() {
    final isActive = currentIndex == 0;
    return CustomPaint(
      size: const Size(24, 24),
      painter: HomeIconPainter(
        color: isActive ? const Color(0xFFFFD700) : const Color(0xFF9CA3AF),
      ),
    );
  }

  Widget _buildCameraIcon() {
    final isActive = currentIndex == 1;
    return CustomPaint(
      size: const Size(24, 24),
      painter: CameraIconPainter(
        color: isActive ? const Color(0xFFFFD700) : const Color(0xFF9CA3AF),
      ),
    );
  }

  Widget _buildProfileIcon() {
    final isActive = currentIndex == 2;
    return CustomPaint(
      size: const Size(24, 24),
      painter: ProfileIconPainter(
        color: isActive ? const Color(0xFFFFD700) : const Color(0xFF9CA3AF),
      ),
    );
  }
}

class HomeIconPainter extends CustomPainter {
  final Color color;

  HomeIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // House outline
    path.moveTo(size.width * 0.125, size.width * 0.375); // Start at left
    path.lineTo(size.width * 0.5, size.width * 0.083); // Top point
    path.lineTo(size.width * 0.875, size.width * 0.375); // Right
    path.lineTo(size.width * 0.875, size.width * 0.875); // Bottom right
    path.lineTo(size.width * 0.125, size.width * 0.875); // Bottom left
    path.close();

    // Door
    path.moveTo(size.width * 0.375, size.width * 0.5);
    path.lineTo(size.width * 0.375, size.width * 0.875);
    path.moveTo(size.width * 0.625, size.width * 0.5);
    path.lineTo(size.width * 0.625, size.width * 0.875);
    path.moveTo(size.width * 0.375, size.width * 0.5);
    path.lineTo(size.width * 0.625, size.width * 0.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CameraIconPainter extends CustomPainter {
  final Color color;

  CameraIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Camera body
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.083,
        size.width * 0.25,
        size.width * 0.833,
        size.width * 0.583,
      ),
      const Radius.circular(4),
    ));

    // Lens
    path.addOval(Rect.fromCenter(
      center: Offset(size.width * 0.5, size.width * 0.542),
      width: size.width * 0.333,
      height: size.width * 0.333,
    ));

    // Flash
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.333,
        size.width * 0.083,
        size.width * 0.333,
        size.width * 0.167,
      ),
      const Radius.circular(2),
    ));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ProfileIconPainter extends CustomPainter {
  final Color color;

  ProfileIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // Head (circle)
    canvas.drawCircle(
      Offset(size.width * 0.5, size.width * 0.292),
      size.width * 0.167,
      paint,
    );

    // Body (arc)
    final bodyPath = Path();
    bodyPath.addArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.width * 1.042),
        width: size.width * 0.667,
        height: size.width * 0.667,
      ),
      -3.14159, // Start angle (radians)
      3.14159,  // Sweep angle (radians)
    );

    canvas.drawPath(bodyPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
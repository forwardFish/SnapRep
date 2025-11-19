import 'package:flutter/material.dart';

/// 步骤进度指示器
/// 显示当前在多步流程中的位置
class StepProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Color activeColor;
  final Color inactiveColor;
  final double height;

  const StepProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.activeColor = const Color(0xFF6C5CE7),
    this.inactiveColor = const Color(0xFFE5E5E5),
    this.height = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index < currentStep;
        final isCurrent = index == currentStep - 1;

        return Expanded(
          child: Container(
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isActive
                  ? activeColor
                  : isCurrent
                      ? activeColor.withOpacity(0.5)
                      : inactiveColor,
              borderRadius: BorderRadius.circular(height / 2),
            ),
          ),
        );
      }),
    );
  }
}

/// 步骤指示器（带数字和标题）
class NumberedStepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> stepTitles;
  final Color activeColor;
  final Color completedColor;
  final Color inactiveColor;

  const NumberedStepIndicator({
    super.key,
    required this.currentStep,
    required this.stepTitles,
    this.activeColor = const Color(0xFF6C5CE7),
    this.completedColor = const Color(0xFF4CAF50),
    this.inactiveColor = const Color(0xFFE5E5E5),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(stepTitles.length, (index) {
        final isCompleted = index < currentStep - 1;
        final isActive = index == currentStep - 1;
        final isInactive = index > currentStep - 1;

        Color circleColor;
        Color textColor;
        IconData? icon;

        if (isCompleted) {
          circleColor = completedColor;
          textColor = completedColor;
          icon = Icons.check;
        } else if (isActive) {
          circleColor = activeColor;
          textColor = activeColor;
        } else {
          circleColor = inactiveColor;
          textColor = Colors.grey;
        }

        return Expanded(
          child: Column(
            children: [
              // 圆圈和连接线
              Row(
                children: [
                  // 连接线（左侧）
                  if (index > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isCompleted ? completedColor : inactiveColor,
                      ),
                    ),

                  // 步骤圆圈
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: circleColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: circleColor,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: icon != null
                          ? Icon(
                              icon,
                              size: 16,
                              color: Colors.white,
                            )
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isActive || isCompleted
                                    ? Colors.white
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),

                  // 连接线（右侧）
                  if (index < stepTitles.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isCompleted ? completedColor : inactiveColor,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // 步骤标题
              Text(
                stepTitles[index],
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }),
    );
  }
}
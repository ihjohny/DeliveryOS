import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/trip_models.dart';

class TripTimelineHeader extends StatelessWidget {
  final TripStep currentStep;

  const TripTimelineHeader({
    super.key,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildStepPill(
            stepNumber: 1,
            title: 'Pick Up',
            isActive: currentStep == TripStep.pickup,
            isCompleted: currentStep.stepNumber > 1,
          ),
          _buildStepDivider(isCompleted: currentStep.stepNumber > 1),
          _buildStepPill(
            stepNumber: 2,
            title: 'Deliver',
            isActive: currentStep == TripStep.delivering,
            isCompleted: currentStep.stepNumber > 2,
          ),
          _buildStepDivider(isCompleted: currentStep.stepNumber > 2),
          _buildStepPill(
            stepNumber: 3,
            title: 'Handover',
            isActive: currentStep == TripStep.handover,
            isCompleted: currentStep == TripStep.completed,
          ),
        ],
      ),
    );
  }

  Widget _buildStepPill({
    required int stepNumber,
    required String title,
    required bool isActive,
    required bool isCompleted,
  }) {
    final bgColor = isCompleted
        ? AppColors.dutyOnline
        : isActive
            ? AppColors.primary
            : AppColors.background;
    final textColor = (isActive || isCompleted) ? Colors.white : AppColors.textSecondary;

    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: bgColor,
          child: isCompleted
              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
              : Text(
                  '$stepNumber',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textColor),
                ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
            color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider({required bool isCompleted}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: isCompleted ? AppColors.dutyOnline : AppColors.border,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../domain/tracking_models.dart';

class OrderStepperWidget extends StatelessWidget {
  final OrderStage currentStage;

  const OrderStepperWidget({
    super.key,
    required this.currentStage,
  });

  static const List<Map<String, dynamic>> _steps = [
    {'title': 'Placed', 'icon': Icons.receipt_long_rounded},
    {'title': 'Assigned', 'icon': Icons.person_pin_rounded},
    {'title': 'Preparing', 'icon': Icons.outdoor_grill_rounded},
    {'title': 'Ready', 'icon': Icons.inventory_2_rounded},
    {'title': 'Delivering', 'icon': Icons.delivery_dining_rounded},
    {'title': 'Delivered', 'icon': Icons.check_circle_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final isCancelled = currentStage == OrderStage.cancelled;
    final activeIndex = currentStage.stepperIndex;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: isCancelled ? AppColors.errorBorder : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  currentStage.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w900,
                    color: isCancelled ? AppColors.errorDark : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: isCancelled ? AppColors.errorLight : AppColors.primaryContainer,
                  borderRadius: AppRadius.borderSm,
                ),
                child: Text(
                  isCancelled ? 'Cancelled' : 'Stage ${activeIndex + 1} of 6',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isCancelled ? AppColors.errorDark : AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            currentStage.description,
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),

          if (isCancelled)
            Container(
              padding: AppSpacing.edgeInsetsMd,
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: AppRadius.borderSm,
                border: Border.all(color: AppColors.errorBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cancel_outlined, color: AppColors.errorDark, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'This order has been cancelled and will not be prepared or delivered.',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.errorText,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.15,
              child: Row(
                children: List.generate(_steps.length * 2 - 1, (index) {
                  if (index.isOdd) {
                    final stepBefore = index ~/ 2;
                    final isPassed = activeIndex > stepBefore;
                    return Expanded(
                      child: Container(
                        height: 3,
                        color: isPassed ? AppColors.primary : AppColors.border,
                      ),
                    );
                  }

                  final stepIndex = index ~/ 2;
                  final isCompleted = activeIndex > stepIndex;
                  final isCurrent = activeIndex == stepIndex;

                  return SizedBox(
                    width: 38,
                    child: Column(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: isCompleted || isCurrent ? AppColors.primary : AppColors.background,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCompleted || isCurrent ? AppColors.primary : AppColors.border,
                              width: isCurrent ? 2 : 1,
                            ),
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.35),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            isCompleted ? Icons.check_rounded : (_steps[stepIndex]['icon'] as IconData),
                            size: 13,
                            color: isCompleted || isCurrent ? AppColors.white : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _steps[stepIndex]['title'] as String,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            fontSize: 9,
                            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                            color: isCurrent ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

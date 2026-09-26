import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCancelled ? const Color(0xFFFECACA) : AppColors.border),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isCancelled ? const Color(0xFFDC2626) : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCancelled ? const Color(0xFFFEE2E2) : AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isCancelled ? 'Cancelled' : 'Stage ${activeIndex + 1} of 6',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isCancelled ? const Color(0xFFDC2626) : AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            currentStage.description,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          if (isCancelled)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This order has been cancelled and will not be prepared or delivered.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF991B1B),
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
                            color: isCompleted || isCurrent ? Colors.white : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _steps[stepIndex]['title'] as String,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
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

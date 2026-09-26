import 'package:flutter/material.dart';
import '../../../../core/constants/design_tokens.dart';
import '../../domain/duty_models.dart';

class DutySwitchCard extends StatelessWidget {
  final RiderDutyState dutyState;
  final bool isOnline;
  final VoidCallback onToggleDuty;

  const DutySwitchCard({
    super.key,
    required this.dutyState,
    required this.isOnline,
    required this.onToggleDuty,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isOnline ? AppColors.dutyOnline : AppColors.dutyOffline;
    final statusTitle = isOnline ? 'YOU ARE ONLINE' : 'YOU ARE OFFLINE';
    final statusSubtitle = isOnline
        ? 'Live GPS radar streaming • Ready for incoming trip orders'
        : 'Duty toggle is off • You will not receive delivery alerts';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isOnline ? AppColors.dutyOnline : AppColors.black).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isOnline ? AppColors.white : AppColors.white54,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        statusTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.h2.copyWith(
                          fontSize: 18,
                          color: AppColors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOnline ? 'DUTY ACTIVE' : 'DUTY OFF',
                  style: AppTypography.badgeText.copyWith(color: AppColors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            statusSubtitle,
            style: AppTypography.caption.copyWith(fontSize: 13, color: AppColors.white70),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: dutyState.isToggling ? null : onToggleDuty,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: isOnline ? AppColors.dutyOnline : AppColors.textPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: dutyState.isToggling
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Icon(
                      isOnline ? Icons.power_settings_new_rounded : Icons.flash_on_rounded,
                      size: 24,
                      color: isOnline ? AppColors.error : AppColors.dutyOnline,
                    ),
              label: Text(
                isOnline ? 'GO OFFLINE (END SHIFT)' : 'GO ONLINE (START SHIFT)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.buttonText.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                  color: isOnline ? AppColors.error : AppColors.dutyOnline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

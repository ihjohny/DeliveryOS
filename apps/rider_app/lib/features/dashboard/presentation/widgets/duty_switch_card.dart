import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isOnline ? AppColors.dutyOnline : Colors.black).withValues(alpha: 0.25),
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
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.white : Colors.white54,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    statusTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOnline ? 'DUTY ACTIVE' : 'DUTY OFF',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            statusSubtitle,
            style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: dutyState.isToggling ? null : onToggleDuty,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
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
                style: TextStyle(
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

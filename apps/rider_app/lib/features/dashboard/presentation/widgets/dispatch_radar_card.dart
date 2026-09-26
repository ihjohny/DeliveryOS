import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/design_tokens.dart';

class DispatchRadarCard extends StatelessWidget {
  final bool isOnline;
  final bool hasActiveTrip;
  final VoidCallback onSimulateBroadcast;

  const DispatchRadarCard({
    super.key,
    required this.isOnline,
    required this.hasActiveTrip,
    required this.onSimulateBroadcast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isOnline ? AppColors.dutyOnlineBackground : AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOnline ? AppColors.dutyOnline.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isOnline ? Icons.sensors_rounded : Icons.sensors_off_rounded,
            size: 36,
            color: isOnline ? AppColors.dutyOnline : AppColors.textMuted,
          ),
          const SizedBox(height: 10),
          Text(
            isOnline ? 'Searching for Incoming Trips...' : 'Radar Disconnected',
            style: AppTypography.h3.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isOnline ? AppColors.dutyOnline : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isOnline
                ? 'Your GPS beacon is active in the pilot cluster. Incoming orders will chime with instant audio alert.'
                : 'Switch duty toggle to Online to begin receiving delivery dispatches in your zone.',
            textAlign: TextAlign.center,
            style: AppTypography.caption,
          ),
          if (kDebugMode && isOnline && !hasActiveTrip) ...[
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: onSimulateBroadcast,
              icon: const Icon(Icons.bolt_rounded, size: 18, color: AppColors.dutyOnline),
              label: Text(
                'Simulate Order Broadcast (Pilot Demo)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyBold.copyWith(fontSize: 13, color: AppColors.dutyOnline),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.dutyOnline),
                shape: const RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

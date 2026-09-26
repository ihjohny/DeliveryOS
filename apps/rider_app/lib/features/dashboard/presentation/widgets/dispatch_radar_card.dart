import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

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
      padding: const EdgeInsets.all(20),
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
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isOnline ? AppColors.dutyOnline : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isOnline
                ? 'Your GPS beacon is active in the pilot cluster. Incoming orders will chime with instant audio alert.'
                : 'Switch duty toggle to Online to begin receiving delivery dispatches in your zone.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
          ),
          if (kDebugMode && isOnline && !hasActiveTrip) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onSimulateBroadcast,
              icon: const Icon(Icons.bolt_rounded, size: 18, color: AppColors.dutyOnline),
              label: const Text(
                'Simulate Order Broadcast (Pilot Demo)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.dutyOnline),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.dutyOnline),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

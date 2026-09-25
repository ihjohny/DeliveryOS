import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/duty_models.dart';

class GpsTelemetryCard extends StatelessWidget {
  final RiderDutyState dutyState;

  const GpsTelemetryCard({
    super.key,
    required this.dutyState,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: dutyState.isOnline ? AppColors.dutyOnlineBackground : AppColors.dutyOfflineBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              dutyState.isOnline ? Icons.radar_rounded : Icons.location_off_rounded,
              color: dutyState.isOnline ? AppColors.dutyOnline : AppColors.textSecondary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'GPS LOCATION RADAR',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                    ),
                    if (dutyState.isOnline)
                      const Text(
                        'Beaconing (5s)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.dutyOnline),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  dutyState.isOnline
                      ? '${dutyState.latitude.toStringAsFixed(4)}° N, ${dutyState.longitude.toStringAsFixed(4)}° E'
                      : 'Location streaming paused while offline',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

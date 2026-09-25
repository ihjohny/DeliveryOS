import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../trips/domain/trip_models.dart';

class ActiveTripBanner extends StatelessWidget {
  final TripOrder trip;
  final VoidCallback onResumeTrip;

  const ActiveTripBanner({
    super.key,
    required this.trip,
    required this.onResumeTrip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
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
                  const Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'ACTIVE TRIP: ${trip.orderNumber}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trip.currentStep.stepTitle,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${trip.store.name} ➔ ${trip.customer.address}',
            style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onResumeTrip,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text('RESUME FULFILLMENT', style: TextStyle(fontWeight: FontWeight.w900)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

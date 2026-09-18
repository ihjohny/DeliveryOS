import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../dashboard/providers/duty_provider.dart';
import '../../domain/trip_models.dart';
import '../../providers/trip_provider.dart';
import '../active_trip_screen.dart';

class IncomingTripModal extends ConsumerWidget {
  final TripOrder trip;

  const IncomingTripModal({
    super.key,
    required this.trip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripState = ref.watch(riderTripProvider);
    final dutyState = ref.watch(riderDutyProvider);
    final remainingSecs = tripState.countdownSeconds;
    final progress = (remainingSecs / 45.0).clamp(0.0, 1.0);
    final isBlockedByCashLimit = trip.isCod && dutyState.isCashLimitReached;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Broadcast Alert Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.dutyOnlineBackground,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.dutyOnline),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: AppColors.dutyOnline,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NEW TRIP BROADCAST',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: AppColors.dutyOnline,
                        ),
                      ),
                      Text(
                        'Expires in ${remainingSecs}s',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Payout Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'EARN',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white70),
                      ),
                      Text(
                        '৳${trip.payout.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Countdown Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.background,
                valueColor: AlwaysStoppedAnimation<Color>(
                  remainingSecs <= 10 ? AppColors.error : AppColors.dutyOnline,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Route & Pickup/Drop-off Summary
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  // Pickup Store
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trip.store.name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            ),
                            Text(
                              '${trip.distanceKm} km away • ${trip.store.address}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        height: 16,
                        child: VerticalDivider(color: AppColors.borderStrong, thickness: 2),
                      ),
                    ),
                  ),

                  // Drop-off Customer Doorstep
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.place_rounded, color: AppColors.dutyOnline, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trip.customer.name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            ),
                            Text(
                              trip.customer.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Order Package & Payment Type Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: trip.isCod ? AppColors.warningBackground : AppColors.dutyOnlineBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: trip.isCod ? AppColors.warning.withValues(alpha: 0.4) : AppColors.dutyOnline.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        trip.isCod ? Icons.payments_rounded : Icons.credit_card_rounded,
                        size: 16,
                        color: trip.isCod ? AppColors.warning : AppColors.dutyOnline,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        trip.isCod ? 'Cash on Delivery: ৳${trip.totalAmount.toStringAsFixed(0)}' : 'Paid Online (Prepaid)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: trip.isCod ? AppColors.warning : AppColors.dutyOnline,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${trip.itemsCount} items',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Safety limit blocking alert
            if (isBlockedByCashLimit) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'COD Safety Limit Reached (৳${dutyState.codCashInHand.toStringAsFixed(0)} / ৳${dutyState.cashSafetyLimit.toStringAsFixed(0)}). Deposit cash at the hub before taking new COD orders.',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (tripState.error != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.errorBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error),
                ),
                child: Text(
                  tripState.error!,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.error),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Big Accept Button (height >= 56px)
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: (tripState.isClaiming || isBlockedByCashLimit)
                    ? null
                    : () async {
                        final success = await ref.read(riderTripProvider.notifier).claimTrip(trip);
                        if (context.mounted && success) {
                          Navigator.of(context).pop(); // Close modal
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ActiveTripScreen()),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isBlockedByCashLimit ? AppColors.borderStrong : AppColors.dutyOnline,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.borderStrong.withValues(alpha: 0.5),
                  disabledForegroundColor: Colors.white70,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: tripState.isClaiming
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isBlockedByCashLimit ? Icons.lock_rounded : Icons.check_circle_rounded, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            isBlockedByCashLimit ? 'COD LIMIT REACHED' : 'ACCEPT ORDER',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 10),

            // Decline Action
            Center(
              child: TextButton(
                onPressed: () {
                  ref.read(riderTripProvider.notifier).dismissIncomingAlert();
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Decline / Pass',
                  style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

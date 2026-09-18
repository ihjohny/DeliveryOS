import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/domain/auth_models.dart';
import '../../auth/presentation/pending_approval_screen.dart';
import '../../auth/presentation/phone_login_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/duty_models.dart';
import '../providers/duty_provider.dart';

class RiderDashboardScreen extends ConsumerWidget {
  const RiderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(riderAuthProvider);
    final dutyState = ref.watch(riderDutyProvider);
    final profile = authState.profile;

    // Safety Invariant: unapproved accounts cannot access active dashboard
    if (authState.isPendingApproval || profile?.status == AccountStatus.pendingApproval) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isOnline = dutyState.isOnline;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(riderAuthProvider.notifier).fetchProfile();
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            children: [
              // Top Bar: Rider Profile & Logout
              _buildTopBar(context, ref, profile),
              const SizedBox(height: 16),

              // Prominent Sunlight-Readable Duty Switch Card
              _buildDutySwitchCard(context, ref, dutyState, isOnline),
              const SizedBox(height: 16),

              // Live GPS Radar Telemetry Card
              _buildGpsTelemetryCard(dutyState),
              const SizedBox(height: 16),

              // Daily Performance & Cash Safety Overview
              _buildPerformanceMetrics(dutyState),
              const SizedBox(height: 16),

              // Dispatch Radar Status
              _buildDispatchRadarStatus(isOnline),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref, RiderProfileData? profile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryLight.withValues(alpha: 0.15),
            child: const Icon(Icons.person_pin_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      profile?.fullName ?? 'Rider Partner',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.dutyOnlineBackground,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 2),
                          Text(
                            profile?.rating.toString() ?? '5.0',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.dutyOnline),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      _getVehicleIcon(profile?.vehicleType),
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      profile?.vehicleType.displayName ?? 'Motorcycle',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                    Text(
                      profile?.phone ?? '',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary, size: 20),
            tooltip: 'Log Out',
            onPressed: () async {
              await ref.read(riderAuthProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDutySwitchCard(
    BuildContext context,
    WidgetRef ref,
    RiderDutyState state,
    bool isOnline,
  ) {
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

          // High-Contrast Large Touch-Target Switch Button (height >= 56px)
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: state.isToggling
                  ? null
                  : () async {
                      final success = await ref.read(riderDutyProvider.notifier).toggleDuty();
                      if (!success && context.mounted) {
                        final error = ref.read(riderDutyProvider).error;
                        if (error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error), backgroundColor: AppColors.error),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: isOnline ? AppColors.dutyOnline : AppColors.textPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: state.isToggling
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

  Widget _buildGpsTelemetryCard(RiderDutyState state) {
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
              color: state.isOnline ? AppColors.dutyOnlineBackground : AppColors.dutyOfflineBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              state.isOnline ? Icons.radar_rounded : Icons.location_off_rounded,
              color: state.isOnline ? AppColors.dutyOnline : AppColors.textSecondary,
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
                    if (state.isOnline)
                      const Text(
                        'Beaconing (5s)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.dutyOnline),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  state.isOnline
                      ? '${state.latitude.toStringAsFixed(4)}° N, ${state.longitude.toStringAsFixed(4)}° E'
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

  Widget _buildPerformanceMetrics(RiderDutyState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TODAY\'S PERFORMANCE',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.5),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Completed Trips',
                value: '${state.todayTrips}',
                icon: Icons.task_alt_rounded,
                iconColor: AppColors.dutyOnline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'Earned Payout',
                value: '৳${state.todayEarnings.toStringAsFixed(0)}',
                icon: Icons.account_balance_wallet_rounded,
                iconColor: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Cash-in-Hand vs Safety Limit Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.payments_rounded, color: AppColors.warning, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'COD Cash in Hand',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  Text(
                    '৳${state.codCashInHand.toStringAsFixed(0)} / ৳${state.cashSafetyLimit.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (state.codCashInHand / state.cashSafetyLimit).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppColors.background,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    state.isCashLimitReached ? AppColors.error : AppColors.warning,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                state.isCashLimitReached
                    ? '⚠️ Cash safety limit reached! Deposit cash to accept more COD orders.'
                    : 'Safe limit remaining: ৳${(state.cashSafetyLimit - state.codCashInHand).toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: state.isCashLimitReached ? AppColors.error : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchRadarStatus(bool isOnline) {
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
        ],
      ),
    );
  }

  IconData _getVehicleIcon(VehicleType? vehicle) {
    switch (vehicle) {
      case VehicleType.bicycle:
        return Icons.pedal_bike_rounded;
      case VehicleType.car:
        return Icons.directions_car_rounded;
      case VehicleType.motorcycle:
      default:
        return Icons.two_wheeler_rounded;
    }
  }
}

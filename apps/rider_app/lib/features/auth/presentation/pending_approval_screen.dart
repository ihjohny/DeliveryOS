import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../dashboard/presentation/rider_dashboard_screen.dart';
import '../domain/auth_models.dart';
import '../providers/auth_provider.dart';
import 'phone_login_screen.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(riderAuthProvider);
    final profile = authState.profile;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Pending Status Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warningBackground,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(
                        Icons.hourglass_top_rounded,
                        color: AppColors.warning,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Account Pending Approval',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warningBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warning),
                      ),
                      child: const Text(
                        'STATUS: PENDING_APPROVAL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.warning,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome ${profile?.fullName ?? "Rider"}! Your application to join DeliveryOS is currently under review by our operations team.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Rider Details Recap
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('Rider Name', profile?.fullName ?? 'New Applicant'),
                          const Divider(height: 16, color: AppColors.border),
                          _buildDetailRow('Mobile Phone', profile?.phone ?? authState.phoneNumber ?? '-'),
                          const Divider(height: 16, color: AppColors.border),
                          _buildDetailRow('Vehicle Type', profile?.vehicleType.displayName ?? 'Motorcycle'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Invariant Guard Notice
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield_outlined, color: AppColors.error, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Duty Switch is locked until account approval per fleet safety compliance.',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Check Status Button
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: authState.isLoading
                      ? null
                      : () async {
                          await ref.read(riderAuthProvider.notifier).refreshApprovalStatus();
                          final updated = ref.read(riderAuthProvider);
                          if (context.mounted && updated.isAuthenticated) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const RiderDashboardScreen()),
                              (route) => false,
                            );
                          }
                        },
                  icon: authState.isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('Check Approval Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Dev Mode Instant Approval Button
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(riderAuthProvider.notifier).forceApproveForDev();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const RiderDashboardScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.bolt_rounded, size: 18, color: AppColors.dutyOnline),
                label: const Text(
                  'Simulate Admin Approval (Dev Mode)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.dutyOnline),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.dutyOnline),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),

              // Logout Button
              TextButton.icon(
                onPressed: () async {
                  await ref.read(riderAuthProvider.notifier).logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.textSecondary),
                label: const Text('Log Out', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

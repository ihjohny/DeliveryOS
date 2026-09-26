import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/design_tokens.dart';
import '../domain/auth_models.dart';
import '../providers/auth_provider.dart';
import 'otp_verification_screen.dart';
import 'widgets/vehicle_type_selector.dart';

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isRegistering = false;
  VehicleType _selectedVehicle = VehicleType.motorcycle;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleProceed() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid mobile number'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final String formattedPhone;
    if (rawPhone.startsWith('+') && !rawPhone.startsWith('+880')) {
      formattedPhone = rawPhone;
    } else {
      String cleanDigits = rawPhone.replaceAll(RegExp(r'\D'), '');
      if (cleanDigits.startsWith('880')) {
        cleanDigits = cleanDigits.substring(3);
      }
      if (cleanDigits.startsWith('0')) {
        cleanDigits = cleanDigits.substring(1);
      }
      if (cleanDigits.length < 9) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid mobile number (min 9 digits)'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      formattedPhone = '+880$cleanDigits';
    }

    if (_isRegistering && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your full name for rider registration'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await ref.read(riderAuthProvider.notifier).requestOtp(
          phone: formattedPhone,
          fullName: _isRegistering ? _nameController.text.trim() : null,
          vehicleType: _selectedVehicle,
        );

    if (success && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            phoneNumber: formattedPhone,
            isRegistering: _isRegistering,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(riderAuthProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(AppSpacing.xl),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: const BoxDecoration(
                          color: AppColors.dutyOnline,
                          borderRadius: AppRadius.roundedLg,
                        ),
                        child: const Icon(
                          Icons.delivery_dining_rounded,
                          size: 40,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'DeliveryOS Rider Fleet',
                        style: AppTypography.h2.copyWith(
                          color: AppColors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Partner Delivery Portal',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isRegistering = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            decoration: BoxDecoration(
                              color: !_isRegistering ? AppColors.primary : AppColors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Rider Login',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyBold.copyWith(
                                fontWeight: FontWeight.w800,
                                color: !_isRegistering ? AppColors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isRegistering = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            decoration: BoxDecoration(
                              color: _isRegistering ? AppColors.primary : AppColors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Apply / Register',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyBold.copyWith(
                                fontWeight: FontWeight.w800,
                                color: _isRegistering ? AppColors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isRegistering) ...[
                        Text(
                          'FULL NAME',
                          style: AppTypography.badgeText.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nameController,
                          style: AppTypography.h3,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Tanvir Hossain',
                            prefixIcon: Icon(Icons.person_rounded, color: AppColors.primary),
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.roundedMd,
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'VEHICLE TYPE',
                          style: AppTypography.badgeText.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        VehicleTypeSelector(
                          selectedVehicle: _selectedVehicle,
                          onVehicleSelected: (type) => setState(() => _selectedVehicle = type),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      Text(
                        'MOBILE NUMBER',
                        style: AppTypography.badgeText.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: AppTypography.h2.copyWith(
                          fontSize: 18,
                          letterSpacing: 1.0,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
                            child: Text(
                              '🇧🇩 +880',
                              style: AppTypography.bodyBold.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          hintText: '1700112233',
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
                          border: const OutlineInputBorder(
                            borderRadius: AppRadius.roundedMd,
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: authState.isLoading ? null : _handleProceed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: authState.isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2.5),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _isRegistering ? 'Submit Application' : 'Send Verification OTP',
                                        style: AppTypography.buttonText.copyWith(fontSize: 16),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    const Icon(Icons.arrow_forward_rounded, size: 20),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: AppSpacing.xl),

                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.dutyOnlineBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.dutyOnlineLight.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '⚡ PILOT TEST ACCOUNTS (DEBUG ONLY)',
                          style: AppTypography.badgeText.copyWith(color: AppColors.dutyOnline),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          children: [
                            ActionChip(
                              avatar: const Icon(Icons.check_circle_rounded, color: AppColors.dutyOnline, size: 16),
                              label: const Text('Approved Pilot (+8801700112233)'),
                              onPressed: () {
                                setState(() {
                                  _isRegistering = false;
                                  _phoneController.text = '1700112233';
                                });
                              },
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.pending_actions_rounded, color: AppColors.warning, size: 16),
                              label: const Text('New / Pending (+8801700998877)'),
                              onPressed: () {
                                setState(() {
                                  _isRegistering = true;
                                  _nameController.text = 'Shafiqul Islam';
                                  _phoneController.text = '1700998877';
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

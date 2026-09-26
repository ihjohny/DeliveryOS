import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.dutyOnline,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.delivery_dining_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'DeliveryOS Rider Fleet',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Partner Delivery Portal',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(4),
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
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isRegistering ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Rider Login',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: !_isRegistering ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isRegistering = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isRegistering ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Apply / Register',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: _isRegistering ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isRegistering) ...[
                        const Text(
                          'FULL NAME',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. Tanvir Hossain',
                            prefixIcon: const Icon(Icons.person_rounded, color: AppColors.primary),
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'VEHICLE TYPE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        VehicleTypeSelector(
                          selectedVehicle: _selectedVehicle,
                          onVehicleSelected: (type) => setState(() => _selectedVehicle = type),
                        ),
                        const SizedBox(height: 16),
                      ],

                      const Text(
                        'MOBILE NUMBER',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            child: const Text(
                              '🇧🇩 +880',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          hintText: '1700112233',
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: authState.isLoading ? null : _handleProceed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: authState.isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _isRegistering ? 'Submit Application' : 'Send Verification OTP',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward_rounded, size: 20),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.dutyOnlineBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.dutyOnlineLight.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '⚡ PILOT TEST ACCOUNTS (DEBUG ONLY)',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.dutyOnline),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/language_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/presentation/phone_input_screen.dart';
import '../../home/presentation/home_screen.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.xl,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 40.0),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          padding: AppSpacing.edgeInsetsXs,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: AppRadius.borderFull,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _LanguageChip(
                                code: 'en',
                                label: 'English',
                                isSelected: currentLocale.languageCode == 'en',
                                onTap: () => ref.read(languageProvider.notifier).setLanguage('en'),
                              ),
                              _LanguageChip(
                                code: 'ar',
                                label: 'العربية',
                                isSelected: currentLocale.languageCode == 'ar',
                                onTap: () => ref.read(languageProvider.notifier).setLanguage('ar'),
                              ),
                              _LanguageChip(
                                code: 'bn',
                                label: 'বাংলা',
                                isSelected: currentLocale.languageCode == 'bn',
                                onTap: () => ref.read(languageProvider.notifier).setLanguage('bn'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: AppSpacing.edgeInsetsVerticalXxl,
                        child: Column(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: AppRadius.borderXxl,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.delivery_dining_rounded,
                                size: 54,
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            Text(
                              l10n.translate('app_title'),
                              style: AppTypography.headlineLarge.copyWith(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              l10n.translate('tagline'),
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const PhoneInputScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                                elevation: 0,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: AppRadius.borderLg,
                                ),
                              ),
                              child: Text(
                                l10n.translate('continue_btn'),
                                style: AppTypography.labelLarge.copyWith(
                                  fontSize: 16,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: TextButton(
                              onPressed: () async {
                                await ref.read(authProvider.notifier).continueAsGuest();
                                if (context.mounted) {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                                  );
                                }
                              },
                              child: Text(
                                l10n.translate('skip_guest'),
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  final String code;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageChip({
    required this.code,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.transparent,
          borderRadius: AppRadius.borderFull,
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

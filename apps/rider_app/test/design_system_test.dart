import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_app/core/constants/design_tokens.dart';

void main() {
  group('Design System Tokens Tests', () {
    test('AppColors defines required semantic and utility palette', () {
      expect(AppColors.primary, const Color(0xFF1E3A8A));
      expect(AppColors.dutyOnline, const Color(0xFF059669));
      expect(AppColors.dutyOffline, const Color(0xFF374151));
      expect(AppColors.card, const Color(0xFFFFFFFF));
      expect(AppColors.border, const Color(0xFFE2E8F0));
      expect(AppColors.white, const Color(0xFFFFFFFF));
      expect(AppColors.black, const Color(0xFF000000));
      expect(AppColors.transparent, const Color(0x00000000));
      expect(AppColors.star, const Color(0xFFF59E0B));

      // Neutral greys
      expect(AppColors.grey50, isNotNull);
      expect(AppColors.grey100, isNotNull);
      expect(AppColors.grey200, isNotNull);
      expect(AppColors.grey300, isNotNull);
      expect(AppColors.grey400, isNotNull);
      expect(AppColors.grey500, isNotNull);
      expect(AppColors.grey600, isNotNull);
      expect(AppColors.grey700, isNotNull);
      expect(AppColors.grey800, isNotNull);
      expect(AppColors.grey900, isNotNull);
    });

    test('AppTypography defines 9 outdoor high-contrast hierarchy tokens', () {
      expect(AppTypography.h1.fontSize, 28);
      expect(AppTypography.h1.fontWeight, FontWeight.w900);

      expect(AppTypography.h2.fontSize, 20);
      expect(AppTypography.h2.fontWeight, FontWeight.w800);

      expect(AppTypography.h3.fontSize, 16);
      expect(AppTypography.h3.fontWeight, FontWeight.w700);

      expect(AppTypography.body.fontSize, 14);
      expect(AppTypography.body.fontWeight, FontWeight.w400);

      expect(AppTypography.bodyBold.fontSize, 14);
      expect(AppTypography.bodyBold.fontWeight, FontWeight.w700);

      expect(AppTypography.caption.fontSize, 12);
      expect(AppTypography.caption.fontWeight, FontWeight.w500);

      expect(AppTypography.statNumber.fontSize, 26);
      expect(AppTypography.statNumber.fontWeight, FontWeight.w900);

      expect(AppTypography.badgeText.fontSize, 11);
      expect(AppTypography.badgeText.fontWeight, FontWeight.w800);

      expect(AppTypography.buttonText.fontSize, 15);
      expect(AppTypography.buttonText.fontWeight, FontWeight.w800);
      expect(AppTypography.buttonText.color, AppColors.white);
    });

    test('AppSpacing and AppRadius define standard scales', () {
      expect(AppSpacing.xs, 4.0);
      expect(AppSpacing.sm, 8.0);
      expect(AppSpacing.md, 12.0);
      expect(AppSpacing.lg, 16.0);
      expect(AppSpacing.xl, 20.0);
      expect(AppSpacing.xxl, 24.0);
      expect(AppSpacing.xxxl, 32.0);

      expect(AppRadius.xs, 4.0);
      expect(AppRadius.sm, 8.0);
      expect(AppRadius.md, 12.0);
      expect(AppRadius.lg, 16.0);
      expect(AppRadius.full, 999.0);

      expect(AppRadius.roundedMd, const BorderRadius.all(Radius.circular(12.0)));
      expect(AppRadius.roundedLg, const BorderRadius.all(Radius.circular(16.0)));
    });
  });
}

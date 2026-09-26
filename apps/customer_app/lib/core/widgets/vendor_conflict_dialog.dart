import 'package:flutter/material.dart';
import '../constants/constants.dart';

class VendorConflictDialog extends StatelessWidget {
  final String newVendorName;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const VendorConflictDialog({
    super.key,
    required this.newVendorName,
    required this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
      title: Text(
        'Replace Cart Items?',
        style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
      ),
      content: Text(
        'Your cart already contains items from a different store. Clear cart and add from $newVendorName?',
        style: AppTypography.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
            onCancel?.call();
          },
          child: Text(
            'Cancel',
            style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
          ),
          child: Text(
            'Replace & Add',
            style: AppTypography.labelLarge.copyWith(color: AppColors.white),
          ),
        ),
      ],
    );
  }
}

Future<bool?> showVendorConflictDialog({
  required BuildContext context,
  required String newVendorName,
  required VoidCallback onConfirmReplace,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => VendorConflictDialog(
      newVendorName: newVendorName,
      onConfirm: onConfirmReplace,
    ),
  );
}

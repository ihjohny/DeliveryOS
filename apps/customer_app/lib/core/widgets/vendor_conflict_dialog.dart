import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Reusable dialog shown when adding an item from a different store
/// while the cart already has items from another store.
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Replace Cart Items?',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: Text(
        'Your cart already contains items from a different store. Clear cart and add from $newVendorName?',
        style: const TextStyle(fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
            onCancel?.call();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Replace & Add'),
        ),
      ],
    );
  }
}

/// Helper function to display the [VendorConflictDialog] cleanly.
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

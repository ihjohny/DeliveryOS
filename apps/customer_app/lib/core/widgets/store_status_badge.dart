import 'package:flutter/material.dart';

/// Reusable store operational status pill badge across DeliveryOS.
/// Displays OPEN, BUSY, or CLOSED with consistent brand theme tokens.
class StoreStatusBadge extends StatelessWidget {
  final bool isOpen;
  final bool isBusy;
  final bool compact;

  const StoreStatusBadge({
    super.key,
    required this.isOpen,
    this.isBusy = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color bgColor;
    final Color textColor;

    if (!isOpen) {
      label = compact ? 'CLOSED' : 'CLOSED';
      bgColor = const Color(0xFFFEE2E2);
      textColor = const Color(0xFFDC2626);
    } else if (isBusy) {
      label = 'BUSY';
      bgColor = const Color(0xFFFEF3C7);
      textColor = const Color(0xFFD97706);
    } else {
      label = compact ? 'OPEN' : 'OPEN NOW';
      bgColor = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF16A34A);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6.0 : 8.0,
        vertical: compact ? 2.0 : 4.0,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(compact ? 4 : 6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w800,
          color: textColor,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

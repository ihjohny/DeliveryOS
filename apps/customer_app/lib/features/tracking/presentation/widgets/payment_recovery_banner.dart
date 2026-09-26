import 'package:flutter/material.dart';

/// Modular payment recovery banner allowing customer to switch to Cash on Delivery (COD)
/// when an online gateway transaction is pending or failed.
class PaymentRecoveryBanner extends StatelessWidget {
  final VoidCallback onSwitchToCOD;
  final VoidCallback onRefresh;

  const PaymentRecoveryBanner({
    super.key,
    required this.onSwitchToCOD,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payment_rounded, color: Color(0xFFD97706), size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Online Payment Pending',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Kitchen preparation and courier dispatch will begin immediately once payment is confirmed.',
            style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: onSwitchToCOD,
                icon: const Icon(Icons.money_rounded, size: 16),
                label: const Text(
                  'Switch to Cash (COD)',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.sync_rounded, size: 16),
                label: const Text(
                  'Refresh',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF92400E),
                  side: const BorderSide(color: Color(0xFFF59E0B)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/tracking_models.dart';

class TrackingMapView extends StatelessWidget {
  final OrderTrackingState state;

  const TrackingMapView({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE6E8EA),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Road Grid & Route Painter
          CustomPaint(
            painter: _RouteMapPainter(
              stage: state.stage,
            ),
          ),

          // Store Marker
          Positioned(
            left: 50,
            top: 60,
            child: _buildPin(
              label: state.store.name.split('-').first.trim(),
              icon: Icons.storefront_rounded,
              color: AppColors.primary,
            ),
          ),

          // Customer Delivery Pin
          Positioned(
            right: 50,
            bottom: 70,
            child: _buildPin(
              label: 'Delivery Address',
              icon: Icons.home_rounded,
              color: AppColors.secondary,
            ),
          ),

          // Live Moving Rider Pin (interpolated)
          if (state.rider != null && state.stage == OrderStage.dispatched)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeInOut,
              left: 140,
              top: 130,
              child: _buildRiderPin(state.rider!),
            ),

          // Telemetry Overlay Badge
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.satellite_alt_rounded, size: 14, color: AppColors.secondary),
                  const SizedBox(width: 6),
                  Text(
                    'GPS Live Telemetry • ${state.rider?.speed.toStringAsFixed(0) ?? "0"} km/h',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPin({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Icon(icon, size: 30, color: color),
      ],
    );
  }

  Widget _buildRiderPin(RiderMeta rider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.textPrimary,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.two_wheeler_rounded, size: 12, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                rider.name.split(' ').first,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 10,
                spreadRadius: 3,
              ),
            ],
          ),
          child: const Icon(Icons.navigation_rounded, size: 18, color: Colors.white),
        ),
      ],
    );
  }
}

class _RouteMapPainter extends CustomPainter {
  final OrderStage stage;

  _RouteMapPainter({required this.stage});

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final routePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Grid Roads
    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.3), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.7), roadPaint);
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.3, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.7, 0), Offset(size.width * 0.7, size.height), roadPaint);

    // Active Route Polyline from Store (left: 70, top: 90) to Customer (width - 70, height - 90)
    final routePath = Path()
      ..moveTo(70, 90)
      ..lineTo(size.width * 0.3, 90)
      ..lineTo(size.width * 0.3, size.height * 0.5)
      ..lineTo(size.width * 0.7, size.height * 0.5)
      ..lineTo(size.width * 0.7, size.height - 90)
      ..lineTo(size.width - 70, size.height - 90);

    canvas.drawPath(routePath, routePaint);
  }

  @override
  bool shouldRepaint(covariant _RouteMapPainter oldDelegate) => oldDelegate.stage != stage;
}

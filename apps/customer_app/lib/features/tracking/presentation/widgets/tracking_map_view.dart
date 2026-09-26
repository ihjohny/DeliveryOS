import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/tracking_models.dart';

class TrackingMapView extends StatefulWidget {
  final OrderTrackingState state;

  const TrackingMapView({
    super.key,
    required this.state,
  });

  @override
  State<TrackingMapView> createState() => _TrackingMapViewState();
}

class _TrackingMapViewState extends State<TrackingMapView> {
  GoogleMapController? _mapController;

  @override
  void didUpdateWidget(covariant TrackingMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.rider != null && _mapController != null) {
      final rider = widget.state.rider!;
      if (widget.state.stage == OrderStage.dispatched) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(LatLng(rider.latitude, rider.longitude)),
        );
      }
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    final store = widget.state.store;
    final customer = widget.state.customer;
    final rider = widget.state.rider;

    // 1. Store Marker
    markers.add(
      Marker(
        markerId: const MarkerId('store_marker'),
        position: LatLng(store.latitude, store.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: store.name,
          snippet: store.address,
        ),
      ),
    );

    // 2. Customer Destination Marker
    markers.add(
      Marker(
        markerId: const MarkerId('customer_marker'),
        position: LatLng(customer.latitude, customer.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Delivery Address',
          snippet: customer.address,
        ),
      ),
    );

    // 3. Live Courier Marker (if assigned)
    if (rider != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('rider_marker'),
          position: LatLng(rider.latitude, rider.longitude),
          rotation: rider.bearing,
          flat: true,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: '${rider.name} (Courier)',
            snippet: '${rider.speed.toStringAsFixed(1)} km/h • ${rider.vehicleType}',
          ),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    final points = <LatLng>[
      LatLng(widget.state.store.latitude, widget.state.store.longitude),
    ];

    if (widget.state.rider != null && widget.state.stage == OrderStage.dispatched) {
      points.add(LatLng(widget.state.rider!.latitude, widget.state.rider!.longitude));
    }

    points.add(LatLng(widget.state.customer.latitude, widget.state.customer.longitude));

    return {
      Polyline(
        polylineId: const PolylineId('delivery_route'),
        points: points,
        color: AppColors.primary,
        width: 4,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  LatLngBounds _computeBounds() {
    final store = widget.state.store;
    final customer = widget.state.customer;
    final rider = widget.state.rider;

    final lats = [store.latitude, customer.latitude];
    final lngs = [store.longitude, customer.longitude];
    if (rider != null) {
      lats.add(rider.latitude);
      lngs.add(rider.longitude);
    }

    final south = lats.reduce(math.min);
    final north = lats.reduce(math.max);
    final west = lngs.reduce(math.min);
    final east = lngs.reduce(math.max);

    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.state.store;
    final initialCenter = LatLng(store.latitude, store.longitude);

    return Stack(
      fit: StackFit.expand,
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialCenter,
            zoom: 14.0,
          ),
          markers: _buildMarkers(),
          polylines: _buildPolylines(),
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: true,
          onMapCreated: (controller) {
            _mapController = controller;
            try {
              final bounds = _computeBounds();
              controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
            } catch (_) {}
          },
        ),

        Positioned(
          left: 16,
          top: 16,
          right: 64,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.state.stage == OrderStage.dispatched
                          ? const Color(0xFF10B981)
                          : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.state.stage == OrderStage.dispatched
                          ? 'Live GPS • ${widget.state.estimatedMinutesRemaining} mins away'
                          : widget.state.stage.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            elevation: 3,
            onPressed: () {
              if (_mapController != null) {
                try {
                  final bounds = _computeBounds();
                  _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
                } catch (_) {}
              }
            },
            child: const Icon(Icons.crop_free_rounded, size: 20),
          ),
        ),
      ],
    );
  }
}

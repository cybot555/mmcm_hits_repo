import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mmcm_hits/repositories/ride_repository.dart';
import 'package:mmcm_hits/viewmodels/driver_live_map_viewmodel.dart';
import 'package:provider/provider.dart';

class DriverLiveMap extends StatelessWidget {
  final String rideId;
  final GeoPoint destination;

  const DriverLiveMap({
    super.key,
    required this.rideId,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    final rideRepository = context.read<RideRepository>();

    return ChangeNotifierProvider(
      create: (_) => DriverLiveMapViewModel(
        rideRepository,
        rideId: rideId,
        destination: destination,
      )..initialise(),
      child: const _DriverLiveMapView(),
    );
  }
}

class _DriverLiveMapView extends StatefulWidget {
  const _DriverLiveMapView();

  @override
  State<_DriverLiveMapView> createState() => _DriverLiveMapViewState();
}

class _DriverLiveMapViewState extends State<_DriverLiveMapView> {
  final MapController _mapController = MapController();
  LatLng? _lastCenter;

  @override
  Widget build(BuildContext context) {
    return Consumer<DriverLiveMapViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.currentPosition != null &&
            viewModel.currentPosition != _lastCenter) {
          _lastCenter = viewModel.currentPosition;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final center = viewModel.currentPosition!;
            _mapController.move(center, _mapController.camera.zoom);
          });
        }

        if (viewModel.errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final messenger = ScaffoldMessenger.maybeOf(context);
            if (messenger == null) return;
            messenger.showSnackBar(
              SnackBar(content: Text(viewModel.errorMessage!)),
            );
            viewModel.resetError();
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Live Ride Tracking'),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          body: viewModel.currentPosition == null
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: viewModel.currentPosition!,
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'mmcm_hits_app',
                    ),
                    if (viewModel.routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: viewModel.routePoints,
                            strokeWidth: 4,
                            color: Colors.blueAccent,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: viewModel.currentPosition!,
                          width: 50,
                          height: 50,
                          child: const Icon(
                            Icons.local_taxi,
                            color: Colors.green,
                            size: 38,
                          ),
                        ),
                        Marker(
                          point: LatLng(
                            viewModel.destination.latitude,
                            viewModel.destination.longitude,
                          ),
                          width: 50,
                          height: 50,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 42,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

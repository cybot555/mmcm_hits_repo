import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mmcm_hits/repositories/ride_repository.dart';
import 'package:mmcm_hits/viewmodels/hitcher_live_map_viewmodel.dart';
import 'package:provider/provider.dart';

class HitcherLiveMap extends StatelessWidget {
  final String rideId;

  const HitcherLiveMap({super.key, required this.rideId});

  @override
  Widget build(BuildContext context) {
    final rideRepository = context.read<RideRepository>();

    return ChangeNotifierProvider(
      create: (_) =>
          HitcherLiveMapViewModel(rideRepository, rideId: rideId)..initialise(),
      child: const _HitcherLiveMapView(),
    );
  }
}

class _HitcherLiveMapView extends StatefulWidget {
  const _HitcherLiveMapView();

  @override
  State<_HitcherLiveMapView> createState() => _HitcherLiveMapViewState();
}

class _HitcherLiveMapViewState extends State<_HitcherLiveMapView> {
  final MapController _mapController = MapController();
  LatLng? _lastDriverPosition;

  @override
  Widget build(BuildContext context) {
    return Consumer<HitcherLiveMapViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.driverPosition != null &&
            viewModel.driverPosition != _lastDriverPosition) {
          _lastDriverPosition = viewModel.driverPosition;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final pos = viewModel.driverPosition!;
            _mapController.move(pos, _mapController.camera.zoom);
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

        if (viewModel.rideCompleted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              navigator.pop();
              final messenger = ScaffoldMessenger.maybeOf(context);
              messenger?.showSnackBar(
                const SnackBar(
                  content: Text('✅ Ride completed by driver.'),
                ),
              );
            }
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Live Driver Tracker'),
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
          ),
          body: viewModel.driverPosition == null
              ? const Center(child: Text('Waiting for driver to start ride...'))
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: viewModel.driverPosition!,
                    initialZoom: 15,
                    onMapReady: () {
                      if (viewModel.driverPosition != null) {
                        _mapController.move(viewModel.driverPosition!, 15);
                      }
                    },
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                          point: viewModel.driverPosition!,
                          width: 50,
                          height: 50,
                          child: const Icon(
                            Icons.local_taxi,
                            color: Colors.green,
                            size: 38,
                          ),
                        ),
                        if (viewModel.destination != null)
                          Marker(
                            point: viewModel.destination!,
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
}

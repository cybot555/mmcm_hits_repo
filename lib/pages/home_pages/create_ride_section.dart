import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:mmcm_hits/repositories/auth_repository.dart';
import 'package:mmcm_hits/repositories/ride_repository.dart';
import 'package:mmcm_hits/repositories/user_repository.dart';
import 'package:mmcm_hits/viewmodels/create_ride_viewmodel.dart';
import 'package:provider/provider.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  LatLng? _lastCurrent;
  LatLng? _lastDestination;

  @override
  void dispose() {
    _destinationController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rideRepository = context.read<RideRepository>();
    final authRepository = context.read<AuthRepository>();
    final userRepository = context.read<UserRepository>();

    return ChangeNotifierProvider(
      create: (_) => CreateRideViewModel(
        rideRepository,
        authRepository,
        userRepository,
      )..determinePosition(),
      child: Consumer<CreateRideViewModel>(
        builder: (context, viewModel, _) {
          _syncControllers(viewModel);
          _maybeMoveCamera(viewModel);

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
            body: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(14.5995, 120.9842),
                    initialZoom: 12,
                    onTap: (tapPosition, point) {
                      viewModel.selectDestination(point);
                      _mapController.move(point, 15);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    if (viewModel.currentLocation != null)
                      CurrentLocationLayer(
                        alignPositionOnUpdate: AlignOnUpdate.always,
                        alignDirectionOnUpdate: AlignOnUpdate.never,
                        style: const LocationMarkerStyle(
                          marker: DefaultLocationMarker(
                            color: Colors.blue,
                            child: Icon(Icons.navigation, color: Colors.white),
                          ),
                          markerSize: Size(40, 40),
                          accuracyCircleColor: Colors.blueAccent,
                        ),
                      ),
                    if (viewModel.destination != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: viewModel.destination!,
                            width: 60,
                            height: 60,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
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
                  ],
                ),
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: Card(
                    elevation: 4,
                    child: TextField(
                      controller: _destinationController,
                      decoration: InputDecoration(
                        hintText: 'Enter destination',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () => viewModel
                              .searchDestination(_destinationController.text),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      onSubmitted: viewModel.searchDestination,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<int>(
                          value: viewModel.selectedSeats,
                          decoration: const InputDecoration(
                            labelText: 'Seats Available',
                            border: OutlineInputBorder(),
                          ),
                          items: List.generate(
                            3,
                            (i) => DropdownMenuItem(
                              value: i + 1,
                              child: Text('${i + 1}'),
                            ),
                          ),
                          onChanged: viewModel.updateSeats,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _messageController,
                          maxLength: 100,
                          minLines: 1,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Note',
                            hintText: 'Add a quick note for hitchers',
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: viewModel.updateMessage,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(45),
                            backgroundColor:
                                const Color.fromARGB(255, 88, 240, 12),
                          ),
                          icon: viewModel.isPosting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: const Text('Post Ride'),
                          onPressed: viewModel.isPosting
                              ? null
                              : () async {
                                  final success = await viewModel.postRide();
                                  final messenger =
                                      ScaffoldMessenger.maybeOf(context);
                                  if (messenger == null) return;
                                  if (success) {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Ride posted successfully!',
                                        ),
                                      ),
                                    );
                                    _destinationController.clear();
                                    _messageController.clear();
                                  } else if (viewModel.errorMessage != null) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          viewModel.errorMessage!,
                                        ),
                                      ),
                                    );
                                    viewModel.resetError();
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _syncControllers(CreateRideViewModel viewModel) {
    final label = viewModel.destinationLabel;
    if (label.isNotEmpty &&
        _destinationController.text.trim() != label.trim()) {
      _destinationController.text = label;
    }

    final note = viewModel.message;
    if (_messageController.text != note) {
      _messageController
        ..text = note
        ..selection = TextSelection.collapsed(offset: note.length);
    }
  }

  void _maybeMoveCamera(CreateRideViewModel viewModel) {
    if (viewModel.currentLocation != null &&
        viewModel.currentLocation != _lastCurrent) {
      _lastCurrent = viewModel.currentLocation;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(viewModel.currentLocation!, 15);
      });
    }

    if (viewModel.destination != null &&
        viewModel.destination != _lastDestination) {
      _lastDestination = viewModel.destination;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(viewModel.destination!, 15);
      });
    }
  }
}

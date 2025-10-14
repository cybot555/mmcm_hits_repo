import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class DriverLiveMap extends StatefulWidget {
  final String rideId;
  final GeoPoint destination;

  const DriverLiveMap({
    super.key,
    required this.rideId,
    required this.destination,
  });

  @override
  State<DriverLiveMap> createState() => _DriverLiveMapState();
}

class _DriverLiveMapState extends State<DriverLiveMap> {
  final MapController _mapController = MapController();
  LatLng? _currentPos;
  List<LatLng> _routePoints = [];
  final dbRT = FirebaseDatabase.instance.ref();

  StreamSubscription<Position>? _posSub;

  @override
  void initState() {
    super.initState();
    _initLocationStream();
  }

  // 🛰️ Initialize GPS tracking
  Future<void> _initLocationStream() async {
    // 1️⃣ Check if location services are on
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    // 2️⃣ Permissions
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
    }

    // 3️⃣ Get initial position to instantly show map
    final initialPos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (!mounted) return;
    setState(() {
      _currentPos = LatLng(initialPos.latitude, initialPos.longitude);
    });

    // 4️⃣ Draw initial route
    await _drawRoute();

    // 5️⃣ Begin continuous location updates
    _posSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // send update after ~10 meters movement
          ),
        ).listen((pos) async {
          if (!mounted) return;

          final newPos = LatLng(pos.latitude, pos.longitude);
          setState(() {
            _currentPos = newPos;
          });

          // 🗺️ Auto-follow the driver as they move
          _mapController.move(newPos, _mapController.camera.zoom);

          // 🔥 Update Firebase Realtime Database
          await dbRT.child('activeRides/${widget.rideId}/driverLocation').set({
            'lat': pos.latitude,
            'lng': pos.longitude,
            'timestamp': ServerValue.timestamp,
          });
        });
  }

  // 🧭 Draw route between current position and destination
  Future<void> _drawRoute() async {
    if (_currentPos == null) return;

    final dest = widget.destination;
    final url =
        "https://router.project-osrm.org/route/v1/driving/${_currentPos!.longitude},${_currentPos!.latitude};${dest.longitude},${dest.latitude}?overview=full&geometries=geojson";

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        final coords =
            data['routes'][0]['geometry']['coordinates'] as List<dynamic>;
        setState(() {
          _routePoints = coords.map((c) => LatLng(c[1], c[0])).toList();
        });
      }
    } catch (e) {
      debugPrint('⚠️ Error drawing route: $e');
    }
  }

  @override
  void dispose() {
    _posSub?.cancel(); // ✅ Stop GPS stream when page closes
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Ride Tracking'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _currentPos == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPos!,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                // Base map tiles
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'mmcm_hits_app',
                ),

                // Route polyline
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 4,
                        color: Colors.blueAccent,
                      ),
                    ],
                  ),

                // Markers: driver + destination
                MarkerLayer(
                  markers: [
                    // Driver (green)
                    Marker(
                      point: _currentPos!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.local_taxi,
                        color: Colors.green,
                        size: 38,
                      ),
                    ),
                    // Destination (red)
                    Marker(
                      point: LatLng(
                        widget.destination.latitude,
                        widget.destination.longitude,
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
  }
}

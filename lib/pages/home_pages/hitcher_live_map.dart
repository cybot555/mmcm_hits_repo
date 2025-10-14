import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HitcherLiveMap extends StatefulWidget {
  final String rideId; // same rideId used by the driver

  const HitcherLiveMap({super.key, required this.rideId});

  @override
  State<HitcherLiveMap> createState() => _HitcherLiveMapState();
}

class _HitcherLiveMapState extends State<HitcherLiveMap> {
  final MapController _mapController = MapController();
  final dbRT = FirebaseDatabase.instance.ref();

  LatLng? driverPos;
  LatLng? destination;
  List<LatLng> routePoints = [];

  StreamSubscription<DatabaseEvent>? _driverSub;
  bool _mapReady = false; // ✅ Prevents controller errors
  bool _mounted = true; // ✅ Avoids setState after dispose

  @override
  void initState() {
    super.initState();
    _loadRideDetails();
  }

  @override
  void dispose() {
    _mounted = false;
    _driverSub?.cancel();
    super.dispose();
  }

  /// 1️⃣ Get destination from Firestore (same data driver posted)
  Future<void> _loadRideDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('rides')
          .doc(widget.rideId)
          .get();

      if (!doc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Ride not found.')));
        }
        return;
      }

      final rideData = doc.data()!;
      final dest = rideData['destinationLocation'] as GeoPoint;

      if (!_mounted) return;
      setState(() {
        destination = LatLng(dest.latitude, dest.longitude);
      });

      _listenToDriverUpdates(); // ✅ Start tracking after destination loaded
    } catch (e) {
      debugPrint('Error loading ride: $e');
    }
  }

  /// 2️⃣ Listen to driver’s live location updates in Realtime Database
  void _listenToDriverUpdates() {
    _driverSub = dbRT
        .child('activeRides/${widget.rideId}/driverLocation')
        .onValue
        .listen((event) async {
          if (!_mounted) return;

          final data = event.snapshot.value as Map?;
          if (data == null) {
            // If ride ended (driver removed entry)
            if (_mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Ride completed by driver.')),
              );
              Navigator.pop(context); // Auto-close map for hitcher
            }
            return;
          }

          final lat = (data['lat'] as num?)?.toDouble();
          final lng = (data['lng'] as num?)?.toDouble();
          if (lat == null || lng == null) return;

          final newPos = LatLng(lat, lng);
          if (_mounted) {
            setState(() {
              driverPos = newPos;
            });
          }

          // ✅ Move only when map is ready
          if (_mapReady && _mounted) {
            _mapController.move(newPos, _mapController.camera.zoom);
          }

          // 🗺️ Draw route once
          if (routePoints.isEmpty && destination != null) {
            await _drawRoute(newPos, destination!);
          }
        });
  }

  /// 3️⃣ Draw route line from driver → destination
  Future<void> _drawRoute(LatLng start, LatLng end) async {
    final url =
        "https://router.project-osrm.org/route/v1/driving/"
        "${start.longitude},${start.latitude};"
        "${end.longitude},${end.latitude}?overview=full&geometries=geojson";

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200 && _mounted) {
        final data = json.decode(response.body);
        final coords =
            data['routes'][0]['geometry']['coordinates'] as List<dynamic>;
        setState(() {
          routePoints = coords.map((c) => LatLng(c[1], c[0])).toList();
        });
      }
    } catch (e) {
      debugPrint('Error drawing route: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Driver Tracker'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: driverPos == null
          ? const Center(child: Text('Waiting for driver to start ride...'))
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: driverPos!,
                initialZoom: 15,
                onMapReady: () {
                  setState(() => _mapReady = true);
                },
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                // 🗺️ Base map (no subdomains = no OSM warning)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'mmcm_hits_app',
                ),

                // 🛣️ Route polyline
                if (routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints,
                        strokeWidth: 4,
                        color: Colors.blueAccent,
                      ),
                    ],
                  ),

                // 📍 Markers
                MarkerLayer(
                  markers: [
                    Marker(
                      point: driverPos!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.local_taxi,
                        color: Colors.green,
                        size: 38,
                      ),
                    ),
                    if (destination != null)
                      Marker(
                        point: destination!,
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

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

  @override
  void initState() {
    super.initState();
    _initLocationStream();
  }

  Future<void> _initLocationStream() async {
    final perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever)
      return;

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
      ),
    ).listen((pos) async {
      setState(() {
        _currentPos = LatLng(pos.latitude, pos.longitude);
      });

      // update RTDB
      await dbRT.child('activeRides/${widget.rideId}/driverLocation').set({
        'lat': pos.latitude,
        'lng': pos.longitude,
        'timestamp': ServerValue.timestamp,
      });

      // draw route once we have both points
      if (_routePoints.isEmpty) _drawRoute();
    });
  }

  Future<void> _drawRoute() async {
    if (_currentPos == null) return;

    final dest = widget.destination;
    final url =
        "https://router.project-osrm.org/route/v1/driving/${_currentPos!.longitude},${_currentPos!.latitude};${dest.longitude},${dest.latitude}?overview=full&geometries=geojson";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final coords =
          data['routes'][0]['geometry']['coordinates'] as List<dynamic>;
      setState(() {
        _routePoints = coords.map((c) => LatLng(c[1], c[0])).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Live Tracking')),
      body: _currentPos == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(initialCenter: _currentPos!, initialZoom: 15),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                // Route line
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
                // Destination pin
                MarkerLayer(
                  markers: [
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
                        size: 40,
                      ),
                    ),
                    if (_currentPos != null)
                      Marker(
                        point: _currentPos!,
                        width: 50,
                        height: 50,
                        child: const Icon(
                          Icons.local_taxi,
                          color: Colors.green,
                          size: 35,
                        ),
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}

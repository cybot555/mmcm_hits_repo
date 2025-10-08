import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController mapController = MapController();
  LatLng? currentLocation;
  LatLng? destination;
  List<LatLng> routePoints = [];
  final TextEditingController destinationController = TextEditingController();
  final TextEditingController seatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // ✅ Get current position
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location services')),
      );
      await Geolocator.openLocationSettings();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
    });

    mapController.move(currentLocation!, 15);
  }

  // ✅ Search destination by name
  Future<void> _searchDestination(String query) async {
    if (query.isEmpty) return;

    final url =
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'mmcm_hits_app/1.0 (your_email@example.com)'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isNotEmpty) {
          double lat = double.parse(data[0]['lat']);
          double lon = double.parse(data[0]['lon']);

          setState(() {
            destination = LatLng(lat, lon);
            destinationController.text = data[0]['display_name'];
            routePoints.clear();
          });

          mapController.move(destination!, 15);
          _drawRoute();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Destination not found')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error ${response.statusCode}: ${response.reasonPhrase}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Failed to reach location service: $e')),
      );
    }
  }

  // ✅ Tap on map → set destination
  void _onTapMap(TapPosition tapPosition, LatLng point) async {
    setState(() {
      destination = point;
      routePoints.clear();
    });

    mapController.move(point, 15);

    final url =
        'https://nominatim.openstreetmap.org/reverse?lat=${point.latitude}&lon=${point.longitude}&format=json';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'mmcm_hits_app/1.0 (your_email@example.com)'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String? name = data['display_name'];

        setState(() {
          destinationController.text =
              name ?? '(${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})';
        });

        _drawRoute();
      } else {
        setState(() {
          destinationController.text = 'Unknown location';
        });
      }
    } catch (e) {
      setState(() {
        destinationController.text = 'Unknown location';
      });
    }
  }

  // ✅ Draw route
  Future<void> _drawRoute() async {
    if (currentLocation == null || destination == null) return;

    try {
      final url =
          "https://router.project-osrm.org/route/v1/driving/${currentLocation!.longitude},${currentLocation!.latitude};${destination!.longitude},${destination!.latitude}?overview=full&geometries=geojson";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coords =
            data['routes'][0]['geometry']['coordinates'] as List<dynamic>;
        setState(() {
          routePoints = coords.map((c) => LatLng(c[1], c[0])).toList();
        });
      }
    } catch (e) {
      print("❌ Route error: $e");
    }
  }

  // ✅ Post ride (no fare)
  void _createRide() {
    if (destination == null || seatController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all ride details')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Ride created to ${destinationController.text} • ${seatController.text} seats available',
        ),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {
      routePoints.clear();
      destination = null;
      destinationController.clear();
      seatController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Ride")),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: LatLng(14.5995, 120.9842),
              initialZoom: 12,
              onTap: _onTapMap,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              if (currentLocation != null)
                CurrentLocationLayer(
                  followOnLocationUpdate: FollowOnLocationUpdate.always,
                ),
              if (destination != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: destination!,
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
            ],
          ),

          // 🔍 Destination search bar
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 4,
              child: TextField(
                controller: destinationController,
                decoration: InputDecoration(
                  hintText: "Enter destination",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () =>
                        _searchDestination(destinationController.text),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ),
          ),

          // 🚘 Bottom form
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                  TextField(
                    controller: seatController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Seats Available",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(45),
                      backgroundColor: Colors.green,
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text("Create Ride"),
                    onPressed: _createRide,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

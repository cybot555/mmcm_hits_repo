import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController mapController = MapController();

  LatLng? currentLocation; // driver current location
  LatLng? destination; // chosen destination (lat,lng)
  List<LatLng> routePoints = [];

  /// ✅ Single source of truth for destination *text*
  final TextEditingController destinationController = TextEditingController();

  /// seats dropdown
  int? selectedSeats;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    destinationController.dispose();
    super.dispose();
  }

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

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
    });
    mapController.move(currentLocation!, 15);
  }

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
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);

          setState(() {
            destination = LatLng(lat, lon);
            destinationController.text =
                data[0]['display_name']; // ✅ keep in sync
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
          SnackBar(
            content: Text(
              'Error ${response.statusCode}: ${response.reasonPhrase}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Failed to reach location service: $e')),
      );
    }
  }

  /// When tapping the map, set both the LatLng *and* the text field.
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
        final name = data['display_name'] as String?;
        setState(() {
          destinationController.text =
              name ??
              '(${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})';
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
      // ignore for now
    }
  }

  /// ✅ Fixed: use `destinationController.text` and also save GeoPoint for coords
  Future<void> postRide() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not logged in')));
      return;
    }

    final destName = destinationController.text.trim();
    if (destName.isEmpty || destination == null || selectedSeats == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a destination and seats')),
      );
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver profile not found')),
        );
        return;
      }

      final driverData = userDoc.data()!;
      final driverName = driverData['email'] ?? 'Unknown Driver';
      final plateNumber = driverData['plateNumber'] ?? 'Unknown Plate';

      final rideData = {
        'driverId': user.uid,
        'driverName': driverName,
        'plateNumber': plateNumber,
        'origin': 'MMCM Campus', // TODO: set real pickup if you add a picker
        'destinationName': destName, // ✅ name
        'destinationLocation': GeoPoint(
          destination!.latitude,
          destination!.longitude,
        ), // ✅ coords
        if (currentLocation != null)
          'pickupLocation': GeoPoint(
            currentLocation!.latitude,
            currentLocation!.longitude,
          ),
        'seatsAvailable': selectedSeats,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('rides').add(rideData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride posted successfully!')),
      );

      // Reset UI
      setState(() {
        routePoints.clear();
        destination = null;
        destinationController.clear();
        selectedSeats = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error posting ride: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: const LatLng(14.5995, 120.9842),
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
                controller: destinationController, // ✅ same controller
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
                onSubmitted: _searchDestination,
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
                  DropdownButtonFormField<int>(
                    value: selectedSeats,
                    decoration: const InputDecoration(
                      labelText: "Seats Available",
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(
                      3,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text('${i + 1}'),
                      ),
                    ),
                    onChanged: (v) => setState(() => selectedSeats = v),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(45),
                      backgroundColor: const Color.fromARGB(255, 88, 240, 12),
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text("Post Ride"),
                    onPressed: postRide,
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

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateRideSection extends StatefulWidget {
  const CreateRideSection({super.key});

  @override
  State<CreateRideSection> createState() => _CreateRideSectionState();
}

class _CreateRideSectionState extends State<CreateRideSection> {
  final Location _location = Location();
  LocationData? _currentLocation;
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _seatsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
  print("🔍 Checking if location service is enabled..."); // ✅

  bool serviceEnabled = await _location.serviceEnabled();
  if (!serviceEnabled) {
    print("⚙️ Requesting location service to be enabled..."); // ✅
    serviceEnabled = await _location.requestService();
    if (!serviceEnabled) {
      print("❌ Location service not enabled."); // ✅
      return;
    }
  }

  print("🔐 Checking for location permission..."); // ✅
  PermissionStatus permissionGranted = await _location.hasPermission();
  if (permissionGranted == PermissionStatus.denied) {
    print("⚙️ Requesting location permission..."); // ✅
    permissionGranted = await _location.requestPermission();
    if (permissionGranted != PermissionStatus.granted) {
      print("❌ Location permission not granted."); // ✅
      return;
    }
  }

  print("📍 Getting current location..."); // ✅
  final loc = await _location.getLocation();
  print("✅ Location obtained: ${loc.latitude}, ${loc.longitude}"); // ✅

  setState(() => _currentLocation = loc);
}


  Future<void> _createRide() async {
    if (_currentLocation == null ||
        _destinationController.text.isEmpty ||
        _seatsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    await FirebaseFirestore.instance.collection('rides').add({
      'driver': user?.email ?? 'Unknown',
      'from': 'Current Location',
      'to': _destinationController.text,
      'seats': int.tryParse(_seatsController.text) ?? 1,
      'lat': _currentLocation!.latitude,
      'lng': _currentLocation!.longitude,
      'timestamp': DateTime.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ride created successfully!')),
    );

    _destinationController.clear();
    _seatsController.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentLocation == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentLatLng =
        LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);

    return Column(
      children: [
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: currentLatLng,
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: currentLatLng,
                    width: 80,
                    height: 80,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              TextField(
                controller: _destinationController,
                decoration: const InputDecoration(
                  labelText: 'Destination',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _seatsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Seats Available',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _createRide,
                icon: const Icon(Icons.add),
                label: const Text("Post Ride"),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

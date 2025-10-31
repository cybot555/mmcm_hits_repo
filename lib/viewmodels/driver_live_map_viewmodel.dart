import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:mmcm_hits/repositories/ride_repository.dart';
import 'package:mmcm_hits/viewmodels/base_viewmodel.dart';

class DriverLiveMapViewModel extends BaseViewModel {
  DriverLiveMapViewModel(
    this._rideRepository, {
    required this.rideId,
    required this.destination,
  });

  final RideRepository _rideRepository;
  final String rideId;
  final GeoPoint destination;

  LatLng? _currentPosition;
  List<LatLng> _routePoints = [];

  StreamSubscription<Position>? _subscription;

  LatLng? get currentPosition => _currentPosition;
  List<LatLng> get routePoints => _routePoints;

  Future<void> initialise() async {
    final hasPermission = await _ensurePermission();
    if (!hasPermission) {
      setError('Location permission denied.');
      return;
    }

    try {
      final initialPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentPosition = LatLng(initialPos.latitude, initialPos.longitude);
      notifyListeners();

      await _drawRoute();
      _startTracking();
    } catch (e) {
      setError('Unable to start tracking.');
    }
  }

  Future<bool> _ensurePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  void _startTracking() {
    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      _currentPosition = LatLng(pos.latitude, pos.longitude);
      notifyListeners();
      _rideRepository.setDriverLocation(
        rideId,
        lat: pos.latitude,
        lng: pos.longitude,
      );
    });
  }

  Future<void> _drawRoute() async {
    if (_currentPosition == null) return;

    final url =
        'https://router.project-osrm.org/route/v1/driving/'
        '${_currentPosition!.longitude},${_currentPosition!.latitude};'
        '${destination.longitude},${destination.latitude}?overview=full&geometries=geojson';

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final coords =
            (data['routes'][0]['geometry']['coordinates'] as List<dynamic>)
                .map((c) => LatLng(
                      (c[1] as num).toDouble(),
                      (c[0] as num).toDouble(),
                    ))
                .toList();
        _routePoints = coords;
        notifyListeners();
      }
    } catch (_) {
      // ignore route errors
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

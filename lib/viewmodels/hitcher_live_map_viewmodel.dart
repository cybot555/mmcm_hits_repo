import 'dart:async';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:mmcm_hits/repositories/ride_repository.dart';
import 'package:mmcm_hits/viewmodels/base_viewmodel.dart';

class HitcherLiveMapViewModel extends BaseViewModel {
  HitcherLiveMapViewModel(this._rideRepository, {required this.rideId});

  final RideRepository _rideRepository;
  final String rideId;

  LatLng? _driverPosition;
  LatLng? _destination;
  List<LatLng> _routePoints = [];
  bool _rideCompleted = false;

  StreamSubscription<DatabaseEvent>? _subscription;

  LatLng? get driverPosition => _driverPosition;
  LatLng? get destination => _destination;
  List<LatLng> get routePoints => _routePoints;
  bool get rideCompleted => _rideCompleted;

  Future<void> initialise() async {
    final ride = await _rideRepository.fetchRide(rideId);
    if (ride?.destinationLocation != null) {
      final geo = ride!.destinationLocation!;
      _destination = LatLng(geo.latitude, geo.longitude);
      notifyListeners();
    } else {
      setError('Ride not found.');
      return;
    }

    _subscription = _rideRepository.watchDriverLocation(rideId).listen(
      (event) async {
        final value = event.snapshot.value;
        if (value == null) {
          _rideCompleted = true;
          notifyListeners();
          return;
        }

        if (value is Map) {
          final lat = (value['lat'] as num?)?.toDouble();
          final lng = (value['lng'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            _driverPosition = LatLng(lat, lng);
            notifyListeners();
            await _drawRoute();
          }
        }
      },
    );
  }

  Future<void> _drawRoute() async {
    if (_driverPosition == null || _destination == null) return;
    if (_routePoints.isNotEmpty) return; // draw once

    final url =
        'https://router.project-osrm.org/route/v1/driving/'
        '${_driverPosition!.longitude},${_driverPosition!.latitude};'
        '${_destination!.longitude},${_destination!.latitude}?overview=full&geometries=geojson';
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

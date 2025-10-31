import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:mmcm_hits/models/ride.dart';
import 'package:mmcm_hits/models/ride_request.dart';
import 'package:mmcm_hits/repositories/auth_repository.dart';
import 'package:mmcm_hits/repositories/ride_repository.dart';
import 'package:mmcm_hits/viewmodels/base_viewmodel.dart';

class DriverRequestsViewModel extends BaseViewModel {
  DriverRequestsViewModel(this._rideRepository, this._authRepository);

  final RideRepository _rideRepository;
  final AuthRepository _authRepository;

  StreamSubscription<Position>? _positionSubscription;
  String? _trackingRideId;
  bool _isTracking = false;

  String? get _uid => _authRepository.currentUser?.uid;

  bool get isTracking => _isTracking;

  Stream<List<Ride>> watchRides({required bool history}) {
    final driverId = _uid;
    if (driverId == null) return const Stream.empty();
    return _rideRepository.watchDriverRides(
      driverId: driverId,
      history: history,
    );
  }

  Stream<List<RideRequest>> watchRideRequests(String rideId) {
    return _rideRepository.watchRideRequests(rideId);
  }

  Future<void> acceptRequest(String rideId, String requestId) async {
    resetError();
    try {
      await _rideRepository.acceptRideRequest(
        rideId: rideId,
        requestId: requestId,
      );
    } catch (e) {
      setError('Error accepting request.');
    }
  }

  Future<void> rejectRequest(String rideId, String requestId) async {
    resetError();
    try {
      await _rideRepository.rejectRideRequest(
        rideId: rideId,
        requestId: requestId,
      );
    } catch (e) {
      setError('Error rejecting request.');
    }
  }

  Future<bool> startRide(String rideId) async {
    if (!await _ensureLocationPermission()) {
      setError('Location permission denied.');
      return false;
    }

    try {
      await _rideRepository.startRide(rideId);
      _isTracking = true;
      _trackingRideId = rideId;
      notifyListeners();

      _positionSubscription?.cancel();
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 15,
        ),
      ).listen((pos) {
        _rideRepository.setDriverLocation(
          rideId,
          lat: pos.latitude,
          lng: pos.longitude,
        );
      });
      return true;
    } catch (e) {
      setError('Error starting ride.');
      return false;
    }
  }

  Future<void> endRide(String rideId) async {
    try {
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      _isTracking = false;
      _trackingRideId = null;
      await _rideRepository.completeRide(rideId);
      await _rideRepository.clearDriverLocation(rideId);
      notifyListeners();
    } catch (e) {
      setError('Error ending ride.');
    }
  }

  Future<bool> _ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}

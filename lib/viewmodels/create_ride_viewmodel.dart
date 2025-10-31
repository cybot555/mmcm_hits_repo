import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:mmcm_hits/repositories/auth_repository.dart';
import 'package:mmcm_hits/repositories/ride_repository.dart';
import 'package:mmcm_hits/repositories/user_repository.dart';
import 'package:mmcm_hits/viewmodels/base_viewmodel.dart';

class CreateRideViewModel extends BaseViewModel {
  CreateRideViewModel(
    this._rideRepository,
    this._authRepository,
    this._userRepository,
  );

  final RideRepository _rideRepository;
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  LatLng? _currentLocation;
  LatLng? _destination;
  List<LatLng> _routePoints = [];
  int? _selectedSeats;
  bool _isPosting = false;
  bool _isLocating = false;
  String _destinationLabel = '';

  LatLng? get currentLocation => _currentLocation;
  LatLng? get destination => _destination;
  List<LatLng> get routePoints => _routePoints;
  int? get selectedSeats => _selectedSeats;
  bool get isPosting => _isPosting;
  bool get isLocating => _isLocating;
  String get destinationLabel => _destinationLabel;

  Future<void> determinePosition() async {
    _isLocating = true;
    notifyListeners();
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setError('Please enable location services.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setError('Location permission denied.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setError('Location permission permanently denied.');
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      _currentLocation = LatLng(position.latitude, position.longitude);
    } catch (e) {
      setError('Unable to determine location.');
    } finally {
      _isLocating = false;
      notifyListeners();
    }
  }

  Future<void> searchDestination(String query) async {
    if (query.isEmpty) return;
    final url =
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'mmcm_hits_app/1.0 (hits@mmcm.edu.ph)'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        if (data.isEmpty) {
          setError('Destination not found.');
          return;
        }
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);
        _destination = LatLng(lat, lon);
        _destinationLabel = data[0]['display_name'] ?? '';
        notifyListeners();
        await _drawRoute();
      } else {
        setError('Failed to search destination.');
      }
    } catch (e) {
      setError('Failed to reach location service.');
    }
  }

  Future<void> selectDestination(LatLng point) async {
    _destination = point;
    _destinationLabel =
        '(${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})';
    _routePoints = [];
    notifyListeners();
    await _reverseGeocode(point);
    await _drawRoute();
  }

  void updateDestinationLabel(String value) {
    _destinationLabel = value;
    notifyListeners();
  }

  void updateSeats(int? seats) {
    _selectedSeats = seats;
    notifyListeners();
  }

  Future<void> _reverseGeocode(LatLng point) async {
    final url =
        'https://nominatim.openstreetmap.org/reverse?lat=${point.latitude}&lon=${point.longitude}&format=json';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'mmcm_hits_app/1.0 (hits@mmcm.edu.ph)'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final name = data['display_name'] as String?;
        if (name != null) {
          _destinationLabel = name;
          notifyListeners();
        }
      }
    } catch (_) {
      // ignore reverse geocode errors
    }
  }

  Future<void> _drawRoute() async {
    if (_currentLocation == null || _destination == null) return;

    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/'
          '${_currentLocation!.longitude},${_currentLocation!.latitude};'
          '${_destination!.longitude},${_destination!.latitude}?overview=full&geometries=geojson';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final coords = (data['routes'][0]['geometry']['coordinates']
                as List<dynamic>)
            .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList();
        _routePoints = coords;
        notifyListeners();
      }
    } catch (_) {
      // ignore route errors
    }
  }

  Future<bool> postRide() async {
    final destination = _destination;
    if (destination == null ||
        _destinationLabel.isEmpty ||
        _selectedSeats == null) {
      setError('Please pick a destination and seats.');
      return false;
    }

    final user = _authRepository.currentUser;
    if (user == null) {
      setError('User not logged in.');
      return false;
    }

    _isPosting = true;
    resetError();
    notifyListeners();

    try {
      final userDoc = await _userRepository.fetchRawUserDoc(user.uid);
      final userData = userDoc.data();
      if (userData == null) {
        setError('Driver profile not found.');
        return false;
      }

      final rideData = {
        'driverId': user.uid,
        'driverName': userData['email'] ?? 'Unknown Driver',
        'plateNumber': userData['plateNumber'] ?? 'Unknown Plate',
        'origin': 'MMCM Campus',
        'destinationName': _destinationLabel,
        'destinationLocation': GeoPoint(
          destination.latitude,
          destination.longitude,
        ),
        if (_currentLocation != null)
          'pickupLocation': GeoPoint(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
          ),
        'seatsAvailable': _selectedSeats,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _rideRepository.createRide(rideData);
      _routePoints = [];
      _destination = null;
      _destinationLabel = '';
      _selectedSeats = null;
      notifyListeners();
      return true;
    } catch (e) {
      setError('Error posting ride.');
      return false;
    } finally {
      _isPosting = false;
      notifyListeners();
    }
  }
}

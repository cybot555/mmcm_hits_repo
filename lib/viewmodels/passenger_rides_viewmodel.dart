import 'dart:async';

import 'package:mmcm_hits/models/ride.dart';
import 'package:mmcm_hits/models/ride_request.dart';
import 'package:mmcm_hits/repositories/auth_repository.dart';
import 'package:mmcm_hits/repositories/ride_repository.dart';
import 'package:mmcm_hits/repositories/user_repository.dart';
import 'package:mmcm_hits/viewmodels/base_viewmodel.dart';

class PassengerRidesViewModel extends BaseViewModel {
  PassengerRidesViewModel(
    this._rideRepository,
    this._authRepository,
    this._userRepository,
  );

  final RideRepository _rideRepository;
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  String? get _uid => _authRepository.currentUser?.uid;

  Stream<List<Ride>> get ridesStream => _rideRepository.watchAllRides();

  Stream<RideRequest?> watchRequestForRide(String rideId) {
    final riderId = _uid;
    if (riderId == null) return const Stream.empty();
    return _rideRepository.watchRequestForRider(
      rideId: rideId,
      riderId: riderId,
    );
  }

  Future<bool> sendRideRequest(String rideId) async {
    final riderId = _uid;
    if (riderId == null) {
      setError('User not logged in.');
      return false;
    }

    setLoading(true);
    resetError();

    try {
      final exists = await _rideRepository.hasExistingRequest(
        rideId: rideId,
        riderId: riderId,
      );

      if (exists) {
        setError('You already requested this ride.');
        return false;
      }

      final userDoc = await _userRepository.fetchRawUserDoc(riderId);
      final userData = userDoc.data();
      if (userData == null) {
        setError('User profile not found.');
        return false;
      }

      final riderName =
          userData['name'] as String? ?? userData['email'] ?? 'Unknown Rider';

      final request = RideRequest(
        id: '',
        riderId: riderId,
        riderName: riderName,
        status: 'pending',
        timestamp: DateTime.now(),
      );

      await _rideRepository.addRideRequest(
        rideId: rideId,
        request: request,
      );
      return true;
    } catch (e) {
      setError('Error sending request.');
      return false;
    } finally {
      setLoading(false);
    }
  }

  bool shouldShowRide({
    required Ride ride,
    required RideRequest? request,
    required bool isHistory,
  }) {
    final userId = _uid;
    if (userId != null && ride.driverId == userId) {
      return false;
    }

    final rideStatus = ride.status;
    final requestStatus = request?.status;

    if (isHistory) {
      return requestStatus == 'accepted' && rideStatus == 'completed';
    }

    if (requestStatus == 'rejected') {
      return false;
    }

    final hasRequest = request != null;
    final isRideCompleted = rideStatus == 'completed';

    if (hasRequest) {
      final isAcceptedOrPending =
          requestStatus == 'accepted' || requestStatus == 'pending';
      return isAcceptedOrPending && !isRideCompleted;
    }

    final isRideOpen = rideStatus == 'open';
    final hasSeats = ride.seatsAvailable > 0;
    return isRideOpen && hasSeats;
  }
}

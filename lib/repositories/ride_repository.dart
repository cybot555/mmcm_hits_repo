import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mmcm_hits/models/ride.dart';
import 'package:mmcm_hits/models/ride_request.dart';

/// Data access for rides, ride requests, and live tracking.
class RideRepository {
  RideRepository(
    FirebaseFirestore firestore,
    FirebaseDatabase realtimeDb,
  )   : _firestore = firestore,
        _realtimeDb = realtimeDb;

  final FirebaseFirestore _firestore;
  final FirebaseDatabase _realtimeDb;

  CollectionReference<Map<String, dynamic>> get _rides =>
      _firestore.collection('rides');

  DatabaseReference _activeRideRef(String rideId) =>
      _realtimeDb.ref('activeRides/$rideId');

  Stream<List<Ride>> watchAllRides() {
    return _rides
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(Ride.fromDoc).toList();
        });
  }

  Future<Ride?> fetchRide(String rideId) async {
    final doc = await _rides.doc(rideId).get();
    if (!doc.exists) return null;
    return Ride.fromDoc(doc);
  }

  Stream<List<Ride>> watchDriverRides({
    required String driverId,
    required bool history,
  }) {
    final statuses = history ? ['completed'] : ['open', 'full', 'ongoing'];
    return _rides
        .where('driverId', isEqualTo: driverId)
        .where('status', whereIn: statuses)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Ride.fromDoc).toList());
  }

  Future<void> createRide(Map<String, dynamic> data) async {
    await _rides.add(data);
  }

  Future<void> updateRide(String rideId, Map<String, dynamic> data) {
    return _rides.doc(rideId).update(data);
  }

  Stream<RideRequest?> watchRequestForRider({
    required String rideId,
    required String riderId,
  }) {
    return _rides
        .doc(rideId)
        .collection('requests')
        .where('riderId', isEqualTo: riderId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return RideRequest.fromDoc(snapshot.docs.first);
        });
  }

  Future<bool> hasExistingRequest({
    required String rideId,
    required String riderId,
  }) async {
    final existing = await _rides
        .doc(rideId)
        .collection('requests')
        .where('riderId', isEqualTo: riderId)
        .limit(1)
        .get();
    return existing.docs.isNotEmpty;
  }

  Future<void> addRideRequest({
    required String rideId,
    required RideRequest request,
  }) async {
    final data = request.toMap();
    data['timestamp'] ??= FieldValue.serverTimestamp();
    await _rides.doc(rideId).collection('requests').add(data);
  }

  Stream<List<RideRequest>> watchRideRequests(String rideId) {
    return _rides
        .doc(rideId)
        .collection('requests')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map(RideRequest.fromDoc).toList();
        });
  }

  Future<void> updateRideRequest({
    required String rideId,
    required String requestId,
    required Map<String, dynamic> data,
  }) {
    return _rides
        .doc(rideId)
        .collection('requests')
        .doc(requestId)
        .update(data);
  }

  Future<void> acceptRideRequest({
    required String rideId,
    required String requestId,
  }) async {
    final rideRef = _rides.doc(rideId);
    final requestRef = rideRef.collection('requests').doc(requestId);

    await _firestore.runTransaction((transaction) async {
      final rideSnap = await transaction.get(rideRef);
      final rideData = rideSnap.data() ?? {};
      final seatsLeft = rideData['seatsAvailable'] ?? 0;
      final seats = seatsLeft is int
          ? seatsLeft
          : int.tryParse('$seatsLeft') ??
              0; // guard against Firestore storing string

      if (seats <= 0) {
        throw StateError('No seats available');
      }

      transaction.update(requestRef, {'status': 'accepted'});
      transaction.update(rideRef, {
        'seatsAvailable': seats - 1,
        if (seats - 1 == 0) 'status': 'full',
      });
    });
  }

  Future<void> rejectRideRequest({
    required String rideId,
    required String requestId,
  }) {
    return updateRideRequest(
      rideId: rideId,
      requestId: requestId,
      data: {'status': 'rejected'},
    );
  }

  Future<void> startRide(String rideId) {
    return updateRide(rideId, {'status': 'ongoing'});
  }

  Future<void> completeRide(String rideId) {
    return updateRide(rideId, {'status': 'completed'});
  }

  Future<void> setDriverLocation(
    String rideId, {
    required double lat,
    required double lng,
  }) async {
    await _activeRideRef(rideId).child('driverLocation').set({
      'lat': lat,
      'lng': lng,
      'timestamp': ServerValue.timestamp,
    });
  }

  Future<void> clearDriverLocation(String rideId) async {
    await _activeRideRef(rideId).remove();
  }

  Stream<DatabaseEvent> watchDriverLocation(String rideId) {
    return _activeRideRef(rideId).child('driverLocation').onValue;
  }
}

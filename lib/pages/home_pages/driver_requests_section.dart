import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'driver_live_map.dart';

class DriverRequestsSection extends StatefulWidget {
  const DriverRequestsSection({super.key});

  @override
  State<DriverRequestsSection> createState() => _DriverRequestsSectionState();
}

class _DriverRequestsSectionState extends State<DriverRequestsSection> {
  final user = FirebaseAuth.instance.currentUser!;
  final db = FirebaseFirestore.instance;
  final dbRT = FirebaseDatabase.instance.ref();
  StreamSubscription<Position>? _positionSubscription;

  /// ✅ Accept request
  Future<void> acceptRequest(String rideId, String requestId) async {
    final rideRef = db.collection('rides').doc(rideId);
    final requestRef = rideRef.collection('requests').doc(requestId);

    await db
        .runTransaction((txn) async {
          final rideSnap = await txn.get(rideRef);
          final rideData = rideSnap.data() as Map<String, dynamic>;
          final seatsLeft = rideData['seatsAvailable'] ?? 0;

          if (seatsLeft > 0) {
            txn.update(requestRef, {'status': 'accepted'});
            txn.update(rideRef, {
              'seatsAvailable': seatsLeft - 1,
              if (seatsLeft - 1 == 0) 'status': 'full',
            });
          } else {
            throw Exception('No seats left');
          }
        })
        .then((_) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('✅ Request accepted')));
        })
        .catchError((e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error accepting: $e')));
        });
  }

  /// ❌ Reject request
  Future<void> rejectRequest(String rideId, String requestId) async {
    await db
        .collection('rides')
        .doc(rideId)
        .collection('requests')
        .doc(requestId)
        .update({'status': 'rejected'});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('❌ Request rejected')));
  }

  /// 🛰️ Check & request location permission
  Future<bool> _checkAndRequestLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location services.')),
      );
      await Geolocator.openLocationSettings();
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied.')),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permissions are permanently denied.'),
        ),
      );
      return false;
    }

    return true;
  }

  /// 🚗 Start ride and begin live tracking
  Future<void> startRide(String rideId) async {
    if (!await _checkAndRequestLocation()) return;

    try {
      await db.collection('rides').doc(rideId).update({'status': 'ongoing'});

      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 15,
            ),
          ).listen((pos) {
            dbRT.child('activeRides/$rideId/driverLocation').set({
              'lat': pos.latitude,
              'lng': pos.longitude,
              'timestamp': ServerValue.timestamp,
            });
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚗 Ride started — live tracking active!'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error starting ride: $e')));
    }
  }

  /// 🏁 End ride & stop tracking
  Future<void> endRide(String rideId) async {
    try {
      await _positionSubscription?.cancel();
      _positionSubscription = null;

      await db.collection('rides').doc(rideId).update({'status': 'completed'});
      await dbRT.child('activeRides/$rideId').remove();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Ride completed — tracking stopped.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error ending ride: $e')));
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  /// 📋 Builds ride list (shared by Active & History tabs)
  Widget buildRideList(BuildContext context, {required bool isHistory}) {
    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('rides')
          .where('driverId', isEqualTo: user.uid)
          .where(
            'status',
            whereIn: isHistory ? ['completed'] : ['open', 'full', 'ongoing'],
          )
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, rideSnap) {
        if (rideSnap.hasError) {
          return Center(child: Text('Error: ${rideSnap.error}'));
        }

        if (!rideSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final rides = rideSnap.data!.docs;
        if (rides.isEmpty) {
          return Center(
            child: Text(
              isHistory
                  ? "No completed rides yet."
                  : "No active rides right now.",
            ),
          );
        }

        return ListView(
          children: rides.map((ride) {
            final rideData = ride.data() as Map<String, dynamic>;
            final rideId = ride.id;
            final destination = rideData['destinationName'] ?? 'Unknown';
            final seats = rideData['seatsAvailable'] ?? 0;
            final rideStatus = rideData['status'] ?? 'open';

            return Card(
              margin: const EdgeInsets.all(10),
              elevation: 3,
              child: ExpansionTile(
                title: Text(
                  destination,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text("Seats available: $seats"),
                children: [
                  // 👇 Always show ride requests, both active and history
                  StreamBuilder<QuerySnapshot>(
                    stream: ride.reference.collection('requests').snapshots(),
                    builder: (context, reqSnap) {
                      if (reqSnap.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('Error: ${reqSnap.error}'),
                        );
                      }

                      if (!reqSnap.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        );
                      }

                      final requests = reqSnap.data!.docs;

                      if (requests.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("No requests yet."),
                        );
                      }

                      final acceptedCount = requests
                          .where(
                            (r) => (r.data() as Map)['status'] == 'accepted',
                          )
                          .length;

                      return Column(
                        children: [
                          ...requests.map((req) {
                            final data = req.data() as Map<String, dynamic>;
                            final status = data['status'] ?? 'pending';
                            final rider = data['riderName'] ?? 'Unknown Rider';

                            Color statusColor;
                            switch (status) {
                              case 'accepted':
                                statusColor = Colors.green;
                                break;
                              case 'rejected':
                                statusColor = Colors.red;
                                break;
                              default:
                                statusColor = Colors.orange;
                            }

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: statusColor,
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(rider),
                              subtitle: Text("Status: $status"),
                              trailing: (!isHistory && status == 'pending')
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.check,
                                            color: Colors.green,
                                          ),
                                          onPressed: () =>
                                              acceptRequest(rideId, req.id),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              rejectRequest(rideId, req.id),
                                        ),
                                      ],
                                    )
                                  : null,
                            );
                          }),
                          if (isHistory)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                "✅ Ride Completed — $acceptedCount passenger(s)",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  const Divider(),

                  // 🚦 Ride controls (active only)
                  if (!isHistory)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        children: [
                          if (rideStatus == 'open' || rideStatus == 'full')
                            ElevatedButton.icon(
                              onPressed: () async {
                                await startRide(rideId);
                                final destGeo =
                                    rideData['destinationLocation']
                                        as GeoPoint?;
                                if (destGeo != null && context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DriverLiveMap(
                                        rideId: rideId,
                                        destination: destGeo,
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text("Start Ride"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          if (rideStatus == 'ongoing') ...[
                            ElevatedButton.icon(
                              onPressed: () => endRide(rideId),
                              icon: const Icon(Icons.flag),
                              label: const Text("End Ride"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            OutlinedButton.icon(
                              onPressed: () {
                                final destGeo =
                                    rideData['destinationLocation']
                                        as GeoPoint?;
                                if (destGeo != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DriverLiveMap(
                                        rideId: rideId,
                                        destination: destGeo,
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.map_outlined),
                              label: const Text("View Live Map"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blueAccent,
                                side: const BorderSide(
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const TabBar(
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF00C853),
                tabs: [
                  Tab(text: "Active"),
                  Tab(text: "History"),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    buildRideList(context, isHistory: false),
                    buildRideList(context, isHistory: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

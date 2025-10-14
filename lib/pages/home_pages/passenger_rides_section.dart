import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'hitcher_live_map.dart'; // ✅ Import the live tracking map

class PassengerRidesSection extends StatefulWidget {
  const PassengerRidesSection({super.key});

  @override
  State<PassengerRidesSection> createState() => _PassengerRidesSectionState();
}

class _PassengerRidesSectionState extends State<PassengerRidesSection> {
  final user = FirebaseAuth.instance.currentUser!;
  final db = FirebaseFirestore.instance;

  /// 🔹 Sends a ride request to a specific ride
  Future<void> sendRideRequest(String rideId) async {
    try {
      final userDoc = await db.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User profile not found')));
        return;
      }

      final userData = userDoc.data()!;
      final riderName = userData['email'] ?? 'Unknown Rider';

      final reqRef = db.collection('rides').doc(rideId).collection('requests');
      final existing = await reqRef
          .where('riderId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You already requested this ride.')),
        );
        return;
      }

      await reqRef.add({
        'riderId': user.uid,
        'riderName': riderName,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Ride request sent!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending request: $e')));
    }
  }

  /// 🗺️ Opens the live tracking map
  void openLiveTracking(String rideId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HitcherLiveMap(rideId: rideId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: StreamBuilder<QuerySnapshot>(
        stream: db
            .collection('rides')
            .where('status', whereIn: ['open', 'ongoing', 'completed'])
            .orderBy('createdAt', descending: true) // 👈 NEW: newest on top
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rides = snapshot.data!.docs;

          if (rides.isEmpty) {
            return const Center(
              child: Text(
                "No rides available right now 🚗",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 10, bottom: 20),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides[index];
              final data = ride.data() as Map<String, dynamic>;

              final destination =
                  data['destinationName'] ?? 'Unknown Destination';
              final driver = data['driverName'] ?? 'Unknown Driver';
              final plate = data['plateNumber'] ?? 'N/A';
              final seats = data['seatsAvailable'] ?? 0;
              final rideStatus = data['status'] ?? 'open';

              // 🔹 Listen to THIS user's request status for each ride
              return StreamBuilder<QuerySnapshot>(
                stream: db
                    .collection('rides')
                    .doc(ride.id)
                    .collection('requests')
                    .where('riderId', isEqualTo: user.uid)
                    .snapshots(),
                builder: (context, reqSnap) {
                  String? requestStatus;
                  if (reqSnap.hasData && reqSnap.data!.docs.isNotEmpty) {
                    final reqData =
                        reqSnap.data!.docs.first.data() as Map<String, dynamic>;
                    requestStatus = reqData['status'];
                  }

                  // 🎨 Button logic
                  Color buttonColor;
                  String buttonText;
                  bool enabled;
                  bool showTrackButton = false;

                  if (requestStatus == 'accepted' && rideStatus == 'ongoing') {
                    buttonColor = Colors.blueAccent;
                    buttonText = '🚗 Ride In Progress';
                    enabled = false;
                    showTrackButton = true;
                  } else if (requestStatus == 'accepted' &&
                      rideStatus == 'open') {
                    buttonColor = Colors.green;
                    buttonText = 'Accepted ✅';
                    enabled = false;
                    showTrackButton = true;
                  } else if (requestStatus == 'accepted' &&
                      rideStatus == 'completed') {
                    buttonColor = Colors.grey;
                    buttonText = '✅ Ride Completed';
                    enabled = false;
                  } else if (requestStatus == 'rejected') {
                    buttonColor = Colors.red;
                    buttonText = 'Rejected ❌';
                    enabled = false;
                  } else if (requestStatus == 'pending') {
                    buttonColor = Colors.orange;
                    buttonText = 'Requested 🕒';
                    enabled = false;
                  } else {
                    buttonColor = const Color(0xFF59E70C);
                    buttonText = 'Request Ride';
                    enabled = true;
                  }

                  // 🧩 Card layout
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.directions_car_rounded,
                                color: Colors.blueAccent,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  destination,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Driver: $driver",
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            "Plate: $plate",
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            "Seats Available: $seats",
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 14),

                          // 🧭 Buttons (improved layout)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: buttonColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size.fromHeight(45),
                                ),
                                onPressed: enabled
                                    ? () => sendRideRequest(ride.id)
                                    : null,
                                icon: const Icon(Icons.send),
                                label: Text(buttonText),
                              ),
                              if (showTrackButton) ...[
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    minimumSize: const Size.fromHeight(42),
                                  ),
                                  onPressed: () => openLiveTracking(ride.id),
                                  icon: const Icon(Icons.map),
                                  label: const Text("Track Ride"),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

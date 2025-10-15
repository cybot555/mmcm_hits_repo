import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'hitcher_live_map.dart';

class PassengerRidesSection extends StatefulWidget {
  const PassengerRidesSection({super.key});

  @override
  State<PassengerRidesSection> createState() => _PassengerRidesSectionState();
}

class _PassengerRidesSectionState extends State<PassengerRidesSection> {
  final user = FirebaseAuth.instance.currentUser!;
  final db = FirebaseFirestore.instance;

  /// 🔹 Send ride request
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
      final riderName = userData['name'] ?? 'Unknown Rider';

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

  /// 🗺️ Open live tracking
  void openLiveTracking(String rideId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HitcherLiveMap(rideId: rideId)),
    );
  }

  /// 🧱 Ride list builder
  Widget buildRideList({required bool isHistory}) {
    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection('rides')
          .orderBy('createdAt', descending: true)
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
          return Center(
            child: Text(
              isHistory
                  ? "No completed rides yet 📜"
                  : "No rides available right now 🚗",
              style: const TextStyle(fontSize: 16),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.only(top: 10, bottom: 20),
          children: rides.map((ride) {
            final data = ride.data() as Map<String, dynamic>;
            final rideId = ride.id;
            final rideStatus = data['status'] ?? 'open';

            return StreamBuilder<QuerySnapshot>(
              stream: db
                  .collection('rides')
                  .doc(rideId)
                  .collection('requests')
                  .where('riderId', isEqualTo: user.uid)
                  .limit(1)
                  .snapshots(),
              builder: (context, reqSnap) {
                if (!reqSnap.hasData) return const SizedBox.shrink();
                if (reqSnap.data!.docs.isEmpty) return const SizedBox.shrink();

                final reqData =
                    reqSnap.data!.docs.first.data() as Map<String, dynamic>;
                final requestStatus = reqData['status'] ?? 'pending';

                final isAccepted = requestStatus == 'accepted';
                final isPending = requestStatus == 'pending';
                final isRejected = requestStatus == 'rejected';
                final isCompleted = rideStatus == 'completed';

                // Hide irrelevant rides
                if (isRejected) return const SizedBox.shrink();
                if (isHistory) {
                  if (!(isAccepted && isCompleted))
                    return const SizedBox.shrink();
                } else {
                  if (!(isAccepted || isPending) || isCompleted) {
                    return const SizedBox.shrink();
                  }
                }

                final destination =
                    data['destinationName'] ?? 'Unknown Destination';
                final driverName = data['driverName'] ?? 'Unknown Driver';
                final driverId = data['driverId'];
                final plate = data['plateNumber'] ?? 'N/A';
                final seats = data['seatsAvailable'] ?? 0;

                // 🎨 Button state
                Color buttonColor;
                String buttonText;
                bool enabled = false;
                bool showTrackButton = false;

                if (isCompleted) {
                  buttonColor = Colors.grey;
                  buttonText = '✅ Ride Completed';
                } else if (isAccepted && rideStatus == 'ongoing') {
                  buttonColor = Colors.blueAccent;
                  buttonText = '🚗 Ride In Progress';
                  showTrackButton = true;
                } else if (isAccepted && rideStatus == 'open') {
                  buttonColor = Colors.green;
                  buttonText = 'Accepted ✅';
                  showTrackButton = true;
                } else if (isPending) {
                  buttonColor = Colors.orange;
                  buttonText = 'Requested 🕒';
                } else {
                  buttonColor = const Color(0xFF59E70C);
                  buttonText = 'Request Ride';
                  enabled = true;
                }

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
                        // 👤 Driver header with pfp
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            FutureBuilder<DocumentSnapshot>(
                              future: db
                                  .collection('users')
                                  .doc(driverId)
                                  .get(),
                              builder: (context, driverSnap) {
                                if (driverSnap.connectionState ==
                                    ConnectionState.waiting) {
                                  return const CircleAvatar(
                                    radius: 25,
                                    backgroundColor: Colors.grey,
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    ),
                                  );
                                }
                                if (!driverSnap.hasData ||
                                    !driverSnap.data!.exists) {
                                  return const CircleAvatar(
                                    radius: 25,
                                    backgroundColor: Colors.grey,
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    ),
                                  );
                                }
                                final driverData =
                                    driverSnap.data!.data()
                                        as Map<String, dynamic>;
                                final imageUrl =
                                    driverData['profileImage'] as String?;
                                return CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.grey[300],
                                  backgroundImage: imageUrl != null
                                      ? NetworkImage(imageUrl)
                                      : null,
                                  child: imageUrl == null
                                      ? const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                        )
                                      : null,
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    driverName,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Plate: $plate",
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                  Text(
                                    "Seats: $seats",
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        Text(
                          "Destination: $destination",
                          style: const TextStyle(fontSize: 15),
                        ),
                        const SizedBox(height: 14),

                        // 🧭 Buttons
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

                        // 🧍‍♀️ Show Other Hitchers (History only)
                        if (isHistory && isCompleted) ...[
                          const SizedBox(height: 20),
                          const Text(
                            "Other Hitchers",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          StreamBuilder<QuerySnapshot>(
                            stream: db
                                .collection('rides')
                                .doc(rideId)
                                .collection('requests')
                                .where('status', isEqualTo: 'accepted')
                                .snapshots(),
                            builder: (context, hitchSnap) {
                              if (hitchSnap.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (!hitchSnap.hasData ||
                                  hitchSnap.data!.docs.isEmpty) {
                                return const Text(
                                  "No other hitchers joined this ride.",
                                  style: TextStyle(color: Colors.black54),
                                );
                              }

                              final hitchers = hitchSnap.data!.docs.where((h) {
                                final data = h.data() as Map<String, dynamic>;
                                return data['riderId'] != user.uid;
                              }).toList();

                              if (hitchers.isEmpty) {
                                return const Text(
                                  "You were the only hitcher 😊",
                                  style: TextStyle(color: Colors.black54),
                                );
                              }

                              return SizedBox(
                                height: 80,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: hitchers.length,
                                  itemBuilder: (context, index) {
                                    final hitcher =
                                        hitchers[index].data() as Map;
                                    final riderId = hitcher['riderId'];
                                    final riderName =
                                        hitcher['riderName'] ?? 'Unknown';

                                    return FutureBuilder<DocumentSnapshot>(
                                      future: db
                                          .collection('users')
                                          .doc(riderId)
                                          .get(),
                                      builder: (context, userSnap) {
                                        String? img;
                                        if (userSnap.hasData &&
                                            userSnap.data!.exists) {
                                          img =
                                              (userSnap.data!.data()
                                                      as Map)['profileImage']
                                                  as String?;
                                        }
                                        return Container(
                                          width: 70,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                          child: Column(
                                            children: [
                                              CircleAvatar(
                                                radius: 24,
                                                backgroundColor:
                                                    Colors.grey[300],
                                                backgroundImage: img != null
                                                    ? NetworkImage(img)
                                                    : null,
                                                child: img == null
                                                    ? const Icon(
                                                        Icons.person,
                                                        color: Colors.white,
                                                      )
                                                    : null,
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                riderName.split(' ').first,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
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
                    buildRideList(isHistory: false),
                    buildRideList(isHistory: true),
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

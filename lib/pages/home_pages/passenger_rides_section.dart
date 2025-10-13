import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
      // Get passenger info
      final userDoc = await db.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User profile not found')));
        return;
      }

      final userData = userDoc.data()!;
      final riderName = userData['email'] ?? 'Unknown Rider';

      // Check if already requested
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

      // Add new request
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Rides"),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db
            .collection('rides')
            .where('status', isEqualTo: 'open')
            //.orderBy('createdAt', descending: true)
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
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides[index];
              final data = ride.data() as Map<String, dynamic>;

              final destination =
                  data['destinationName'] ?? 'Unknown Destination';
              final driver = data['driverName'] ?? 'Unknown Driver';
              final plate = data['plateNumber'] ?? 'N/A';
              final seats = data['seatsAvailable'] ?? 0;
              final departure = data['departureTime']?.toDate();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 👇 Fixed: Allow long destination names to wrap cleanly
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.directions_car,
                            color: Colors.blueAccent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              destination,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              softWrap: true, // allow wrapping
                              maxLines: 3, // up to 3 lines before clipping
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),
                      Text("Driver: $driver"),
                      Text("Plate: $plate"),
                      Text("Seats Available: $seats"),
                      if (departure != null)
                        Text(
                          "Departure: ${departure.hour}:${departure.minute.toString().padLeft(2, '0')}",
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      const SizedBox(height: 10),

                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 88, 240, 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => sendRideRequest(ride.id),
                          icon: const Icon(Icons.send),
                          label: const Text("Request Ride"),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

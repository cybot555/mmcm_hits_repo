import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DriverRequestsSection extends StatefulWidget {
  const DriverRequestsSection({super.key});

  @override
  State<DriverRequestsSection> createState() => _DriverRequestsSectionState();
}

class _DriverRequestsSectionState extends State<DriverRequestsSection> {
  final user = FirebaseAuth.instance.currentUser!;
  final db = FirebaseFirestore.instance;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Incoming Ride Requests"),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db
            .collection('rides')
            .where('driverId', isEqualTo: user.uid)
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
            return const Center(child: Text("No rides posted yet."));
          }

          return ListView(
            children: rides.map((ride) {
              final rideData = ride.data() as Map<String, dynamic>;
              final rideId = ride.id;
              final destination = rideData['destinationName'] ?? 'Unknown';
              final seats = rideData['seatsAvailable'] ?? 0;

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
                    StreamBuilder<QuerySnapshot>(
                      stream: ride.reference
                          .collection('requests')
                          //.orderBy('timestamp', descending: true)
                          .snapshots(),
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

                        // ✅ Added: Expanded + Safe ListView for smoother rebuilds
                        return Column(
                          children: requests.map((req) {
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
                              trailing: status == 'pending'
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
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

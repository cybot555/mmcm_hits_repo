import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mmcm_hits/models/ride.dart';
import 'package:mmcm_hits/models/ride_request.dart';
import 'package:mmcm_hits/pages/home_pages/driver_live_map.dart';
import 'package:mmcm_hits/repositories/auth_repository.dart';
import 'package:mmcm_hits/repositories/ride_repository.dart';
import 'package:mmcm_hits/repositories/user_repository.dart';
import 'package:mmcm_hits/viewmodels/driver_requests_viewmodel.dart';
import 'package:provider/provider.dart';

class DriverRequestsSection extends StatelessWidget {
  const DriverRequestsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final rideRepository = context.read<RideRepository>();
    final authRepository = context.read<AuthRepository>();

    return ChangeNotifierProvider(
      create: (_) => DriverRequestsViewModel(rideRepository, authRepository),
      child: Consumer<DriverRequestsViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final messenger = ScaffoldMessenger.maybeOf(context);
              if (messenger == null) return;
              messenger.showSnackBar(
                SnackBar(content: Text(viewModel.errorMessage!)),
              );
              viewModel.resetError();
            });
          }

          return const DefaultTabController(
            length: 2,
            child: Scaffold(
              body: SafeArea(
                child: Column(
                  children: [
                    TabBar(
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Color(0xFF00C853),
                      tabs: [
                        Tab(text: 'Active'),
                        Tab(text: 'History'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _DriverRideList(isHistory: false),
                          _DriverRideList(isHistory: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DriverRideList extends StatelessWidget {
  final bool isHistory;

  const _DriverRideList({required this.isHistory});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DriverRequestsViewModel>();

    return StreamBuilder<List<Ride>>(
      stream: viewModel.watchRides(history: isHistory),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final rides = snapshot.data!;
        if (rides.isEmpty) {
          return Center(
            child: Text(
              isHistory
                  ? 'No completed rides yet.'
                  : 'No active rides right now.',
            ),
          );
        }

        return ListView.builder(
          itemCount: rides.length,
          itemBuilder: (context, index) {
            final ride = rides[index];
            return _DriverRideCard(ride: ride, isHistory: isHistory);
          },
        );
      },
    );
  }
}

class _DriverRideCard extends StatelessWidget {
  final Ride ride;
  final bool isHistory;

  const _DriverRideCard({
    required this.ride,
    required this.isHistory,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<DriverRequestsViewModel>();
    final destination =
        ride.destinationName.isNotEmpty ? ride.destinationName : 'Unknown';

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
        subtitle: Text('Seats available: ${ride.seatsAvailable}'),
        children: [
          StreamBuilder<List<RideRequest>>(
            stream: viewModel.watchRideRequests(ride.id),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Error: ${snapshot.error}'),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                );
              }

              final requests = snapshot.data!;
              if (requests.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('No requests yet.'),
                );
              }

              final acceptedCount = requests
                  .where((req) => req.status == 'accepted')
                  .length;

              return Column(
                children: [
                  ...requests.map(
                    (request) => _RequestTile(
                      rideId: ride.id,
                      request: request,
                      isHistory: isHistory,
                    ),
                  ),
                  if (isHistory)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '✅ Ride Completed — $acceptedCount passenger(s)',
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
          if (!isHistory)
            _RideControls(
              ride: ride,
              onStart: () async {
                final success = await viewModel.startRide(ride.id);
                final messenger = ScaffoldMessenger.maybeOf(context);
                if (messenger == null) return;

                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('🚗 Ride started — live tracking active!'),
                    ),
                  );
                  final destination = ride.destinationLocation;
                  if (destination != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DriverLiveMap(
                          rideId: ride.id,
                          destination: destination,
                        ),
                      ),
                    );
                  }
                } else if (viewModel.errorMessage != null) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(viewModel.errorMessage!)),
                  );
                  viewModel.resetError();
                }
              },
              onEnd: () async {
                await viewModel.endRide(ride.id);
                final messenger = ScaffoldMessenger.maybeOf(context);
                if (messenger == null) return;
                if (viewModel.errorMessage != null) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(viewModel.errorMessage!)),
                  );
                  viewModel.resetError();
                } else {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('✅ Ride completed — tracking stopped.'),
                    ),
                  );
                }
              },
            ),
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final String rideId;
  final RideRequest request;
  final bool isHistory;

  const _RequestTile({
    required this.rideId,
    required this.request,
    required this.isHistory,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<DriverRequestsViewModel>();
    final userRepository = context.read<UserRepository>();

    Color statusColor;
    switch (request.status) {
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
      leading: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: userRepository.fetchRawUserDoc(request.riderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, color: Colors.white),
            );
          }

          String? imageUrl;
          if (snapshot.hasData && snapshot.data!.data() != null) {
            imageUrl = snapshot.data!.data()!['profileImage'] as String?;
          }

          return CircleAvatar(
            backgroundColor: Colors.grey[300],
            backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
            child: imageUrl == null
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          );
        },
      ),
      title: Text(request.riderName),
      subtitle: Text('Status: ${request.status}'),
      trailing: (!isHistory && request.status == 'pending')
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () async {
                    await viewModel.acceptRequest(rideId, request.id);
                    final messenger = ScaffoldMessenger.maybeOf(context);
                    if (messenger == null) return;
                    if (viewModel.errorMessage != null) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(viewModel.errorMessage!)),
                      );
                      viewModel.resetError();
                    } else {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('✅ Request accepted'),
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () async {
                    await viewModel.rejectRequest(rideId, request.id);
                    final messenger = ScaffoldMessenger.maybeOf(context);
                    if (messenger == null) return;
                    if (viewModel.errorMessage != null) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(viewModel.errorMessage!)),
                      );
                      viewModel.resetError();
                    } else {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('❌ Request rejected'),
                        ),
                      );
                    }
                  },
                ),
              ],
            )
          : null,
    );
  }
}

class _RideControls extends StatelessWidget {
  final Ride ride;
  final Future<void> Function() onStart;
  final Future<void> Function() onEnd;

  const _RideControls({
    required this.ride,
    required this.onStart,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          if (ride.status == 'open' || ride.status == 'full')
            ElevatedButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Ride'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
            ),
          if (ride.status == 'ongoing') ...[
            ElevatedButton.icon(
              onPressed: onEnd,
              icon: const Icon(Icons.flag),
              label: const Text('End Ride'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: () {
                final destination = ride.destinationLocation;
                if (destination != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DriverLiveMap(
                        rideId: ride.id,
                        destination: destination,
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.map_outlined),
              label: const Text('View Live Map'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blueAccent,
                side: const BorderSide(color: Colors.blueAccent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mmcm_hits/models/ride.dart';
import 'package:mmcm_hits/models/ride_request.dart';
import 'package:mmcm_hits/pages/home_pages/hitcher_live_map.dart';
import 'package:mmcm_hits/repositories/auth_repository.dart';
import 'package:mmcm_hits/repositories/ride_repository.dart';
import 'package:mmcm_hits/repositories/user_repository.dart';
import 'package:mmcm_hits/viewmodels/passenger_rides_viewmodel.dart';
import 'package:provider/provider.dart';

class PassengerRidesSection extends StatelessWidget {
  const PassengerRidesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final rideRepository = context.read<RideRepository>();
    final authRepository = context.read<AuthRepository>();
    final userRepository = context.read<UserRepository>();

    return ChangeNotifierProvider(
      create: (_) => PassengerRidesViewModel(
        rideRepository,
        authRepository,
        userRepository,
      ),
      child: Consumer<PassengerRidesViewModel>(
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
                          _RideList(isHistory: false),
                          _RideList(isHistory: true),
                        ],
                      ),
                    )
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

class _RideList extends StatelessWidget {
  final bool isHistory;

  const _RideList({required this.isHistory});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PassengerRidesViewModel>();
    return StreamBuilder<List<Ride>>(
      stream: viewModel.ridesStream,
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
                  ? 'No completed rides yet 📜'
                  : 'No rides available right now 🚗',
              style: const TextStyle(fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 10, bottom: 20),
          itemCount: rides.length,
          itemBuilder: (context, index) {
            final ride = rides[index];
            return _RideCard(
              ride: ride,
              isHistory: isHistory,
            );
          },
        );
      },
    );
  }
}

class _RideCard extends StatelessWidget {
  final Ride ride;
  final bool isHistory;

  const _RideCard({
    required this.ride,
    required this.isHistory,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<PassengerRidesViewModel>();

    return StreamBuilder<RideRequest?>(
      stream: viewModel.watchRequestForRide(ride.id),
      builder: (context, snapshot) {
        RideRequest? request = snapshot.data;
        var shouldRender = viewModel.shouldShowRide(
          ride: ride,
          request: request,
          isHistory: isHistory,
        );

        if (!shouldRender &&
            snapshot.connectionState == ConnectionState.waiting) {
          shouldRender = viewModel.shouldShowRide(
            ride: ride,
            request: null,
            isHistory: isHistory,
          );
          if (shouldRender) {
            request = null;
          }
        }

        if (!shouldRender) return const SizedBox.shrink();

        final rideStatus = ride.status;
        final requestStatus = request?.status;

        final isAccepted = requestStatus == 'accepted';
        final isPending = requestStatus == 'pending';
        final isRejected = requestStatus == 'rejected';
        final isCompleted = rideStatus == 'completed';
        final isOngoing = rideStatus == 'ongoing';
        final isOpen = rideStatus == 'open';
        final isFull = rideStatus == 'full';
        final hasSeats = ride.seatsAvailable > 0;
        final hasRequest = request != null;

        final destination = ride.destinationName.isNotEmpty
            ? ride.destinationName
            : 'Unknown Destination';
        final driverName =
            ride.driverName.isNotEmpty ? ride.driverName : 'Unknown Driver';

        Color buttonColor;
        String buttonText;
        bool enabled = false;
        bool showTrack = false;

        if (isHistory || isCompleted) {
          buttonColor = Colors.grey;
          buttonText = '✅ Ride Completed';
        } else if (isAccepted && isOngoing) {
          buttonColor = Colors.blueAccent;
          buttonText = '🚗 Ride In Progress';
          showTrack = true;
        } else if (isAccepted && (isOpen || isFull)) {
          buttonColor = Colors.green;
          buttonText = 'Accepted ✅';
          showTrack = true;
        } else if (isPending) {
          buttonColor = Colors.orange;
          buttonText = 'Requested 🕒';
        } else if (isRejected) {
          buttonColor = Colors.redAccent;
          buttonText = 'Request Rejected';
        } else if (isOpen && hasSeats) {
          buttonColor = const Color(0xFF59E70C);
          buttonText = 'Request Ride';
          enabled = true;
        } else if (isOngoing && hasRequest) {
          buttonColor = Colors.blueAccent;
          buttonText = '🚗 Ride In Progress';
          showTrack = true;
        } else if (!hasSeats || isFull) {
          buttonColor = Colors.grey;
          buttonText = 'Full';
        } else {
          buttonColor = Colors.grey;
          buttonText = 'Unavailable';
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DriverHeader(driverId: ride.driverId, driverName: driverName),
                const SizedBox(height: 10),
                Text(
                  destination,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.confirmation_number, size: 18),
                    const SizedBox(width: 6),
                    Text('Seats left: ${ride.seatsAvailable}'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.directions_car, size: 18),
                    const SizedBox(width: 6),
                    Text('Plate: ${ride.plateNumber}'),
                  ],
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    minimumSize: const Size.fromHeight(42),
                  ),
                  onPressed: !enabled
                      ? null
                      : () async {
                          final success =
                              await viewModel.sendRideRequest(ride.id);
                          final messenger = ScaffoldMessenger.maybeOf(context);
                          if (messenger == null) return;
                          if (success) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('✅ Ride request sent!'),
                              ),
                            );
                          } else if (viewModel.errorMessage != null) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(viewModel.errorMessage!),
                              ),
                            );
                            viewModel.resetError();
                          }
                        },
                  child: Text(
                    buttonText,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                if (showTrack)
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HitcherLiveMap(rideId: ride.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Track Ride'),
                  ),
                if (isHistory) _CompletedRideInfo(rideId: ride.id),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DriverHeader extends StatelessWidget {
  final String driverId;
  final String driverName;

  const _DriverHeader({
    required this.driverId,
    required this.driverName,
  });

  @override
  Widget build(BuildContext context) {
    final userRepository = context.read<UserRepository>();
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: userRepository.fetchRawUserDoc(driverId),
      builder: (context, snapshot) {
        String? imageUrl;
        if (snapshot.hasData && snapshot.data!.data() != null) {
          imageUrl = snapshot.data!.data()!['profileImage'] as String?;
        }
        return Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey,
              backgroundImage:
                  imageUrl != null ? NetworkImage(imageUrl) : null,
              child: imageUrl == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driverName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Driver • Verified',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CompletedRideInfo extends StatelessWidget {
  final String rideId;

  const _CompletedRideInfo({required this.rideId});

  @override
  Widget build(BuildContext context) {
    final rideRepository = context.read<RideRepository>();
    return StreamBuilder<List<RideRequest>>(
      stream: rideRepository.watchRideRequests(rideId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final hitchers = snapshot.data!
            .where((request) => request.status == 'accepted')
            .toList();

        if (hitchers.isEmpty) {
          return const Text(
            'No other hitchers joined this ride.',
            style: TextStyle(color: Colors.black54),
          );
        }

        return SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: hitchers.length,
            itemBuilder: (context, index) {
              final hitcher = hitchers[index];
              return _HitcherAvatar(riderId: hitcher.riderId);
            },
          ),
        );
      },
    );
  }
}

class _HitcherAvatar extends StatelessWidget {
  final String riderId;

  const _HitcherAvatar({required this.riderId});

  @override
  Widget build(BuildContext context) {
    final userRepository = context.read<UserRepository>();
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: userRepository.fetchRawUserDoc(riderId),
      builder: (context, snapshot) {
        String? img;
        String displayName = 'Unknown';
        if (snapshot.hasData && snapshot.data!.data() != null) {
          final data = snapshot.data!.data()!;
          img = data['profileImage'] as String?;
          displayName = (data['name'] ?? data['email'] ?? 'Unknown') as String;
        }

        return Container(
          width: 70,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[300],
                backgroundImage: img != null ? NetworkImage(img) : null,
                child: img == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 5),
              Text(
                displayName.split(' ').first,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ],
          ),
        );
      },
    );
  }
}

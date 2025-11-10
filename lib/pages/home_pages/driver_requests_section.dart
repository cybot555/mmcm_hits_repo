import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mmcm_hits/components/ride_card_shell.dart';
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
          padding: const EdgeInsets.only(top: 10, bottom: 20),
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
    final destination = ride.destinationName.isNotEmpty
        ? ride.destinationName
        : 'Unknown destination';
    final statusLabel = _driverStatusLabel(ride.status, isHistory);
    final statusColor = _driverStatusColor(ride.status, isHistory);
    final rideNote = ride.message.trim();

    return RideCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(destination, style: RideCardStyles.title),
                    const SizedBox(height: 4),
                    Text(
                      formatRideDate(ride.createdAt),
                      style: RideCardStyles.subtitle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              RideStatusChip(
                label: statusLabel,
                background: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (rideNote.isNotEmpty) ...[
            RideMessageNote(message: rideNote),
            const SizedBox(height: 12),
          ] else ...[
            const SizedBox(height: 4),
          ],
          RideInfoRow(
            icon: Icons.place_outlined,
            label: 'From',
            value: ride.origin.isNotEmpty ? ride.origin : 'Pickup pending',
          ),
          const SizedBox(height: 8),
          RideInfoRow(
            icon: Icons.event_seat_outlined,
            label: 'Seats Left',
            value: '${ride.seatsAvailable}',
          ),
          const SizedBox(height: 8),
          RideInfoRow(
            icon: Icons.directions_car_filled_outlined,
            label: 'Vehicle',
            value: buildVehicleLabel(
              ride.vehicleBrand,
              ride.vehiclePlate,
            ),
          ),
          const SizedBox(height: 18),
          StreamBuilder<List<RideRequest>>(
            stream: viewModel.watchRideRequests(ride.id),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final requests = snapshot.data!;
              final acceptedCount = requests
                  .where((req) => req.status == 'accepted')
                  .length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Passenger Requests',
                          style: RideCardStyles.meta.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isHistory)
                        Text(
                          '$acceptedCount passenger(s)',
                          style: RideCardStyles.subtitle,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (requests.isEmpty)
                    Text(
                      isHistory
                          ? 'No passengers joined this ride.'
                          : 'No requests yet.',
                      style: RideCardStyles.subtitle,
                    )
                  else
                    ...requests.map(
                      (request) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RequestTile(
                          rideId: ride.id,
                          request: request,
                          isHistory: isHistory,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          if (!isHistory) ...[
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 12),
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
        ],
      ),
    );
  }
}

String _driverStatusLabel(String status, bool isHistory) {
  if (isHistory || status == 'completed') return 'Completed';
  if (status == 'ongoing') return 'In Progress';
  if (status == 'full') return 'Full';
  if (status == 'open') return 'Accepting';
  return status.isEmpty ? 'Pending' : _capitalize(status);
}

Color _driverStatusColor(String status, bool isHistory) {
  if (isHistory || status == 'completed') {
    return Colors.grey;
  }
  switch (status) {
    case 'ongoing':
      return Colors.blueAccent;
    case 'full':
      return const Color(0xFF7C3AED);
    case 'open':
      return const Color(0xFF22C55E);
    default:
      return Colors.orange;
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
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
                backgroundImage:
                    imageUrl != null ? NetworkImage(imageUrl) : null,
                child: imageUrl == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              );
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.riderName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                RideStatusChip(
                  label: _capitalize(request.status),
                  background: statusColor,
                ),
              ],
            ),
          ),
          if (!isHistory && request.status == 'pending')
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RequestActionButton(
                  icon: Icons.check,
                  color: Colors.green,
                  onTap: () async {
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
                const SizedBox(width: 6),
                _RequestActionButton(
                  icon: Icons.close,
                  color: Colors.red,
                  onTap: () async {
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
            ),
        ],
      ),
    );
  }
}

class _RequestActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Future<void> Function() onTap;

  const _RequestActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: 40,
      child: IconButton(
        style: IconButton.styleFrom(
          foregroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          onTap();
        },
        icon: Icon(icon),
      ),
    );
  }
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ride.status == 'open' || ride.status == 'full')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Ride'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        if (ride.status == 'ongoing') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onEnd,
              icon: const Icon(Icons.flag),
              label: const Text('End Ride'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
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
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                foregroundColor: Colors.blueAccent,
                side: const BorderSide(color: Colors.blueAccent),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

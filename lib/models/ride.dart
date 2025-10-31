import 'package:cloud_firestore/cloud_firestore.dart';

class Ride {
  final String id;
  final String driverId;
  final String driverName;
  final String plateNumber;
  final String origin;
  final String destinationName;
  final GeoPoint? destinationLocation;
  final GeoPoint? pickupLocation;
  final int seatsAvailable;
  final String status;
  final DateTime? createdAt;

  Ride({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.plateNumber,
    required this.origin,
    required this.destinationName,
    required this.seatsAvailable,
    required this.status,
    this.destinationLocation,
    this.pickupLocation,
    this.createdAt,
  });

  factory Ride.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Ride(
      id: doc.id,
      driverId: data['driverId'] ?? '',
      driverName: data['driverName'] ?? '',
      plateNumber: data['plateNumber'] ?? '',
      origin: data['origin'] ?? '',
      destinationName: data['destinationName'] ?? '',
      destinationLocation: data['destinationLocation'],
      pickupLocation: data['pickupLocation'],
      seatsAvailable: (data['seatsAvailable'] ?? 0) is int
          ? data['seatsAvailable'] ?? 0
          : int.tryParse('${data['seatsAvailable']}') ?? 0,
      status: data['status'] ?? 'open',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'plateNumber': plateNumber,
      'origin': origin,
      'destinationName': destinationName,
      'destinationLocation': destinationLocation,
      'pickupLocation': pickupLocation,
      'seatsAvailable': seatsAvailable,
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  Ride copyWith({
    String? status,
    int? seatsAvailable,
  }) {
    return Ride(
      id: id,
      driverId: driverId,
      driverName: driverName,
      plateNumber: plateNumber,
      origin: origin,
      destinationName: destinationName,
      destinationLocation: destinationLocation,
      pickupLocation: pickupLocation,
      seatsAvailable: seatsAvailable ?? this.seatsAvailable,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}

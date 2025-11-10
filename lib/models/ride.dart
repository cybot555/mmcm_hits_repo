import 'package:cloud_firestore/cloud_firestore.dart';

class Ride {
  final String id;
  final String driverId;
  final String driverName;
  final String vehicleBrand;
  final String vehiclePlate;
  final String origin;
  final String destinationName;
  final GeoPoint? destinationLocation;
  final GeoPoint? pickupLocation;
  final int seatsAvailable;
  final String status;
  final DateTime? createdAt;
  final String message;

  Ride({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.vehicleBrand,
    required this.vehiclePlate,
    required this.origin,
    required this.destinationName,
    required this.seatsAvailable,
    required this.status,
    required this.message,
    this.destinationLocation,
    this.pickupLocation,
    this.createdAt,
  });

  factory Ride.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    String vehicleBrand = '';
    String vehiclePlate = '';
    final vehicleData = data['vehicle'];
    if (vehicleData is Map<String, dynamic>) {
      vehicleBrand = (vehicleData['brand'] ?? '').toString();
      vehiclePlate = (vehicleData['plate'] ?? '').toString();
    }
    if (vehiclePlate.isEmpty) {
      vehiclePlate = (data['plateNumber'] ?? '').toString();
    }

    return Ride(
      id: doc.id,
      driverId: data['driverId'] ?? '',
      driverName: data['driverName'] ?? '',
      vehicleBrand: vehicleBrand,
      vehiclePlate: vehiclePlate,
      origin: data['origin'] ?? '',
      destinationName: data['destinationName'] ?? '',
      destinationLocation: data['destinationLocation'],
      pickupLocation: data['pickupLocation'],
      seatsAvailable: (data['seatsAvailable'] ?? 0) is int
          ? data['seatsAvailable'] ?? 0
          : int.tryParse('${data['seatsAvailable']}') ?? 0,
      status: data['status'] ?? 'open',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      message: data['message'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'plateNumber': vehiclePlate,
      'vehicle': {
        'brand': vehicleBrand,
        'plate': vehiclePlate,
      },
      'origin': origin,
      'destinationName': destinationName,
      'destinationLocation': destinationLocation,
      'pickupLocation': pickupLocation,
      'seatsAvailable': seatsAvailable,
      'status': status,
      'message': message,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  Ride copyWith({
    String? status,
    int? seatsAvailable,
    String? message,
    String? vehicleBrand,
    String? vehiclePlate,
  }) {
    return Ride(
      id: id,
      driverId: driverId,
      driverName: driverName,
      vehicleBrand: vehicleBrand ?? this.vehicleBrand,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      origin: origin,
      destinationName: destinationName,
      destinationLocation: destinationLocation,
      pickupLocation: pickupLocation,
      seatsAvailable: seatsAvailable ?? this.seatsAvailable,
      status: status ?? this.status,
      message: message ?? this.message,
      createdAt: createdAt,
    );
  }
}

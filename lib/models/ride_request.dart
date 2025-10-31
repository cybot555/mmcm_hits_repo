import 'package:cloud_firestore/cloud_firestore.dart';

class RideRequest {
  final String id;
  final String riderId;
  final String riderName;
  final String status;
  final DateTime? timestamp;

  RideRequest({
    required this.id,
    required this.riderId,
    required this.riderName,
    required this.status,
    required this.timestamp,
  });

  factory RideRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return RideRequest(
      id: doc.id,
      riderId: data['riderId'] ?? '',
      riderName: data['riderName'] ?? '',
      status: data['status'] ?? 'pending',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'riderId': riderId,
      'riderName': riderName,
      'status': status,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : null,
    };
  }

  RideRequest copyWith({String? status}) {
    return RideRequest(
      id: id,
      riderId: riderId,
      riderName: riderName,
      status: status ?? this.status,
      timestamp: timestamp,
    );
  }
}

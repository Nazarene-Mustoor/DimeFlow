import 'package:cloud_firestore/cloud_firestore.dart';

class Getaway {
  final String id;
  final String name;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final String type; // vacation, business, concert, etc.

  Getaway({
    required this.id,
    required this.name,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.type,
  });

  // Convert to Map for Firestore (excluding 'id', since Firestore sets it separately)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'type': type,
    };
  }

  // Create a Getaway from Firestore map and document ID
  factory Getaway.fromMap(Map<String, dynamic> map, String id) {
    return Getaway(
      id: id, // ✅ Use the actual Firestore doc ID
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      startDate: map['startDate'] is Timestamp
          ? (map['startDate'] as Timestamp).toDate()
          : DateTime.tryParse(map['startDate'] ?? '') ?? DateTime.now(),
      endDate: map['endDate'] is Timestamp
          ? (map['endDate'] as Timestamp).toDate()
          : DateTime.tryParse(map['endDate'] ?? '') ?? DateTime.now(),
      type: map['type'] ?? 'Other',
    );
  }

  // Create a Getaway directly from a Firestore document snapshot
  factory Getaway.fromSnapshot(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return Getaway.fromMap(map, doc.id);
  }

  // Helper to copy the object with optional new values
  Getaway copyWith({
    String? id,
    String? name,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    String? type,
  }) {
    return Getaway(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
    );
  }
}

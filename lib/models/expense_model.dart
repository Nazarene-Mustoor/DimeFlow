import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String userId;
  final double amount;
  final DateTime date;
  final String category;
  final String? note;
  final String emoji;

  ExpenseModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.date,
    required this.category,
    this.note,
    required this.emoji,
  });

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'emoji': emoji,
      'note': note,
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map, String id) {
    return ExpenseModel(
      id: id, // Firestore document ID
      userId: map['userId'] ?? '', // Default to empty string if null
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0, // Ensures it works even if null
      date: (map['date'] is Timestamp)
          ? (map['date'] as Timestamp).toDate()  // ✅ Convert Firestore Timestamp
          : (map['date'] is String)
          ? DateTime.parse(map['date']) // ✅ Convert stored String date
          : DateTime.now(), // ❌ Fallback only if completely missing
      category: map['category'] ?? 'Other', // Default category if null
      emoji: map['emoji'] ?? '✨', // Default emoji if null
      note: map['note'] ?? '', // Default note if null
    );
  }

  // Helper method to copy with new values
  ExpenseModel copyWith({
    String? id,
    String? userId,
    double? amount,
    DateTime? date,
    String? category,
    String? emoji,
    String? note,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      emoji: emoji ?? this.emoji,
      note: note ?? this.note,
    );
  }
}

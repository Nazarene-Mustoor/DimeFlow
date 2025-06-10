import 'package:cloud_firestore/cloud_firestore.dart';

class GetawayExpenseModel {
  String? id;
  String getawayId;
  String category;
  String emoji;
  double amount;
  String description;
  Timestamp dateAdded;
  String userId;

  GetawayExpenseModel ({
    this.id,
    required this.getawayId,
    required this.category,
    required this.emoji,
    required this.amount,
    required this.description,
    required this.dateAdded,
    required this.userId,
  });

  //Convert a GetawayExpenseModel to a Map for Firebase
  Map<String, dynamic> toMap() {
    return{
      'getawayId': getawayId,
      'category': category,
      'emoji': emoji,
      'amount': amount,
      'description': description,
      'dateAdded': dateAdded,
      'userId': userId,
    };
  }

  //Convert a Map to a GetawayExpenseModel
  factory GetawayExpenseModel.fromMap(Map<String,dynamic> map) {
    return GetawayExpenseModel(
      getawayId: map['getawayId'],
      category: map['category'],
      emoji: map['emoji'],
      amount: map['amount'],
      description: map['description'],
      dateAdded: map['dateAdded'],
      userId: map['userId'],
    );
  }

  //Convert Firestore DocumentSnapshot to GetawayExpenseModel
  factory GetawayExpenseModel.fromSnapshot(DocumentSnapshot doc) {
    return GetawayExpenseModel(
      id: doc.id,
      getawayId: doc['getawayId'],
      category: doc['category'],
      emoji: doc['emoji'],
      amount: doc['amount'],
      description: doc['description'],
      dateAdded: doc['dateAdded'],
      userId: doc['userId'],
    );
  }
}
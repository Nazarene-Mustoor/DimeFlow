import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? _user;

  UserModel? get user => _user;

  // Fetch user data
  Future<void> fetchUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        _user = UserModel.fromMap(doc.data()!); // Fixed `fromMap`
        notifyListeners();
      }
    } catch (e) {
      throw Exception("Failed to fetch user: $e");
    }
  }

  // Update user data
  Future<void> updateUser(UserModel updatedUser) async {
    try {
      await _firestore.collection('users').doc(updatedUser.id).set(updatedUser.toMap()); // Fixed `toMap`
      _user = updatedUser;
      notifyListeners();
    } catch (e) {
      throw Exception("Failed to update user: $e");
    }
  }
}
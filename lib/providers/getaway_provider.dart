import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/getaway_model.dart';
import 'package:collection/collection.dart';

class GetawayProvider with ChangeNotifier{
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Getaway> _getaways = [];

  List<Getaway> get getaways => _getaways;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Fetch all getaways for a user
  Future<bool> fetchGetaways() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('getaways')
          .orderBy('startDate', descending: true)
          .get();

      _getaways = snapshot.docs.map((doc) {
        return Getaway.fromMap(doc.data(), doc.id);
      }).toList();

      return _getaways.isNotEmpty;

    } catch (e) {
      print('Error fetching getaways: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //Add a getaway
  Future<void> addGetaway(Getaway getaway) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid; // Get real logged-in user ID

      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('getaways')
          .add(getaway.toMap());

      final newGetaway = getaway.copyWith(id: docRef.id);
      _getaways.insert(0, newGetaway);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding getaway: $e');
    }
  }

  //Delete a getaway
  Future<void> deleteGetaway(String getawayId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      final userId = user.uid;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('getaways')
          .doc(getawayId)
          .delete();

      _getaways.removeWhere((g) => g.id == getawayId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting getaway: $e');
    }
  }

  // Get a single getaway by ID
  Getaway? getGetawayById(String id) {
    return _getaways.firstWhereOrNull((g) => g.id == id);
  }
}
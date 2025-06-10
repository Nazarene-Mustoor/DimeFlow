import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CurrencyProvider with ChangeNotifier {
  String _currency = '₹'; // Default symbol

  String get currency => _currency;

  /// Load the currency from Firestore when the app starts
  Future<void> loadCurrency() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (userDoc.exists && userDoc.data()?['currency'] != null) {
      _currency = userDoc.data()!['currency'];
      notifyListeners();
    }
  }

  /// Change the currency and update it in Firestore
  Future<void> changeCurrency(String newCurrency) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'currency': newCurrency});

      _currency = newCurrency;
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update currency: $e');
    }
  }
}

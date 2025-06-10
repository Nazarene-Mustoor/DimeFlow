import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/getaway_expense_model.dart';

class GetawayExpenseProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<GetawayExpenseModel> _expenses = [];
  List<GetawayExpenseModel> get expenses => _expenses;

  //Fetch expenses for a specific getaway
  Future<void> fetchExpenses(String userId, String getawayId) async {
    if (getawayId.isEmpty) {
      throw Exception('Getaway ID is empty!');
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('getaways')
          .doc(getawayId)
          .collection('getawayExpenses')
          .orderBy('dateAdded', descending: true)
          .get();

      _expenses = snapshot.docs
          .map((doc) => GetawayExpenseModel.fromSnapshot(doc))
          .toList();

      notifyListeners();
    } catch (e) {
      throw Exception('Error fetching getaway expenses: $e');
    }
  }

  //Add a new getaway expense
  Future<void> addExpense(GetawayExpenseModel expense) async {
    try {
      final docRef = await _firestore
          .collection('users') // Ensure you're in the correct user's collection
          .doc(expense.userId)
          .collection('getaways')
          .doc(expense.getawayId)
          .collection('getawayExpenses')
          .add(expense.toMap());

      // Add with doc ID included
      _expenses.add(
        GetawayExpenseModel(
          id: docRef.id,
          getawayId: expense.getawayId,
          category: expense.category,
          emoji: expense.emoji,
          amount: expense.amount,
          description: expense.description,
          dateAdded: expense.dateAdded,
          userId: expense.userId,
        ),
      );
      notifyListeners();
    } catch (e) {
      print('Error adding expense: $e');
    }
  }

  Future<void> deleteExpense(String expenseId, String getawayId, String userId) async {
    try {
      // Delete the expense from the correct path
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('getaways')
          .doc(getawayId)
          .collection('getawayExpenses')
          .doc(expenseId)
          .delete();

      // Remove the expense from the local list
      _expenses.removeWhere((expense) => expense.id == expenseId);
      notifyListeners();
    } catch (e) {
      print('Error deleting expense: $e');
    }
  }

  // Clear all when switching getaways (optional)
  void clearExpense() {
    _expenses = [];
    notifyListeners();
  }
}
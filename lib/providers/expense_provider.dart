import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import 'package:fl_chart/fl_chart.dart';

class ExpenseProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ExpenseModel> _expenses = [];

  List<ExpenseModel> get expenses => _expenses;

  // Fetch all expenses for a user
  Future<void> fetchExpenses(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .get();

      _expenses = snapshot.docs
          .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
          .toList();
      notifyListeners();
    } catch (e) {
      throw Exception("Failed to fetch expenses: $e");
    }
  }

  // Add a new expense
  Future<void> addExpense(ExpenseModel expense) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid; // Get real logged-in user ID

      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .add(expense.toMap());

      _expenses.add(expense.copyWith(id: docRef.id)); // Update expense with Firestore ID
      notifyListeners();
    } catch (e) {
      throw Exception("Failed to add expense: $e");
    }
  }

  // Delete an expense
  Future<void> deleteExpense(String expenseId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid; // Get real logged-in user ID

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .doc(expenseId).delete();
      // await _firestore.collection('expenses').doc(expenseId).delete();
      _expenses.removeWhere((expense) => expense.id == expenseId);
      notifyListeners();
    } catch (e) {
      throw Exception("Failed to delete expense: $e");
    }
  }

  // undo deleted expenses
  void insertExpense(ExpenseModel expense, int index) {
    _expenses.insert(index, expense);
    notifyListeners();
    // Also add it back to Firestore so it persists
    final userId = FirebaseAuth.instance.currentUser!.uid; // Get real logged-in user ID
    // _firestore.collection('expenses').doc(expense.id).set(expense.toMap());
    _firestore.collection('users')
    .doc(userId)
    .collection('expenses')
    .doc(expense.id)
    .set(expense.toMap());
  }

  // Update an existing expense
  Future<void> updateExpense(ExpenseModel updatedExpense) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .doc(updatedExpense.id)
          .update(updatedExpense.toMap());

      // await _firestore.collection('expenses').doc(updatedExpense.id).update(updatedExpense.toMap());

      // Update the local list
      int index = _expenses.indexWhere((expense) => expense.id == updatedExpense.id);
      if (index != -1) {
        _expenses[index] = updatedExpense;
        notifyListeners();
      }
    } catch (e) {
      throw Exception("Failed to update expense: $e");
    }
  }

  // Weekly trend data (Mon–Sun) [Home Screen]
  List<FlSpot> getWeeklyTrendData() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Monday

    Map<int, double> dayTotals = {for (var i = 0; i < 7; i++) i: 0.0};

    for (var expense in expenses) {
      final date = expense.date;
      if (date.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
          date.isBefore(now.add(Duration(days: 1)))) {
        final weekday = date.weekday - 1; // Monday = 0
        dayTotals[weekday] = (dayTotals[weekday] ?? 0.0) + expense.amount;
      }
    }

    return dayTotals.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

// Monthly trend data (1–31) [Home Screen]
  List<FlSpot> getMonthlyTrendData() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final totalDays = endOfMonth.day;

    Map<int, double> dayTotals = {for (var i = 1; i <= totalDays; i++) i: 0.0};

    for (var expense in expenses) {
      final date = expense.date;
      if (date.isAfter(startOfMonth.subtract(Duration(days: 1))) &&
          date.isBefore(endOfMonth.add(Duration(days: 1)))) {
        final day = date.day;
        dayTotals[day] = (dayTotals[day] ?? 0.0) + expense.amount;
      }
    }

    return dayTotals.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  //Horizontal Bar / Pie Chart: Spend by Category [Insights Screen]
  Map<String, double> getCategoryTotalsForMonth(DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);

    Map<String, double> categoryTotals = {};

    for (final expense in expenses) {
      if (expense.date.isAfter(start.subtract(const Duration(days: 1))) &&
          expense.date.isBefore(end)) {
        final category = expense.category;
        categoryTotals[category] = (categoryTotals[category] ?? 0) + expense.amount;
      }
    }

    return categoryTotals;
  }

  //Monthly Comparison ( current month total vs previous month total) [Insights Screen]
  double getTotalForMonth(DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);

    return expenses
        .where((e) => e.date.isAfter(start.subtract(const Duration(days: 1))) &&
        e.date.isBefore(end))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  Map<String, dynamic> getMonthlyComparison(DateTime month) {
    final currentMonthTotal = getTotalForMonth(month);
    final prevMonth = DateTime(month.year, month.month - 1);
    final prevMonthTotal = getTotalForMonth(prevMonth);

    final diff = currentMonthTotal - prevMonthTotal;
    final percent = prevMonthTotal == 0 ? 100 : (diff / prevMonthTotal) * 100;

    String comment;
    if (percent > 10) {
      comment = 'Spending increased by ${percent.toStringAsFixed(1)}%';
    } else if (percent < -10) {
      comment = 'Good job! Spending decreased by ${percent.abs().toStringAsFixed(1)}%';
    } else {
      comment = 'Spending remained fairly stable';
    }

    return {
      'current': currentMonthTotal,
      'previous': prevMonthTotal,
      'percent': percent,
      'comment': comment,
    };
  }

  // Get Expenses by Month and Category [Insights Screen]
  List<ExpenseModel> getExpensesForCategoryAndMonth(String category, DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);

    return expenses.where((expense) =>
    expense.category == category &&
        expense.date.isAfter(start.subtract(const Duration(days: 1))) &&
        expense.date.isBefore(end)
    ).toList();
  }

  // Get Category Spike Detection badge [Insights Screen]
  Map<String, double> getCategorySpikes(DateTime currentMonth, {int lookbackMonths = 3}) {
    final currentTotals = getCategoryTotalsForMonth(currentMonth);
    Map<String, List<double>> pastTotals = {};

    for (int i = 1; i <= lookbackMonths; i++) {
      final pastMonth = DateTime(currentMonth.year, currentMonth.month - i);
      final monthTotals = getCategoryTotalsForMonth(pastMonth);

      monthTotals.forEach((category, amount) {
        pastTotals.putIfAbsent(category, () => []).add(amount);
      });
    }

    Map<String, double> spikes = {};

    currentTotals.forEach((category, currentAmount) {
      final past = pastTotals[category];
      if (past != null && past.isNotEmpty) {
        final avg = past.reduce((a, b) => a + b) / past.length;
        if (currentAmount > avg * 1.5) {
          spikes[category] = currentAmount - avg;
        }
      }
    });

    return spikes;
  }

}
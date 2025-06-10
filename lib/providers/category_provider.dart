import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/category_model.dart';

class CategoryProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<CategoryModel> _categories = [];

  List<CategoryModel> get categories => _categories;

  // Fetch categories for a specific user
  Future<void> fetchCategories(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('categories')
          .get();
      _categories = snapshot.docs.map((doc) => CategoryModel.fromMap(doc.data())).toList();
      notifyListeners();
    } catch (e) {
      throw Exception("Failed to fetch categories: $e");
    }
  }

  // Add a new category (when a user adds an expense)
  Future<void> addCategory(String userId, CategoryModel category) async {
    try {
      final categoryRef = _firestore.collection('users').doc(userId).collection('categories');

      // Check if category already exists
      final existingCategory = await categoryRef.where('name', isEqualTo: category.name).get();
      if (existingCategory.docs.isEmpty) {
        await categoryRef.add(category.toMap());
        _categories.add(category);
        notifyListeners();
      }
    } catch (e) {
      throw Exception("Failed to add category: $e");
    }
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import'package:flutter/material.dart';
import 'package:intl/intl.dart';// Import intl for formatting
import 'package:provider/provider.dart';

import '../models/expense_model.dart';
import '../providers/expense_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  final bool isEditing;
  final Map<String,dynamic>? expenseData;

  const AddExpenseScreen({
    super.key,
    this.isEditing = false,
    this.expenseData,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  late TextEditingController _dateController;

  Map<String, String> categoryEmojis = {
    'Food': '🍕',
    'Transport': '🚗',
    'Shopping': '🛍️',
    'Bills': '🧾',
    'Other': '✨',
  };

  List<String> categories = ['Food', 'Transport', 'Shopping', 'Bills', 'Other'];
  String? _selectedCategory;

  Future<String?> _pickCategoryEmoji(BuildContext context, String category) async {
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Pick an Emoji'),
        content: SizedBox(
          height: 300,
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) {
              Navigator.pop(context, emoji.emoji); // Return selected emoji
            },
          ),
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    TextEditingController categoryController = TextEditingController();
    String selectedEmoji = '✨'; // Default emoji

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Add Category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: categoryController,
                    decoration: const InputDecoration(
                      hintText: 'Enter category name',
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blueGrey, width: 2.0), // Color when focused
                      ),
                    ),
                    cursorColor: Colors.black54,
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      String? emoji = await _pickCategoryEmoji(context, categoryController.text);
                      if (emoji != null) {
                        setDialogState(() { // 👈 Update only the dialog state
                          selectedEmoji = emoji;
                        });
                      }
                    },
                    child: Text(
                      'Pick Emoji: $selectedEmoji',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.blueGrey)),
                ),
                TextButton(
                  onPressed: () {
                    String newCategory = categoryController.text.trim();
                    if (newCategory.isNotEmpty && !categories.contains(newCategory)) {
                      setState(() {
                        categories.insert(0, newCategory);
                        _selectedCategory = newCategory;
                        categoryEmojis[newCategory] = selectedEmoji; // Assign emoji
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add', style: TextStyle(color: Colors.blueGrey)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _fetchCategories() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final categoryCollection = FirebaseFirestore.instance.collection('users').doc(userId).collection('categories');
    final snapshot = await categoryCollection.get();

    final fetchedCategories = snapshot.docs.map((doc) => doc['name'].toString()).toList();
    final fetchedCategoryEmojis = {
      for (var doc in snapshot.docs) doc['name'].toString(): (doc['emoji'] ?? '✨').toString()
    };

    setState(() {
      categories = ['Food', 'Transport', 'Shopping', 'Bills', 'Other', ...fetchedCategories];
      categoryEmojis.addAll(fetchedCategoryEmojis); // Store fetched emojis

      // Keep _selectedCategory unchanged if it's valid
      if (_selectedCategory != null && !categories.contains(_selectedCategory)) {
        categories.add(_selectedCategory!);
      }
    });
  }

  void _deleteCategory(String category) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Confirmation before deleting
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Delete Category?"),
        content: Text("Are you sure you want to delete '$category'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.blueGrey),),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      setState(() {
        categories.remove(category); // Remove category from list
        categoryEmojis.remove(category); // Remove emoji from list
      });

      // Delete from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('categories')
          .doc(category) // Assuming the category name is the document ID
          .delete();
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.isEditing && widget.expenseData != null) {
      _amountController.text = widget.expenseData!['amount'].toString();
      _descriptionController.text = widget.expenseData!['note'] ?? '';
      _selectedCategory = widget.expenseData!['category'];

      // ✅ Now that `ExpenseModel.fromMap` is fixed, this should work correctly!
      _selectedDate = widget.expenseData!['date'];

      // Ensure the category emoji exists for custom categories
      if (_selectedCategory != null && !categoryEmojis.containsKey(_selectedCategory)) {
        categoryEmojis[_selectedCategory!] = '✨';
      }
    } else {
      // Default values for new expense
      _selectedDate = DateTime.now();
    }

    // Fetch categories **after** setting _selectedCategory
    _fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Expense' : 'Add Expense'),
        backgroundColor:const Color(0xFF305038,),
        foregroundColor: const Color(0xFFFFD700),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 30),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(
                        color: Colors.blueGrey,
                      )
                    ),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Colors.blueGrey,
                        )
                    ),
                    hintText: 'Amount',
                    hintStyle: const TextStyle(color: Colors.grey),
                  ),
                  cursorColor: Colors.black54,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter an amount';
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                categories.isEmpty
                    ? const CircularProgressIndicator(color: Colors.black,) // or any loading indicator
                    : PopupMenuButton<String>(
                        color:Colors.white,
                        constraints: const BoxConstraints(minWidth: double.infinity), // Makes popup wider,
                        onSelected: (value) {
                          if (value == 'add_new') {
                            _showAddCategoryDialog();
                          } else {
                            setState(() {
                              _selectedCategory = value;
                            });
                          }
                        },
                        itemBuilder: (context) => [
                          ...categories.map((category) {
                            return PopupMenuItem(
                              value: category,
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onLongPress: () async {
                                      String? newEmoji = await _pickCategoryEmoji(context, category);
                                      if (newEmoji != null) {
                                        setState(() {
                                          categoryEmojis[category] = newEmoji;
                                        });
                                      }
                                    },
                                    child: Text(categoryEmojis[category] ?? '✨', style: const TextStyle(fontSize: 20)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(category, overflow: TextOverflow.ellipsis),
                                  ),
                                  if (!['Food', 'Transport', 'Shopping', 'Bills', 'Other'].contains(category))
                                    IconButton(
                                      icon: const Icon(Icons.delete_forever_rounded, color: Colors.grey, size: 18),
                                      onPressed: () {
                                        _deleteCategory(category);
                                      },
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                          const PopupMenuItem(
                            value: 'add_new',
                            child: Row(
                              children: [
                                Icon(Icons.add, color: Colors.blueGrey),
                                SizedBox(width: 10),
                                Text('Add New Category', style: TextStyle(fontStyle: FontStyle.italic)),
                              ],
                            ),
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blueGrey),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (_selectedCategory != null)
                                Row(
                                  children: [
                                    Text(categoryEmojis[_selectedCategory] ?? '✨', style: const TextStyle(fontSize: 20)),
                                    const SizedBox(width: 10),
                                    Text(_selectedCategory!, style: const TextStyle(color: Colors.grey)),
                                  ],
                                )
                              else
                                const Text('Select Category', style: TextStyle(color: Colors.grey)),
                              const Icon(Icons.arrow_drop_down, color: Colors.blueGrey),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  readOnly: true, // Prevent manual input
                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.blueGrey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.blueGrey),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        icon: const Icon(Icons.calendar_today_sharp, color: Colors.blueGrey),
                        onPressed: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.light().copyWith(
                                  primaryColor: Colors.blueGrey, // Header color
                                  hintColor: Colors.blueGrey, // Selected date color
                                  colorScheme: const ColorScheme.light(primary: Colors.blueGrey), // Button color
                                  buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null && picked != _selectedDate) {
                            setState(() {
                              _selectedDate = picked;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  controller: TextEditingController(
                    text: DateFormat('d MMM').format(_selectedDate), // ✅ Directly format `_selectedDate`
                  ),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Colors.blueGrey,
                        )
                    ),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Colors.blueGrey,
                        )
                    ),
                    hintText: 'Description (Optional)',
                    hintStyle: const TextStyle(color: Colors.grey),
                  ),
                  cursorColor: Colors.black54,
                  maxLines: 2,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final userId = FirebaseAuth.instance.currentUser?.uid;
                      if (userId == null) return; // Ensure user is logged in

                      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);

                      final String expenseId = widget.isEditing
                          ? widget.expenseData!['id']
                          : DateTime.now().millisecondsSinceEpoch.toString(); // Generate ID if new

                      final newExpense = ExpenseModel(
                        id: expenseId,
                        userId: userId,
                        amount: double.parse(_amountController.text),
                        date: _selectedDate,
                        category: _selectedCategory ?? categories.first, // Ensure a valid category
                        emoji: categoryEmojis[_selectedCategory] ?? '✨', // Fetch emoji
                        note: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
                      );

                      try {
                        if (widget.isEditing) {
                          await expenseProvider.updateExpense(newExpense);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Expense updated successfully! ✅')),
                          );
                        } else {
                          await expenseProvider.addExpense(newExpense);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Expense added successfully! 🎉')),
                          );
                        }
                        Navigator.pop(context); // Close the screen after saving
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to save expense: $e ❌')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor:   const Color(0xFF305038,),),
                  child: Text(
                    widget.isEditing ? 'Save Changes' : 'Add Expense',
                    style: const TextStyle(color: Color(0xFFFFD700),),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: 80,
        child: BottomAppBar(
          color: const Color(0xFF305038,),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(onPressed: () {
                    Navigator.pushNamed(context, '/home');
                  }, icon: const Icon(Icons.home_sharp, color: Color(0xFFFFD700),)),
                  const SizedBox(width: 20,),
                  IconButton(onPressed: () {
                    Navigator.pushNamed(context, '/expenseList');
                  }, icon: const Icon(Icons.paid_sharp,color: Color(0xFFFFD700),)),
                  const SizedBox(width: 20,),
                  // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
                  FloatingActionButton(onPressed: (){
                    Navigator.pushNamed(context, '/addExpense');
                  },backgroundColor:  const Color(0xFFFFD700), child: const Icon(Icons.add, color: Colors.black,)),
                  const SizedBox(width: 20,),
                  IconButton(onPressed: () {
                    Navigator.pushNamed(context, '/getawayList');
                  }, icon: const Icon(Icons.tsunami_sharp,color: Color(0xFFFFD700),)),
                  const SizedBox(width: 20,),
                  IconButton(onPressed: () {
                    Navigator.pushNamed(context, '/profile');
                  }, icon: const Icon(Icons.person_rounded,color: Color(0xFFFFD700),)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
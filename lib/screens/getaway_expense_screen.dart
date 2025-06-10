import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/getaway_expense_model.dart';
import '../providers/currency_provider.dart';
import '../providers/getaway_expense_provider.dart';
import '../widgets/placeholder_ui.dart';

class GetawayExpenseScreen extends StatefulWidget {
  final String getawayId;

  const GetawayExpenseScreen({Key? key, required this.getawayId}) : super(key: key);

  @override
  _GetawayExpenseScreenState createState() => _GetawayExpenseScreenState();
}

class _GetawayExpenseScreenState extends State<GetawayExpenseScreen> {
  late Future<void> _fetchExpenses;

  @override
  void initState() {
    super.initState();
    _fetchExpenses = _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final expenseProvider = Provider.of<GetawayExpenseProvider>(context, listen: false);
    try {
      await expenseProvider.fetchExpenses(FirebaseAuth.instance.currentUser!.uid, widget.getawayId);
    } catch (e) {
      // Delay showing snackbar until after build completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.watch<CurrencyProvider>().currency;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Getaway Expenses'),
        backgroundColor: const Color(0xFF305038),
        foregroundColor: const Color(0xFFFFD700),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: _fetchExpenses,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading expenses'));
          } else {
            return Consumer<GetawayExpenseProvider>(
              builder: (context, expenseProvider, _) {
                // Filter expenses for this getaway only
                final filteredExpenses = expenseProvider.expenses
                    .where((e) => e.getawayId == widget.getawayId)
                    .toList()
                    ..sort((a, b) => a.dateAdded.compareTo(b.dateAdded)); // Ascending order

                if (filteredExpenses.isEmpty) {
                  return const EmptyPlaceholder(
                    message: 'No Expenses Yet!',
                    subtitle: 'Add expenses for your getaway',
                    icon: Icons.money_off,
                  );
                }

                return ListView.builder(
                  itemCount: filteredExpenses.length,
                  itemBuilder: (context, index) {
                    final expense = filteredExpenses[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                        color: Colors.white,
                        child: Dismissible(
                          key: Key(expense.id ?? UniqueKey().toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            color: Colors.red,
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) {
                            expenseProvider.deleteExpense(expense.id!, widget.getawayId, FirebaseAuth.instance.currentUser!.uid);
                          },
                          child: ListTile(
                            leading: Text(expense.emoji, style: const TextStyle(fontSize: 24, )),
                            title: Text(expense.description, style: const TextStyle()),
                            subtitle: Text(
                              'Amount: $currencySymbol${expense.amount} \nDate: ${DateFormat('dd MMM yyyy').format(expense.dateAdded.toDate())}',
                              style: const TextStyle(),
                            ),
                            onTap: () {
                              // Optional: navigate to detail screen
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => AddExpenseBottomSheet(getawayId: widget.getawayId),
          );
        },
        backgroundColor: const Color(0xFF305038),
        child: const Icon(Icons.add, color: Color(0xFFFFD700)),
      ),
    );
  }
}

class AddExpenseBottomSheet extends StatefulWidget {
  final String getawayId;

  const AddExpenseBottomSheet({Key? key, required this.getawayId}) : super(key: key);

  @override
  State<AddExpenseBottomSheet> createState() => _AddExpenseBottomSheetState();
}

class _AddExpenseBottomSheetState extends State<AddExpenseBottomSheet> {
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  Emoji _emoji = const Emoji('💰', 'category');

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showEmojiPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return EmojiPicker(
          onEmojiSelected: (Category? category, Emoji emoji) {
            setState(() {
              _emoji = emoji;
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<GetawayExpenseProvider>(context, listen: false);

    return Stack(
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.black.withOpacity(0.3),
          ),
        ),
        DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(16),
              child: ListView(
                controller: scrollController,
                children: [
                  const Center(
                    child: Text(
                      'Add Expense',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _categoryController,
                    decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.blueGrey)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.blueGrey)),
                      hintText: 'Category',
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    cursorColor: Colors.black54,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.blueGrey)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.blueGrey)),
                      hintText: 'Amount',
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    cursorColor: Colors.black54,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.blueGrey)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.blueGrey)),
                      hintText: 'Description',
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    cursorColor: Colors.black54,
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => _showEmojiPicker(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.blueGrey),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Pick Emoji',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          Text(
                            _emoji.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      final category = _categoryController.text.trim();
                      final amountText = _amountController.text.trim();
                      final description = _descriptionController.text.trim();

                      if (category.isEmpty || amountText.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill in all fields')),
                        );
                        return;
                      }

                      final amount = double.tryParse(amountText);
                      if (amount == null || amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid amount')),
                        );
                        return;
                      }

                      final expense = GetawayExpenseModel(
                        getawayId: widget.getawayId,
                        category: category,
                        emoji: _emoji.emoji,
                        amount: amount,
                        description: description,
                        dateAdded: Timestamp.now(),
                        userId: FirebaseAuth.instance.currentUser!.uid,
                      );

                      await expenseProvider.addExpense(expense);
                      if (mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF305038)),
                    child: const Text(
                      'Save Expense',
                      style: TextStyle(color: Color(0xFFFFD700)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
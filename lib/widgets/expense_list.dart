import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../screens/add_expense_screen.dart';

class ExpenseListView extends StatefulWidget {
  const ExpenseListView({super.key});

  @override
  State<ExpenseListView> createState() => _ExpenseListViewState();
}

class _ExpenseListViewState extends State<ExpenseListView> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    bool autofocusSearch = args?['autofocusSearch'] ?? false;

    return Column(
      children: [
        Hero(
          tag: 'search-hero',
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                autofocus: autofocusSearch,
                decoration: InputDecoration(
                  labelText: 'Search Expenses',
                  labelStyle: const TextStyle(color: Colors.black54),
                  prefixIcon: const Icon(Icons.search),
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
                ),
                cursorColor: Colors.black54,
                onChanged: (query) {
                  setState(() {
                    searchQuery = query.toLowerCase();
                  });
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Consumer<ExpenseProvider> (
            builder: (context, expenseProvider, child) {
              final filteredExpenses = expenseProvider.expenses.where((expense) {
                return expense.category.toLowerCase().contains(searchQuery) ||
                  expense.note?.toLowerCase().contains(searchQuery) == true;
              }).toList()
                ..sort((a, b) => b.date.compareTo(a.date)); // Sort by date (latest first);

              if(filteredExpenses.isEmpty) {
                return const Center(child: Text('No expenses found'));
              }

              return ListView.builder(
                itemCount: filteredExpenses.length,
                itemBuilder: (context, index) {
                  final expense = filteredExpenses[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Dismissible(
                      key: Key(expense.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
                        final deletedExpense = expense;
                        final deletedIndex = index; // restores the index of the deleted expenses

                        expenseProvider.deleteExpense(expense.id);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Expense deleted'),
                            action: SnackBarAction(
                              label: 'Undo',
                              textColor: Colors.white,
                              onPressed: () {
                                expenseProvider.insertExpense(deletedExpense, deletedIndex);
                              },
                            ),
                          ),
                        );
                      },
                      child: ExpenseTile (expense: filteredExpenses[index])
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class ExpenseTile extends StatelessWidget {
  final ExpenseModel expense;

  const ExpenseTile({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal:20),
        // color: Color(0xFF305038,),
        color: Colors.white,
        child: ListTile(
          leading: Text(expense.emoji),
          title: Text(
            expense.category,
            style: const TextStyle(fontWeight: FontWeight.bold, ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(expense.note ?? '', style: TextStyle( ),), // Note
              const SizedBox(height: 4), // Small space
              Text(
                DateFormat('MMM dd, yyyy').format(expense.date), // Format date
                style: TextStyle( fontSize: 12), // Lighter date style
              ),
            ],
          ),
          trailing: Text(expense.amount.toStringAsFixed(2),style: TextStyle(),),
          onTap: () {
            //handle tapping on expense (take to expense detail)
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddExpenseScreen(
                  isEditing: true,
                  expenseData: {
                    'id': expense.id,
                    'amount': expense.amount.toString(),
                    'category': expense.category,
                    'note': expense.note,
                    'date': expense.date,
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


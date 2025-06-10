import 'package:expense_tracker_app/widgets/expense_list.dart';
import 'package:expense_tracker_app/widgets/placeholder_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  void _fetchExpenses() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      Provider.of<ExpenseProvider>(context, listen: false).fetchExpenses(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Expenses'),
        backgroundColor:const Color(0xFF305038,),
        foregroundColor: const Color(0xFFFFD700),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top:20.0),
        child: Consumer<ExpenseProvider> (
          builder: (context, expenseProvider, child) {
            if (expenseProvider.expenses.isEmpty) {
              return const NoExpensesPlaceholder();
            }
            return const ExpenseListView();
          },
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

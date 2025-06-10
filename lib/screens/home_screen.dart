import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/homescreen_ui.dart';
import '../widgets/settings_drawer.dart';
import '../widgets/placeholder_ui.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool get hasExpenses => context.watch<ExpenseProvider>().expenses.isNotEmpty;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser; // Get logged-in user
      if (user != null) {
        final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
        expenseProvider.fetchExpenses(user.uid); // Pass user ID to fetch expenses
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF305038),
        foregroundColor: const Color(0xFFFFD700),
        leading: Builder(
          builder: (BuildContext context) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () { Scaffold.of(context).openDrawer(); },
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              ),
            );
          },
        ),
        actions: [
          Hero(
            tag: 'search-hero',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: IconButton(
                icon: const Icon(Icons.search_sharp,color: Color(0xFFFFD700),),
                onPressed: () {
                  // Navigator.pushNamed(context, '/expenseList');
                  Navigator.pushNamed(context, '/expenseList', arguments: {'autofocusSearch': true});
                },
                iconSize: 30,
                color: Colors.black,
              ),
            ),
          ),
        ],

      ),
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.75, // 75% of screen width
        child: const SettingsDrawer(),
      ),
      body: hasExpenses
          ? const SingleChildScrollView(
              child: HomeScreenUI(),
            )
          : const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: NoExpensesPlaceholder(),
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

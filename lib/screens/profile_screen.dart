import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? userId;
  bool isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (userId == null) {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null) {
        userId = currentUserId;
        Provider.of<UserProvider>(context, listen: false)
            .fetchUser(userId!)
            .then((_) {
          setState(() {
            isLoading = false;
          });
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget _buildLockedFeatureCard(String title, String subtitle) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.lock_outline, color: Colors.grey),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Text('Coming Soon', style: TextStyle(color: Colors.orange)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.black,)),
      );
    }

    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text("User not found or not logged in")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor:const Color(0xFF305038,),
        foregroundColor: const Color(0xFFFFD700),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info card
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Color(0xFF305038),
                      child: Text(
                        '💰',
                        style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name, style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 4),
                          Text(user.email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Coming soon features heading
            Text(
              'Features',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            // Locked cards
            _buildLockedFeatureCard('Saving Challenge', 'Track your savings goals'),
            _buildLockedFeatureCard('Getaway Mode Insights', 'Analyze your trip expenses'),
            _buildLockedFeatureCard('Budget Planner', 'Plan your monthly budget'),

            const SizedBox(height: 32),

            // About this app
            Text(
              'About This App',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• DimeFlow is Open Source!!',
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Built with Flutter & Firebase 🔥',
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Designed with clean simplicity in mind ;)',
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Developed by Nazarene — feedback welcome! 😇',
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Last updated: June 2025',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
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

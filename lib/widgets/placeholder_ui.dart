import 'package:flutter/material.dart';


class NoExpensesPlaceholder extends StatelessWidget {
  const NoExpensesPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.money_off, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'No expenses yet!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          SizedBox(height: 10),
          Text(
            'Start tracking your spending by adding your first expense.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16,color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class EmptyPlaceholder extends StatelessWidget {
  final String message;
  final String subtitle;
  final IconData icon;


  const EmptyPlaceholder({
    super.key,
    required this.message,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
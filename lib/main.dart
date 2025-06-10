import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart'; // Import the generated Firebase options
import 'providers/user_provider.dart'; // Import providers
import 'providers/expense_provider.dart';
import 'providers/category_provider.dart';
import 'providers/currency_provider.dart';
import 'providers/getaway_provider.dart';
import 'providers/getaway_expense_provider.dart';

import 'screens/home_screen.dart'; // Import your HomeScreen
import 'package:expense_tracker_app/screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'package:expense_tracker_app/screens/splash_screen.dart';
import '../screens/add_expense_screen.dart';
import '../screens/expense_list_screen.dart';
import '../screens/profile_screen.dart';
import 'package:expense_tracker_app/screens/insights_screen.dart';
import 'package:expense_tracker_app/screens/getaway_list_screen.dart';
import 'package:expense_tracker_app/screens/getaway_expense_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => ExpenseProvider()),
        ChangeNotifierProvider(create: (context) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()..loadCurrency()),
        ChangeNotifierProvider(create: (context) => GetawayProvider()),
        ChangeNotifierProvider(create: (context) => GetawayExpenseProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(), // Splash screen first
          '/home': (context) => const HomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/addExpense':(context) => const AddExpenseScreen(),
          '/expenseList':(context) => const ExpenseListScreen(),
          '/insights':(context) => const InsightsScreen(),
          '/profile':(context) => const ProfileScreen(),
          '/getawayList': (context) => const GetawayListScreen(),
          '/getawayExpenses': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return GetawayExpenseScreen(getawayId: args['getawayId']);
          }
        },
        theme: ThemeData.light(), // Change based on your theme preference
      ),
    );
  }
}



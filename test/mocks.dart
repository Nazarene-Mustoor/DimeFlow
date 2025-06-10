import 'package:expense_tracker_app/providers/currency_provider.dart';
import 'package:expense_tracker_app/providers/expense_provider.dart';
import 'package:expense_tracker_app/providers/getaway_expense_provider.dart';
import 'package:expense_tracker_app/providers/getaway_provider.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';

@GenerateMocks([
  User,
  FirebaseAuth,
  ExpenseProvider,
  CurrencyProvider,
  GetawayProvider,
  GetawayExpenseProvider,
])
void main() {}
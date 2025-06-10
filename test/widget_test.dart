// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
//
// import 'package:expense_tracker_app/main.dart';
//
// void main() {
//   testWidgets('Counter increments smoke test', (WidgetTester tester) async {
//     // Build our app and trigger a frame.
//     await tester.pumpWidget(const MyApp());
//
//     // Verify that our counter starts at 0.
//     expect(find.text('0'), findsOneWidget);
//     expect(find.text('1'), findsNothing);
//
//     // Tap the '+' icon and trigger a frame.
//     await tester.tap(find.byIcon(Icons.add));
//     await tester.pump();
//
//     // Verify that our counter has incremented.
//     expect(find.text('0'), findsNothing);
//     expect(find.text('1'), findsOneWidget);
//   });
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_app/models/expense_model.dart';
import 'package:expense_tracker_app/models/getaway_expense_model.dart';
import 'package:expense_tracker_app/models/getaway_model.dart';
import 'package:expense_tracker_app/providers/getaway_expense_provider.dart';
import 'package:expense_tracker_app/providers/getaway_provider.dart';
import 'package:expense_tracker_app/screens/expense_list_screen.dart';
import 'package:expense_tracker_app/screens/getaway_expense_screen.dart';
import 'package:expense_tracker_app/screens/getaway_list_screen.dart';
import 'package:expense_tracker_app/screens/insights_screen.dart';
import 'package:expense_tracker_app/screens/login_screen.dart';
import 'package:expense_tracker_app/screens/register_screen.dart';
import 'package:expense_tracker_app/widgets/placeholder_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mockito/mockito.dart';
import 'mocks.mocks.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:expense_tracker_app/screens/home_screen.dart';
import 'package:expense_tracker_app/screens/add_expense_screen.dart';
import 'package:expense_tracker_app/providers/expense_provider.dart';
import 'package:expense_tracker_app/providers/currency_provider.dart';

// Your FakeUserCredential class for mocking UserCredential
class FakeUserCredential implements UserCredential {
  @override
  final User? user;

  FakeUserCredential(this.user);

  @override
  // You can leave unimplemented properties throwing errors if unused
  // Or add dummy implementations if your tests need them
  AdditionalUserInfo? get additionalUserInfo => null;
  @override
  AuthCredential? get credential => null;
// add others if your app needs them
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockExpenseProvider mockExpenseProvider;
  late MockCurrencyProvider mockCurrencyProvider;
  late MockGetawayProvider mockGetawayProvider;
  late MockGetawayExpenseProvider mockGetawayExpenseProvider;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockUser;

  setUp(() {
    mockExpenseProvider = MockExpenseProvider();
    mockCurrencyProvider = MockCurrencyProvider();
    mockGetawayProvider = MockGetawayProvider();
    mockGetawayExpenseProvider = MockGetawayExpenseProvider();
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();

    // Stub behaviors as needed
    when(mockCurrencyProvider.currency).thenReturn('₹');
    when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('test_uid');
    when(mockGetawayProvider.fetchGetaways()).thenAnswer((_) async => true);
  });

  group('HomeScreen', () {
    testWidgets('HomeScreen loads and displays UI elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ExpenseProvider>.value(value: mockExpenseProvider),
            ChangeNotifierProvider<CurrencyProvider>.value(value: mockCurrencyProvider),
            ChangeNotifierProvider<GetawayExpenseProvider>.value(value: mockGetawayExpenseProvider),
            // If you use FirebaseAuth via Provider, you can add here:
            // Provider<FirebaseAuth>.value(value: mockFirebaseAuth),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for essential UI elements
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.byIcon(Icons.search_sharp), findsOneWidget);
      expect(find.byType(BottomAppBar), findsOneWidget);
      expect(find.text('Weekly Trend'), findsOneWidget);
      expect(find.text('Monthly Trend'), findsOneWidget);
      expect(find.text('Recent Expenses'), findsOneWidget);
      expect(find.text('view insights >>'), findsOneWidget);
    });
  });

  group('AddExpenseScreen', () {
    Widget createAddExpenseScreen({bool isEditing = false, Map<String, dynamic>? data}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ExpenseProvider>.value(value: mockExpenseProvider),
          ChangeNotifierProvider<CurrencyProvider>.value(value: mockCurrencyProvider),
        ],
        child: MaterialApp(
          home: AddExpenseScreen(
            isEditing: isEditing,
            expenseData: data,
          ),
        ),
      );
    }

    testWidgets('renders AddExpenseScreen form', (tester) async {
      await tester.pumpWidget(createAddExpenseScreen());

      expect(find.text('Add Expense'), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.byIcon(Icons.calendar_month), findsOneWidget);
    });

    testWidgets('calls addExpense when form is filled and submitted', (tester) async {
      when(mockExpenseProvider.addExpense(any)).thenAnswer((_) async => {});

      await tester.pumpWidget(createAddExpenseScreen());

      await tester.enterText(find.byType(TextFormField).first, '100'); // Amount
      await tester.tap(find.text('Add Expense')); // Submit button
      await tester.pumpAndSettle();

      verify(mockExpenseProvider.addExpense(any)).called(1);
    });

    testWidgets('shows validation error if amount is missing', (tester) async {
      await tester.pumpWidget(createAddExpenseScreen());

      await tester.tap(find.text('Add Expense'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter amount'), findsOneWidget); // Customize based on your validator
    });

    testWidgets('pre-fills fields in editing mode', (tester) async {
      Map<String, dynamic> mockData = {
        'amount': 250,
        'description': 'Lunch',
        'category': 'Food',
        'date': DateTime.now(),
        // include any fields you use
      };

      await tester.pumpWidget(createAddExpenseScreen(isEditing: true, data: mockData));
      await tester.pumpAndSettle();

      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('250'), findsOneWidget);
      // add more expectations if needed
    });

    testWidgets('taps dropdown and selects category (if exists)', (tester) async {
      await tester.pumpWidget(createAddExpenseScreen());

      final categoryDropdown = find.byKey(const Key('category_dropdown')); // Add this key in your widget
      if (categoryDropdown.evaluate().isNotEmpty) {
        await tester.tap(categoryDropdown);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Food').last);
        await tester.pumpAndSettle();

        expect(find.text('Food'), findsOneWidget);
      }
    });
  });

  group('ExpenseListScreen', () {
    Widget createScreenWithExpenses(List<ExpenseModel> expenses) {
      when(mockExpenseProvider.expenses).thenReturn(expenses);
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ExpenseProvider>.value(value: mockExpenseProvider),
          ChangeNotifierProvider<CurrencyProvider>.value(value: mockCurrencyProvider),
        ],
        child: const MaterialApp(
          home: ExpenseListScreen(),
        ),
      );
    }

    testWidgets('displays AppBar and bottom bar', (tester) async {
      when(mockExpenseProvider.expenses).thenReturn([]);

      await tester.pumpWidget(createScreenWithExpenses([]));
      await tester.pumpAndSettle();

      expect(find.text('Expenses'), findsOneWidget);
      expect(find.byType(BottomAppBar), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows placeholder when no expenses', (tester) async {
      when(mockExpenseProvider.expenses).thenReturn([]);

      await tester.pumpWidget(createScreenWithExpenses([]));
      await tester.pumpAndSettle();

      expect(find.byType(NoExpensesPlaceholder), findsOneWidget);
    });

    testWidgets('shows filtered expenses list', (tester) async {
      final mockExpense = ExpenseModel(
        id: '1',
        userId: 'test_uid',
        amount: 100,
        category: 'Food',
        emoji: '🍔',
        date: DateTime.now(),
        note: 'Burger',
      );

      await tester.pumpWidget(createScreenWithExpenses([mockExpense]));
      await tester.pumpAndSettle();

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Burger'), findsOneWidget);
      expect(find.text('100.00'), findsOneWidget);
    });

    testWidgets('tapping an expense opens edit screen', (tester) async {
      final mockExpense = ExpenseModel(
        id: '1',
        userId: 'test_uid',
        amount: 200,
        category: 'Travel',
        emoji: '✈️',
        date: DateTime.now(),
        note: 'Flight',
      );

      await tester.pumpWidget(createScreenWithExpenses([mockExpense]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Travel'));
      await tester.pumpAndSettle();

      expect(find.byType(AddExpenseScreen), findsOneWidget);
      expect(find.text('Add Expense'), findsOneWidget); // If shown in AppBar
    });

    testWidgets('deletes expense and shows SnackBar with undo', (tester) async {
      final mockExpense = ExpenseModel(
        id: '1',
        userId: 'test_uid',
        amount: 50,
        category: 'Snacks',
        emoji: '🍪',
        date: DateTime.now(),
        note: 'Cookies',
      );

      when(mockExpenseProvider.expenses).thenReturn([mockExpense]);

      await tester.pumpWidget(createScreenWithExpenses([mockExpense]));
      await tester.pumpAndSettle();

      final dismissible = find.byType(Dismissible).first;
      await tester.drag(dismissible, const Offset(-500, 0));
      await tester.pumpAndSettle();

      verify(mockExpenseProvider.deleteExpense('1')).called(1);
      expect(find.text('Expense deleted'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
    });
  });

 group('GetawayListScreen', () {
   testWidgets('GetawayListScreen renders without errors', (WidgetTester tester) async {
     await tester.pumpWidget(
       MultiProvider(
         providers: [
           ChangeNotifierProvider<GetawayProvider>.value(value: mockGetawayProvider),
           // add other providers if needed
         ],
         child: MaterialApp(
           home: GetawayListScreen(),
         ),
       ),
     );

     expect(find.text('Getaways'), findsOneWidget); // assuming you have a title
     expect(find.byType(FloatingActionButton), findsOneWidget); // add getaway button
   });

   testWidgets('Displays list of getaways', (WidgetTester tester) async {
     when(mockGetawayProvider.getaways).thenReturn([
       Getaway(
         id: '1',
         name: 'Beach Trip',
         location: 'Bali',
         type: 'weekend getaway',
         startDate: DateTime(2023, 12, 20),
         endDate: DateTime(2023, 12, 25),
       ),
       Getaway(
         id: '2',
         name: 'Taylor Swift',
         location: 'Paris',
         type: 'concert',
         startDate: DateTime(2024, 1, 10),
         endDate: DateTime(2024, 1, 15),
       ),
     ]);

     await tester.pumpWidget(
       MultiProvider(
         providers: [
           ChangeNotifierProvider<GetawayProvider>.value(value: mockGetawayProvider),
         ],
         child: MaterialApp(
           home: GetawayListScreen(),
         ),
       ),
     );

     await tester.pumpAndSettle();

     expect(find.text('Beach Trip'), findsOneWidget);
     expect(find.text('Taylor Swift'), findsOneWidget);
   });
 });

  group('GetawayExpenseScreen', () {
    testWidgets('GetawayExpenseScreen renders without errors', (WidgetTester tester) async {
      when(mockGetawayExpenseProvider.expenses).thenReturn([]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<GetawayExpenseProvider>.value(value: mockGetawayExpenseProvider),
            ChangeNotifierProvider<CurrencyProvider>.value(value: mockCurrencyProvider),
          ],
          child: MaterialApp(
            home: GetawayExpenseScreen(getawayId: 'test_getaway_id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Getaway Expenses'), findsOneWidget); // AppBar title
      expect(find.byType(FloatingActionButton), findsOneWidget); // Add expense button
      expect(find.text('No Expenses Yet!'), findsOneWidget); // Empty placeholder shown for empty list
    });

    testWidgets('Displays list of expenses', (WidgetTester tester) async {
      when(mockGetawayExpenseProvider.expenses).thenReturn([
        GetawayExpenseModel(
          id: 'e1',
          getawayId: 'test_getaway_id',
          category: 'Food',
          emoji: '🍔',
          amount: 500,
          description: 'Lunch',
          dateAdded: Timestamp.fromDate(DateTime(2024, 5, 1)),
          userId: 'test_uid',
        ),
        GetawayExpenseModel(
          id: 'e2',
          getawayId: 'test_getaway_id',
          category: 'Transport',
          emoji: '🚌',
          amount: 150,
          description: 'Bus fare',
          dateAdded: Timestamp.fromDate(DateTime(2024, 5, 2)),
          userId: 'test_uid',
        ),
      ]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<GetawayExpenseProvider>.value(value: mockGetawayExpenseProvider),
            ChangeNotifierProvider<CurrencyProvider>.value(value: mockCurrencyProvider),
          ],
          child: MaterialApp(
            home: GetawayExpenseScreen(getawayId: 'test_getaway_id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('🍔'), findsOneWidget);
      expect(find.text('🚌'), findsOneWidget);
      expect(find.textContaining('₹500'), findsOneWidget);
      expect(find.textContaining('₹150'), findsOneWidget);
    });

    testWidgets('Dismissible deletes expense on swipe', (WidgetTester tester) async {
      final expenses = [
        GetawayExpenseModel(
          id: 'e1',
          getawayId: 'test_getaway_id',
          category: 'Food',
          emoji: '🍔',
          amount: 500,
          description: 'Lunch',
          dateAdded: Timestamp.fromDate(DateTime(2024, 5, 1)),
          userId: 'test_uid',
        ),
      ];

      when(mockGetawayExpenseProvider.expenses).thenReturn(expenses);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<GetawayExpenseProvider>.value(value: mockGetawayExpenseProvider),
            ChangeNotifierProvider<CurrencyProvider>.value(value: mockCurrencyProvider),
          ],
          child: MaterialApp(
            home: GetawayExpenseScreen(getawayId: 'test_getaway_id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Food'), findsOneWidget);

      final dismissible = find.byType(Dismissible);
      expect(dismissible, findsOneWidget);

      await tester.drag(dismissible, const Offset(-500, 0)); // swipe left to delete
      await tester.pumpAndSettle();

      verify(mockGetawayExpenseProvider.deleteExpense('e1', 'test_getaway_id', 'test_uid')).called(1);
    });

    testWidgets('Tapping FloatingActionButton shows AddExpenseBottomSheet', (WidgetTester tester) async {
      when(mockGetawayExpenseProvider.expenses).thenReturn([]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<GetawayExpenseProvider>.value(value: mockGetawayExpenseProvider),
            ChangeNotifierProvider<CurrencyProvider>.value(value: mockCurrencyProvider),
          ],
          child: MaterialApp(
            home: GetawayExpenseScreen(getawayId: 'test_getaway_id'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Add Expense'), findsOneWidget);
    });
  });

  group('InsightsScreen', () {
    Widget createInsightsScreen() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ExpenseProvider>.value(value: mockExpenseProvider),
          ChangeNotifierProvider<CurrencyProvider>.value(value: mockCurrencyProvider),
        ],
        child: const MaterialApp(
          home: InsightsScreen(),
        ),
      );
    }

    testWidgets('renders InsightsScreen with tabs and titles', (tester) async {
      await tester.pumpWidget(createInsightsScreen());
      await tester.pumpAndSettle();

      expect(find.text('Insights'), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('view insights >>'), findsNothing); // Shouldn't exist here
    });

    testWidgets('displays message when no data is available', (tester) async {
      // Mock expenses to be empty, so no data for any month
      when(mockExpenseProvider.expenses).thenReturn([]);

      await tester.pumpWidget(createInsightsScreen());
      await tester.pumpAndSettle();

      expect(find.textContaining('No data'), findsOneWidget); // or findsWidgets depending on your UI
    });

    testWidgets('displays quick stats and chart for a month', (tester) async {
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month);

      when(mockExpenseProvider.getCategoryTotalsForMonth(thisMonth)).thenReturn({
        'Food': 200,
        'Travel': 300,
      });

      // If your UI uses a separate method for total, mock it as well
      when(mockExpenseProvider.getTotalForMonth(thisMonth)).thenReturn(500);

      await tester.pumpWidget(createInsightsScreen());
      await tester.pumpAndSettle();

      expect(find.text('₹500'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Travel'), findsOneWidget);
    });

    testWidgets('navigates tabs and updates data per month', (tester) async {
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month);
      DateTime previousMonth(DateTime date) {
        final year = date.month == 1 ? date.year - 1 : date.year;
        final month = date.month == 1 ? 12 : date.month - 1;
        return DateTime(year, month);
      }
      final lastMonth = previousMonth(now);

      when(mockExpenseProvider.getCategoryTotalsForMonth(thisMonth)).thenReturn({
        'Shopping': 400,
        'Bills': 200,
      });
      when(mockExpenseProvider.getTotalForMonth(thisMonth)).thenReturn(600);

      when(mockExpenseProvider.getCategoryTotalsForMonth(lastMonth)).thenReturn({
        'Food': 300,
      });
      when(mockExpenseProvider.getTotalForMonth(lastMonth)).thenReturn(300);

      when(mockExpenseProvider.getMonthlyComparison(thisMonth)).thenReturn({
        'current': 600,
        'previous': 450,
        'percent': 33.33,
        'comment': 'Increase from last month',
      });

      // If you also need comparison for lastMonth, mock it here:
      when(mockExpenseProvider.getMonthlyComparison(lastMonth)).thenReturn({
        'current': 300,
        'previous': 500,
        'percent': -40.0,
        'comment': 'Decrease from previous month',
      });

      await tester.pumpWidget(createInsightsScreen());
      await tester.pumpAndSettle();

      // Current month data
      expect(find.text('₹600'), findsOneWidget);
      expect(find.text('Shopping'), findsOneWidget);

      // Swipe to previous tab (left swipe)
      await tester.drag(find.byType(TabBarView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.text('₹300'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
    });
  });

  group('Login Screen', () {
    Widget createLoginScreen() {
      return Provider<FirebaseAuth>.value(
        value: mockFirebaseAuth,
        child: MaterialApp(
          home: LoginScreen(),
        ),
      );
    }

    testWidgets('renders email, password fields and login button', (tester) async {
      await tester.pumpWidget(createLoginScreen());

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('shows validation errors if fields are empty', (tester) async {
      await tester.pumpWidget(createLoginScreen());

      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter email'), findsOneWidget);
      expect(find.text('Please enter password'), findsOneWidget);
    });

    testWidgets('calls signInWithEmailAndPassword with correct credentials', (tester) async {
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => FakeUserCredential(mockUser));

      await tester.pumpWidget(createLoginScreen());

      await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');

      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      verify(mockFirebaseAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      )).called(1);
    });

    testWidgets('shows error message on sign-in failure', (tester) async {
      when(mockFirebaseAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(FirebaseAuthException(code: 'user-not-found'));

      await tester.pumpWidget(createLoginScreen());

      await tester.enterText(find.byType(TextFormField).at(0), 'wrong@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'wrongpassword');

      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(find.textContaining('user-not-found'), findsOneWidget);
    });
  });

  group('RegisterScreen', () {
    Widget createRegisterScreen() {
      return Provider<FirebaseAuth>.value(
        value: mockFirebaseAuth,
        child: MaterialApp(
          home: RegisterScreen(),
        ),
      );
    }

    testWidgets('renders email, password, confirm password fields and register button', (tester) async {
      await tester.pumpWidget(createRegisterScreen());

      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets('shows validation errors if fields are empty or passwords mismatch', (tester) async {
      await tester.pumpWidget(createRegisterScreen());

      // Tap register without entering any data
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter email'), findsOneWidget);
      expect(find.text('Please enter password'), findsOneWidget);

      // Enter password and mismatched confirm password
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.enterText(find.byType(TextFormField).at(2), 'password321');

      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('calls createUserWithEmailAndPassword with correct data', (tester) async {
      when(mockFirebaseAuth.createUserWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => FakeUserCredential(mockUser));

      await tester.pumpWidget(createRegisterScreen());

      await tester.enterText(find.byType(TextFormField).at(0), 'newuser@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');

      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      verify(mockFirebaseAuth.createUserWithEmailAndPassword(
        email: 'newuser@example.com',
        password: 'password123',
      )).called(1);
    });

    testWidgets('shows error message on registration failure', (tester) async {
      when(mockFirebaseAuth.createUserWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      await tester.pumpWidget(createRegisterScreen());

      await tester.enterText(find.byType(TextFormField).at(0), 'existing@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');

      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      expect(find.textContaining('email-already-in-use'), findsOneWidget);
    });
  });
}

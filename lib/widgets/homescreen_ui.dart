import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import '../providers/expense_provider.dart';
import '../models/expense_model.dart';
import 'package:fl_chart/fl_chart.dart';

import '../screens/expense_list_screen.dart';

class HomeScreenUI extends StatefulWidget {
  const HomeScreenUI({super.key});

  @override
  State<HomeScreenUI> createState() => _HomeScreenUIState();
}

class _HomeScreenUIState extends State<HomeScreenUI> {
  int _selectedIndex = 0; // 0 for weekly, 1 for monthly
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final symbol = context.watch<CurrencyProvider>().currency;
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final expenses = expenseProvider.expenses;
    // Sort expenses by date in descending order (latest first)
    final sortedExpenses = expenses
        .toList() // Convert to list if it's not already a list
      ..sort((a, b) => b.date.compareTo(a.date)); // Sort by date (latest first)

    // Take the top 3 latest expenses
    final recentExpenses = sortedExpenses.take(3).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),

        // Weekly / Monthly Chart Toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ToggleButtons(
            isSelected: [_selectedIndex == 0, _selectedIndex == 1],
            onPressed: (int index) {
              setState(() {
                _selectedIndex = index;
              });
              _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            },
            borderRadius: BorderRadius.circular(8),
            selectedColor: const Color(0xFFFFD700),
            fillColor: const Color(0xFF305038,),
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Weekly Trend'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Monthly Trend'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Chart Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            _selectedIndex == 0 ? 'Spending This Week' : 'Monthly Spending',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),

        const SizedBox(height: 8),

        // Chart View
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            height: 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 2),
              ],
            ),
            child: Consumer<ExpenseProvider>(
              builder: (context, expenseProvider, child) {
                final lineData = expenseProvider.getWeeklyTrendData();
                final barData = expenseProvider.getMonthlyTrendData();

                double getAdaptiveMaxY(List<FlSpot> data) {
                  final maxY = data.map((e) => e.y).fold<double>(0.0, (a, b) => a > b ? a : b);
                  return maxY < 100.0 ? 100.0 : maxY * 1.2;
                }

                return PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  children: [
                    // WEEKLY LINE CHART
                    LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: getAdaptiveMaxY(lineData) * 1.10,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: getAdaptiveMaxY(lineData) / 4,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.grey.shade300,
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                return value.toInt() >= 0 && value.toInt() < days.length
                                    ? Text(days[value.toInt()], style: const TextStyle(fontSize: 12))
                                    : const SizedBox.shrink();
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              interval: getAdaptiveMaxY(lineData) / 4,
                              getTitlesWidget: (value, meta) => Text('$symbol${value.toInt()}',
                                  style: const TextStyle(fontSize: 10)),
                            ),
                          ),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: const Border(
                            bottom: BorderSide(color: Colors.black12),
                            left: BorderSide(color: Colors.black12),
                          ),
                        ),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (spots) => const Color(0xFF305038),
                            getTooltipItems: (spots) => spots
                                .map((spot) => LineTooltipItem(
                                '$symbol${spot.y.toStringAsFixed(0)}',
                                const TextStyle(
                                    color: Color(0xFFFFD700), fontWeight: FontWeight.bold)))
                                .toList(),
                          ),
                          handleBuiltInTouches: true,
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: lineData,
                            isCurved: true,
                            color: const Color(0xFF305038,),
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: const Color(0xFF305038,).withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // MONTHLY BAR CHART
                    BarChart(
                      BarChartData(
                        maxY: getAdaptiveMaxY(barData)*1.15,
                        minY: 0,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipPadding: const EdgeInsets.all(8),
                            tooltipMargin: 8,
                            getTooltipColor: (group) => const Color(0xFF305038,),
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final day = group.x.toInt();
                              final value = rod.toY.toStringAsFixed(2);
                              return BarTooltipItem(
                                'Day $day $symbol$value',
                                const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.w500, fontSize: 12),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() % 5 == 0) {
                                  return Text('${value.toInt()}',
                                      style: const TextStyle(fontSize: 10));
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              interval: getAdaptiveMaxY(barData) / 4,
                              getTitlesWidget: (value, meta) =>
                                  Text('$symbol${value.toInt()}', style: const TextStyle(fontSize: 10)),
                            ),
                          ),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: getAdaptiveMaxY(barData) / 4,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.grey.shade300,
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: const Border(
                            bottom: BorderSide(color: Colors.black12),
                            left: BorderSide(color: Colors.black12),
                          ),
                        ),
                        barGroups: barData
                            .map((spot) => BarChartGroupData(x: spot.x.toInt(), barRods: [
                          BarChartRodData(
                            toY: spot.y,
                            width: 12,
                            color: const Color(0xFF305038,),
                            borderRadius: BorderRadius.circular(4),
                          )
                        ]))
                            .toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        // View Insights Button
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/insights');
            },
            child: const Text('view insights >>', style: TextStyle(color: Colors.black)),
          ),
        ),

        const SizedBox(height: 10),

        // Recent Expenses Section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 2)],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Expenses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => const ExpenseListScreen(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            const begin = Offset(1.0, 0.0); // start from right
                            const end = Offset.zero;         // slide to original position
                            const curve = Curves.ease;

                            final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                            final offsetAnimation = animation.drive(tween);

                            return SlideTransition(
                              position: offsetAnimation,
                              child: child,
                            );
                          },
                        ),
                      );
                    },
                    child: const Text('view all >>', style: TextStyle(color: Colors.black)),
                  ),

                ],
              ),
              const Divider(),
              recentExpenses.isEmpty
                  ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No recent expenses yet. Add some!'),
                  )
                  : Column(
                children: recentExpenses.map((expense) => _buildExpenseItem(expense, symbol)).toList(),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseItem(ExpenseModel expense,  String symbol) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(expense.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(expense.category, style: const TextStyle(fontSize: 16)),
          ),
          Text(
            '$symbol${expense.amount.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

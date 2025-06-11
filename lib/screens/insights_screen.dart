import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import '../providers/expense_provider.dart';
import '../models/expense_model.dart';
import 'package:fl_chart/fl_chart.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  @override
  Widget build(BuildContext context) {

    DateTime getMonthOffset(DateTime base, int offset) {
      // offset can be negative or positive
      int year = base.year;
      int month = base.month + offset;

      // Adjust year and month correctly
      while (month < 1) {
        month += 12;
        year -= 1;
      }
      while (month > 12) {
        month -= 12;
        year += 1;
      }

      return DateTime(year, month);
    }

    return DefaultTabController(
      length: 6,
      initialIndex: 5,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Insights"),
          backgroundColor:const Color(0xFF305038,),
          foregroundColor: const Color(0xFFFFD700),
          centerTitle: true,
          bottom: TabBar(
            dividerColor: Colors.blueGrey,
            indicatorColor: Colors.blueGrey,
            unselectedLabelColor: const Color(0xFFFFD700),
            labelColor: const Color(0xFFFFD700),
            isScrollable: true,
            tabs: List.generate(6, (index) {
              final now = DateTime.now();
              final month = getMonthOffset(now, index - 5);
              final label = DateFormat.MMM().format(month); // Jan, Feb, etc.
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Tab(
                child: Text(
                label,
                style: const TextStyle(fontSize: 16), // increase font size here
              ),
              ),
              );
            }),
          ),
        ),
        body: TabBarView(
          children: List.generate(6, (index) {
            final now = DateTime.now();
            final selectedMonth = DateTime(now.year, now.month - (5 - index));
            return InsightsTabContent(month: selectedMonth);
          }),
        ),
      ),
    );
  }
}

class InsightsTabContent extends StatefulWidget {
  final DateTime month;

  const InsightsTabContent({super.key, required this.month});

  @override
  State<InsightsTabContent> createState() => _InsightsTabContentState();
}

class _InsightsTabContentState extends State<InsightsTabContent> {
  String? selectedCategory;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final monthExpenses = provider.expenses.where((e) =>
    e.date.month == widget.month.month && e.date.year == widget.month.year).toList();

    final categoryTotals = provider.getCategoryTotalsForMonth(widget.month);
    final comparison = provider.getMonthlyComparison(widget.month);
    final filteredByCategory = selectedCategory == null
        ? []
        : provider.getExpensesForCategoryAndMonth(selectedCategory!, widget.month);

    final symbol = context.watch<CurrencyProvider>().currency; // Use the symbol here


    if (monthExpenses.isEmpty) {
      return const Center(
        child: Text("No expenses in this month 🫠",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
      
          // 🔢 Quick stats (reused logic like you planned)
          _buildQuickStats(monthExpenses, symbol),

          const SizedBox(height: 15),

          _buildCategorySpikes(context, monthExpenses, widget.month, symbol),

          const SizedBox(height: 20),
      
          // 📊 Horizontal bar chart
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text("Spend by Category", style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 8),
          _buildBarChart(categoryTotals, symbol),
          _buildPieChart(categoryTotals),
          const SizedBox(height: 10),

          // 📂 Clicked category: List expenses
          if (selectedCategory != null && filteredByCategory.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text("Expenses in $selectedCategory",
                  style: Theme.of(context).textTheme.titleSmall),
            ),
            ...filteredByCategory.map((e) => ListTile(
              title: Text(e.emoji),
              subtitle: Text('${e.category} • ${DateFormat('MMM dd, yyyy').format(e.date.toLocal())}'),
              trailing: Text("$symbol${e.amount.toStringAsFixed(2)}"),
            )),
          ],

          const SizedBox(height: 10),
      
          // 📈 Monthly comparison
          _buildMonthlyComparison(comparison,symbol),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildQuickStats(List<ExpenseModel> expenses, String symbol) {
    double total = expenses.fold(0.0, (sum, e) => sum + e.amount);
    double avg = expenses.isNotEmpty ? total / expenses.length : 0;

    String formatLastExpenseDate(DateTime? lastDate) {
      if (lastDate == null) return 'No Expenses';

      final now = DateTime.now();
      final difference = now.difference(lastDate).inDays;

      if (difference == 0) return 'Today';
      if (difference == 1) return 'Yesterday';
      if (difference < 7) return '$difference days ago';
      if (difference < 30) return '${(difference / 7).floor()} week${(difference / 7).floor() == 1 ? '' : 's'} ago';
      if (difference < 365) return '${(difference / 30).floor()} month${(difference / 30).floor() == 1 ? '' : 's'} ago';

      return 'Over a year ago';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SizedBox(
        width: double.infinity,
        child: Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Quick Stats", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),

                const Row(
                  children: [
                    Icon(Icons.payments, size: 20),
                    SizedBox(width: 10),
                    Text("Total Spent", style: TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "$symbol${total.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                const Row(
                  children: [
                    Icon(Icons.show_chart, size: 20),
                    SizedBox(width: 10),
                    Text("Avg per Transaction", style: TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "$symbol${avg.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                const Row(
                  children: [
                    Icon(Icons.history, size: 20),
                    SizedBox(width: 10),
                    Text("Last Expense", style: TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  expenses.isNotEmpty
                      ? formatLastExpenseDate(expenses.last.date)
                      : 'No Expenses',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySpikes(BuildContext context, List<ExpenseModel> expenses, DateTime currentMonth, String symbol) {
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final spikes = expenseProvider.getCategorySpikes(currentMonth);

    if (spikes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SizedBox(
        width: double.infinity,
        child: Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Spending Spikes (last 3 months)",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),

                ...spikes.entries.map((entry) {
                  final diff = entry.value;
                  final isIncrease = diff >= 0;
                  final color = isIncrease ? Colors.red : Colors.green;
                  final emoji = isIncrease ? '🔺' : '🔻';
                  final label = isIncrease ? 'above' : 'below';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          isIncrease ? Icons.trending_up : Icons.trending_down,
                          size: 20,
                          color: color,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${entry.key}: $symbol${diff.abs().toStringAsFixed(0)} $label usual',
                          style: TextStyle(
                            fontSize: 16,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<String, double> categoryTotals, String symbol) {
    if (categoryTotals.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text("No data to display."),
      );
    }

    final barData = categoryTotals.entries.toList();
    final max = barData.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(barData.length, (index) {
          final label = barData[index].key;
          final value = barData[index].value;
          final percent = (value / max) * 100;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = label;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(width: 80, child: Text(label)),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: percent / 100,
                          child: Container(
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFF305038),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text("$symbol${value.toStringAsFixed(0)}"),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  int? touchedIndex;

  Widget _buildPieChart(Map<String, double> categoryTotals) {
    final colors = [
      const Color(0xFF556B2F), // Olive Green
      const Color(0xFFA8BBA2), // Sage
      const Color(0xFFFFBF00), // Amber
      const Color(0xFFE67300), // Burnt Orange
      const Color(0xFFB7410E), // Rust
      const Color(0xFF5D4037), // Deep Brown
      const Color(0xFFFFF5CC), // Soft Cream
      const Color(0xFF008080), // Teal
      const Color(0xFF6A5ACD), // Slate Blue
      const Color(0xFFC8A2C8), // Soft Lilac
      const Color(0xFFDCAE96), // Dusty Rose
      const Color(0xFF36454F), // Charcoal
      const Color(0xFFFFA07A), // Light Salmon
      const Color(0xFF708090), // Slate Gray
    ];

    final total = categoryTotals.values.fold(0.0, (a, b) => a + b);
    final entries = categoryTotals.entries.toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AspectRatio(
        aspectRatio: 1.3,
        child: PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 40,
            pieTouchData: PieTouchData(
              touchCallback: (event, response) {
                if (response != null &&
                    response.touchedSection != null &&
                    event is! FlLongPressEnd &&
                    event is! FlPanEndEvent &&
                    response.touchedSection!.touchedSectionIndex != -1) {
                  final index = response.touchedSection!.touchedSectionIndex;
                  setState(() {
                    touchedIndex = index;
                    selectedCategory = entries[index].key;
                  });
                } else {
                  setState(() {
                    touchedIndex = null;
                    selectedCategory = null;
                  });
                }
              },
            ),
            sections: List.generate(entries.length, (index) {
              final entry = entries[index];
              final isTouched = index == touchedIndex;
              final percent = total == 0 ? 0.0 : (entry.value / total) * 100;

              return PieChartSectionData(
                color: colors[index % colors.length],
                value: entry.value,
                title: "${percent.toStringAsFixed(1)}% ",
                radius: isTouched ? 70 : 60,
                titleStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyComparison(Map<String, dynamic> data, String symbol) {
    final current = (data['current'] as num).toDouble();
    final previous = (data['previous'] as num).toDouble();
    final percent = (data['percent'] as num).toDouble();
    final comment = data['comment'] as String;

    Color commentColor;
    if (percent > 10) {
      commentColor = Colors.red;
    } else if (percent < -10) {
      commentColor = Colors.green;
    } else {
      commentColor = Colors.grey[600]!;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SizedBox(
        width: double.infinity,
        child: Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Monthly Comparison",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),

                const Row(
                  children: [
                    Icon(Icons.calendar_today, size: 20),
                    SizedBox(width: 10),
                    Text(
                      "This Month",
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "$symbol${current.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                const Row(
                  children: [
                    Icon(Icons.calendar_today, size: 20),
                    SizedBox(width: 10),
                    Text(
                      "Last Month",
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "$symbol${previous.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Icon(
                      percent > 10
                          ? Icons.arrow_upward
                          : percent < -10
                          ? Icons.arrow_downward
                          : Icons.remove,
                      size: 20,
                      color: commentColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        comment,
                        style: TextStyle(
                          fontSize: 16,
                          color: commentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

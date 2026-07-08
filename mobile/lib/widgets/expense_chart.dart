import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ExpenseBreakdownChart extends StatefulWidget {
  final Map<String, double> categoryExpenses;

  const ExpenseBreakdownChart({
    Key? key,
    required this.categoryExpenses,
  }) : super(key: key);

  @override
  State<ExpenseBreakdownChart> createState() => _ExpenseBreakdownChartState();
}

class _ExpenseBreakdownChartState extends State<ExpenseBreakdownChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final validExpenses = widget.categoryExpenses.entries
        .where((e) => e.value > 0)
        .toList();

    if (validExpenses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: const Center(
          child: Text(
            "No expense data available.\nScan a receipt to get started!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 14),
          ),
        ),
      );
    }

    final total = validExpenses.fold<double>(0.0, (sum, item) => sum + item.value);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Category Breakdown",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              touchedIndex = -1;
                              return;
                            }
                            touchedIndex = pieTouchResponse
                                .touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 4,
                      centerSpaceRadius: 40,
                      sections: List.generate(validExpenses.length, (i) {
                        final isTouched = i == touchedIndex;
                        final double fontSize = isTouched ? 16.0 : 12.0;
                        final double radius = isTouched ? 65.0 : 55.0;
                        final entry = validExpenses[i];
                        final percentage = (entry.value / total) * 100;

                        return PieChartSectionData(
                          color: _getCategoryColor(entry.key),
                          value: entry.value,
                          title: '${percentage.toStringAsFixed(0)}%',
                          radius: radius,
                          titleStyle: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: const [
                              Shadow(color: Colors.black45, blurRadius: 2)
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ListView.builder(
                    itemCount: validExpenses.length,
                    itemBuilder: (context, index) {
                      final entry = validExpenses[index];
                      final color = _getCategoryColor(entry.key);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.key,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '฿${entry.value.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return const Color(0xFFFF5E62); // Coral Red
      case 'travel':
      case 'transportation':
        return const Color(0xFF00C6FF); // Blue
      case 'utilities':
      case 'bills':
        return const Color(0xFFF1C40F); // Yellow
      case 'shopping':
        return const Color(0xFFE040FB); // Pink
      case 'entertainment':
        return const Color(0xFFFF9966); // Orange
      default:
        return const Color(0xFF95A5A6); // Grey
    }
  }
}

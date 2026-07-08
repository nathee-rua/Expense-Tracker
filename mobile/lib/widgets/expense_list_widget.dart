import 'package:flutter/material.dart';
import '../models/expense.dart';

class ExpenseListWidget extends StatelessWidget {
  final List<Expense> expenses;
  final Function(Expense) onEdit;
  final Function(Expense) onDelete;

  const ExpenseListWidget({
    Key? key,
    required this.expenses,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: const Center(
          child: Text(
            "ยังไม่มีการบันทึกรายการใช้จ่าย",
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ),
      );
    }

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "ประวัติรายการล่าสุด",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                "${expenses.length} รายการ",
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return _buildExpenseItemCard(expense);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseItemCard(Expense expense) {
    final catColor = _getCategoryColor(expense.category);
    final dateStr = expense.transactionDate.toIso8601String().substring(0, 10);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          // Category Avatar Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: catColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getCategoryIcon(expense.category),
              color: catColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Merchant & Time Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.receiverName ?? expense.senderName ?? 'Expense',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                 Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      "$dateStr • ${expense.transactionTime}",
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                    // Small AI Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        expense.parsedProvider.split(' ').first.toUpperCase(),
                        style: const TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Amount
          Text(
            "฿${expense.amount.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),

          // Actions
          GestureDetector(
            onTap: () => onEdit(expense),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: const Icon(Icons.edit, color: Colors.white38, size: 15),
            ),
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: () => onDelete(expense),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: const Icon(Icons.delete_outline, color: Color(0xFFFF5E62), size: 15),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'travel':
      case 'transport':
      case 'transportation':
        return Icons.directions_transit;
      case 'utilities':
      case 'bills':
        return Icons.power;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.local_play;
      default:
        return Icons.payment;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return const Color(0xFFFF5E62);
      case 'travel':
      case 'transport':
      case 'transportation':
        return const Color(0xFF00C6FF);
      case 'utilities':
      case 'bills':
        return const Color(0xFFF1C40F);
      case 'shopping':
        return const Color(0xFFE040FB);
      case 'entertainment':
        return const Color(0xFFFF9966);
      default:
        return const Color(0xFF95A5A6);
    }
  }
}

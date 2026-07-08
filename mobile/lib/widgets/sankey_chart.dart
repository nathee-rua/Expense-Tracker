import 'package:flutter/material.dart';

class SankeyChart extends StatelessWidget {
  final double income;
  final Map<String, double> categoryExpenses;

  const SankeyChart({
    Key? key,
    required this.income,
    required this.categoryExpenses,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Total expenses
    final totalExpenses = categoryExpenses.values.fold<double>(0.0, (sum, item) => sum + item);
    final remaining = income - totalExpenses;
    final displayRemaining = remaining > 0 ? remaining : 0.0;

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
            "Financial Flow (Sankey)",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: SankeyPainter(
                    income: income,
                    expenses: categoryExpenses,
                    remaining: displayRemaining,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SankeyPainter extends CustomPainter {
  final double income;
  final Map<String, double> expenses;
  final double remaining;

  SankeyPainter({
    required this.income,
    required this.expenses,
    required this.remaining,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (income <= 0) return;

    final width = size.width;
    final height = size.height;

    // Node configuration
    const nodeWidth = 20.0;
    const padding = 10.0;
    final double nodeHeightLimit = height - (padding * 2);

    // Left Node (Source)
    const sourceX = 10.0;
    final sourceY = padding;
    final sourceHeight = nodeHeightLimit;

    // Right Nodes (Destinations)
    final destX = width - nodeWidth - 10.0;

    // Filter categories with positive amounts
    final destinations = <MapEntry<String, double>>[];
    destinations.addAll(expenses.entries.where((e) => e.value > 0));
    if (remaining > 0) {
      destinations.add(MapEntry('Savings/Remaining', remaining));
    }

    if (destinations.isEmpty) return;

    // Draw Source Node (Income)
    final sourceRect = Rect.fromLTWH(sourceX, sourceY, nodeWidth, sourceHeight);
    final sourcePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF36D1DC), Color(0xFF5B86E5)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(sourceRect);

    final sourceRRect = RRect.fromRectAndRadius(sourceRect, const Radius.circular(6));
    canvas.drawRRect(sourceRRect, sourcePaint);

    // Text for Source Node
    _drawText(
      canvas,
      "Income\n฿${income.toStringAsFixed(0)}",
      Offset(sourceX + nodeWidth + 6, sourceY + sourceHeight / 2 - 14),
      Colors.white70,
      11,
      TextAlign.left,
    );

    // Calculate destination node heights and positions
    final gap = 12.0;
    final totalGaps = (destinations.length - 1) * gap;
    final availableHeightForNodes = nodeHeightLimit - totalGaps;
    
    // Sum of destination values
    final totalDestValue = income; // Match source for proportional scale

    double currentSourceYOffset = sourceY;
    double currentDestY = padding;

    for (var i = 0; i < destinations.length; i++) {
      final dest = destinations[i];
      final proportion = dest.value / totalDestValue;
      final nodeH = (proportion * availableHeightForNodes).clamp(16.0, availableHeightForNodes);

      // Define destination node rect
      final destRect = Rect.fromLTWH(destX, currentDestY, nodeWidth, nodeH);
      
      // Node color based on category
      Color nodeColor;
      if (dest.key == 'Savings/Remaining') {
        nodeColor = const Color(0xFF2ECC71); // Green
      } else {
        nodeColor = _getCategoryColor(dest.key);
      }

      final destPaint = Paint()..color = nodeColor;
      final destRRect = RRect.fromRectAndRadius(destRect, const Radius.circular(6));
      canvas.drawRRect(destRRect, destPaint);

      // Draw Connection Flow Line (S-curve path)
      final flowPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF5B86E5).withOpacity(0.3),
            nodeColor.withOpacity(0.3),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(Rect.fromLTRB(sourceX + nodeWidth, sourceY, destX, currentDestY + nodeH));

      // Calculate path for flow
      final flowH = proportion * sourceHeight;
      final path = Path();
      
      // Start of curve top
      path.moveTo(sourceX + nodeWidth, currentSourceYOffset);
      
      // S-curve to destination top
      path.cubicTo(
        (sourceX + nodeWidth + destX) / 2, currentSourceYOffset,
        (sourceX + nodeWidth + destX) / 2, currentDestY,
        destX, currentDestY,
      );

      // Line down destination node
      path.lineTo(destX, currentDestY + nodeH);

      // S-curve back to source bottom
      path.cubicTo(
        (sourceX + nodeWidth + destX) / 2, currentDestY + nodeH,
        (sourceX + nodeWidth + destX) / 2, currentSourceYOffset + flowH,
        sourceX + nodeWidth, currentSourceYOffset + flowH,
      );
      
      path.close();
      canvas.drawPath(path, flowPaint);

      // Text for Destination Node
      _drawText(
        canvas,
        "${dest.key}\n฿${dest.value.toStringAsFixed(0)}",
        Offset(destX - 8, currentDestY + nodeH / 2 - 14),
        Colors.white.withOpacity(0.85),
        10,
        TextAlign.right,
      );

      // Increment offsets
      currentSourceYOffset += flowH;
      currentDestY += nodeH + gap;
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color, double fontSize, TextAlign align) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: align,
    );
    textPainter.layout();
    
    // Adjust alignment offset
    double x = offset.dx;
    if (align == TextAlign.right) {
      x -= textPainter.width;
    }
    
    textPainter.paint(canvas, Offset(x, offset.dy));
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return const Color(0xFFFF5E62); // Coral Red
      case 'travel':
      case 'transport':
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

  @override
  bool shouldRepaint(covariant SankeyPainter oldDelegate) {
    return oldDelegate.income != income || oldDelegate.expenses != expenses || oldDelegate.remaining != remaining;
  }
}

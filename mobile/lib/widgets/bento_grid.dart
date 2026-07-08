import 'package:flutter/material.dart';

class BentoGrid extends StatelessWidget {
  final double totalBudget;
  final double totalSpent;
  final String activeProvider;
  final bool isOcrReady;
  final VoidCallback onSelectImage;
  final VoidCallback onChangeProvider;
  final VoidCallback onChangeBudget;
  final Widget chartWidget;
  final Widget sankeyWidget;

  const BentoGrid({
    Key? key,
    required this.totalBudget,
    required this.totalSpent,
    required this.activeProvider,
    required this.isOcrReady,
    required this.onSelectImage,
    required this.onChangeProvider,
    required this.onChangeBudget,
    required this.chartWidget,
    required this.sankeyWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final balance = totalBudget - totalSpent;
    final balanceColor = balance >= 0 ? const Color(0xFF2ECC71) : const Color(0xFFFF5E62);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        key: const ValueKey('bento_scroll_view'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Antigravity Finance",
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Premium Dashboard",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                // Camera Action Button
                GestureDetector(
                  onTap: onSelectImage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8E2DE2).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Row 1: Big Budget card (2x1 equivalent)
            GestureDetector(
              onTap: onChangeBudget,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.08),
                      Colors.white.withOpacity(0.03),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          "TOTAL BUDGET POOL",
                          style: TextStyle(
                            color: Colors.white50,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Icon(Icons.edit, color: Colors.white38, size: 16),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "฿${totalBudget.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Expenses", style: TextStyle(color: Colors.white38, fontSize: 11)),
                              const SizedBox(height: 4),
                              Text(
                                "฿${totalSpent.toStringAsFixed(2)}",
                                style: const TextStyle(color: Colors.white87, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.white10,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Remaining", style: TextStyle(color: Colors.white38, fontSize: 11)),
                              const SizedBox(height: 4),
                              Text(
                                "฿${balance.toStringAsFixed(2)}",
                                style: TextStyle(color: balanceColor, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Row 2: 1x1 widgets in a grid
            Row(
              children: [
                // Active AI Provider Card (1x1)
                Expanded(
                  child: GestureDetector(
                    onTap: onChangeProvider,
                    child: Container(
                      height: 120,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.psychology, color: Color(0xFF00C6FF), size: 24),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "AI PROVIDER",
                                style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                activeProvider.toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // OCR Status Card (1x1)
                Expanded(
                  child: Container(
                    height: 120,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(Icons.document_scanner, color: Color(0xFF2ECC71), size: 24),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isOcrReady ? const Color(0xFF2ECC71) : Colors.amber,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "THAI OCR STATE",
                              style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isOcrReady ? "OFFLINE ACTIVE" : "LOCAL READY",
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Row 3: Sankey visual chart (Flow of Funds)
            SizedBox(
              height: 250,
              child: sankeyWidget,
            ),
            const SizedBox(height: 16),

            // Row 4: Category breakdown visual chart
            SizedBox(
              height: 220,
              child: chartWidget,
            ),
          ],
        ),
      ),
    );
  }
}

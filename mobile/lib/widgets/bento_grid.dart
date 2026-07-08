import 'package:flutter/material.dart';

class BentoGrid extends StatelessWidget {
  final double totalBudget;
  final double totalSpent;
  final double dailyAverage;
  final double projectedSpent;
  final String activeProvider;
  final bool isOcrReady;
  final VoidCallback onSelectImage;
  final VoidCallback onChangeProvider;
  final VoidCallback onChangeBudget;
  final VoidCallback onAddManual;
  final VoidCallback onResetAll;
  final VoidCallback onExportData;
  final Widget chartWidget;
  final Widget sankeyWidget;
  final Widget expenseListWidget;

  const BentoGrid({
    Key? key,
    required this.totalBudget,
    required this.totalSpent,
    required this.dailyAverage,
    required this.projectedSpent,
    required this.activeProvider,
    required this.isOcrReady,
    required this.onSelectImage,
    required this.onChangeProvider,
    required this.onChangeBudget,
    required this.onAddManual,
    required this.onResetAll,
    required this.onExportData,
    required this.chartWidget,
    required this.sankeyWidget,
    required this.expenseListWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final balance = totalBudget - totalSpent;
    final balanceColor = balance >= 0 ? const Color(0xFF2ECC71) : const Color(0xFFFF5E62);
    final isOverBudget = projectedSpent > totalBudget;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header & Quick Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "แอนตี้กราวิตี้ การเงิน",
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "แดชบอร์ดระดับพรีเมียม",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                // Camera Scanner Action Button
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
            const SizedBox(height: 16),

            // Quick Actions Bar (Manual Add, Export, Reset)
            Row(
              children: [
                _buildActionButton(
                  icon: Icons.add_circle_outline,
                  label: "เพิ่มรายการเอง",
                  color: const Color(0xFF00C6FF),
                  onTap: onAddManual,
                ),
                const SizedBox(width: 10),
                _buildActionButton(
                  icon: Icons.ios_share,
                  label: "ส่งออก CSV",
                  color: const Color(0xFF2ECC71),
                  onTap: onExportData,
                ),
                const SizedBox(width: 10),
                _buildActionButton(
                  icon: Icons.restart_alt,
                  label: "รีเซ็ตข้อมูล",
                  color: const Color(0xFFFF5E62),
                  onTap: onResetAll,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Row 1: Big Budget card (2x1 equivalent) with Trend forecasting
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
                          "งบประมาณหลัก",
                          style: TextStyle(
                            color: Colors.white54,
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
                              const Text("รายจ่ายรวม", style: TextStyle(color: Colors.white38, fontSize: 11)),
                              const SizedBox(height: 4),
                              Text(
                                "฿${totalSpent.toStringAsFixed(2)}",
                                style: const TextStyle(color: Color(0xDEFFFFFF), fontSize: 15, fontWeight: FontWeight.bold),
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
                              const Text("คงเหลือ", style: TextStyle(color: Colors.white38, fontSize: 11)),
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

                    // Divider and Forecasting section
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(color: Colors.white10, height: 1),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.analytics_outlined, color: Colors.white38, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "เฉลี่ย/วัน: ฿${dailyAverage.toStringAsFixed(1)} • คาดการณ์สิ้นเดือน: ฿${projectedSpent.toStringAsFixed(1)}",
                            style: TextStyle(
                              color: isOverBudget ? const Color(0xFFFF5E62) : Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isOverBudget)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5E62).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5E62), size: 10),
                                SizedBox(width: 2),
                                Text(
                                  "เสี่ยงงบเกินเป้า!",
                                  style: TextStyle(color: Color(0xFFFF5E62), fontSize: 8, fontWeight: FontWeight.bold),
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
                                "ผู้ให้บริการ AI",
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
                              "ระบบสแกนสลิป",
                              style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isOcrReady ? "ทำงานออฟไลน์" : "พร้อมใช้งาน",
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
            const SizedBox(height: 16),

            // Row 5: Scrollable Transaction List
            expenseListWidget,
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

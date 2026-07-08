import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import '../widgets/bento_grid.dart';
import '../widgets/sankey_chart.dart';
import '../widgets/expense_chart.dart';
import '../widgets/receipt_scanner.dart';
import '../services/api_service.dart';
import 'ai_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  
  // App settings & states
  double _totalBudget = 15000.00;
  String _apiBaseUrl = "https://expense-tracker-zeta-two-80.vercel.app"; // Deployed live URL
  String _activeProvider = "gemini";
  bool _isOcrReady = true;

  // Transaction list (Pre-populate with realistic mock slips to demonstrate graphics)
  final List<Expense> _expenses = [];

  @override
  void initState() {
    super.initState();
    _loadMockData();
    _loadActiveConfig();
    _fetchBackendHealth();
  }

  Future<void> _loadActiveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _activeProvider = prefs.getString('active_provider') ?? 'gemini';
    });
  }

  void _navigateToAiSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AISettingsScreen(apiBaseUrl: _apiBaseUrl),
      ),
    ).then((_) {
      _loadActiveConfig();
    });
  }

  void _loadMockData() {
    _expenses.addAll([
      Expense(
        id: "mock-1",
        transactionDate: DateTime.now().subtract(const Duration(days: 1)),
        transactionTime: "12:30",
        amount: 350.00,
        senderName: "Nattawut M.",
        receiverName: "Somtum Sab Zaap",
        bankName: "Kasikorn Bank",
        category: "Food",
        items: [ExpenseItem(name: "Somtum & Grilled Chicken", price: 350.00, quantity: 1)],
        rawOcrText: "K-Plus Transfer Successful\nDate: 2026-07-07 Time: 12:30\nTo: Somtum Sab Zaap\nAmount: 350.00 THB",
        parsedProvider: "gemini (mock)",
      ),
      Expense(
        id: "mock-2",
        transactionDate: DateTime.now().subtract(const Duration(days: 2)),
        transactionTime: "08:15",
        amount: 120.00,
        senderName: "Nattawut M.",
        receiverName: "BTS Skytrain",
        bankName: "PromptPay",
        category: "Travel",
        items: [ExpenseItem(name: "BTS Single Journey Ticket", price: 120.00, quantity: 1)],
        rawOcrText: "PromptPay QR Payment\nRef: BTS Skytrain\nAmount: 120.00 Baht\nSuccess",
        parsedProvider: "openrouter (mock)",
      ),
      Expense(
        id: "mock-3",
        transactionDate: DateTime.now().subtract(const Duration(days: 3)),
        transactionTime: "18:45",
        amount: 1450.00,
        senderName: "Nattawut M.",
        receiverName: "MEA Electricity",
        bankName: "Siam Commercial Bank",
        category: "Utilities",
        items: [ExpenseItem(name: "Monthly Electricity Bill", price: 1450.00, quantity: 1)],
        rawOcrText: "SCB Easy\nPayment to: Metropolitan Electricity Authority\nAmount: 1,450.00 THB\nTransaction completed.",
        parsedProvider: "groq (mock)",
      ),
      Expense(
        id: "mock-4",
        transactionDate: DateTime.now().subtract(const Duration(days: 4)),
        transactionTime: "15:20",
        amount: 890.00,
        senderName: "Nattawut M.",
        receiverName: "Uniqlo Siam Paragon",
        bankName: "Krungthai Bank",
        category: "Shopping",
        items: [ExpenseItem(name: "Premium Linen Shirt", price: 890.00, quantity: 1)],
        rawOcrText: "Krungthai NEXT\nTransaction: Transfer Success\nTo: UNIQLO THAILAND\nAmount: 890.00 THB",
        parsedProvider: "gemini (mock)",
      ),
    ]);
  }

  Future<void> _fetchBackendHealth() async {
    final health = await _apiService.checkHealth(_apiBaseUrl);
    if (health['success'] == true) {
      setState(() {
        _activeProvider = health['activeProvider'] ?? 'gemini';
      });
    }
  }

  double get _totalSpent => _expenses.fold<double>(0.0, (sum, e) => sum + e.amount);

  Map<String, double> get _categoryExpenses {
    final Map<String, double> categories = {
      'Food': 0.0,
      'Travel': 0.0,
      'Utilities': 0.0,
      'Shopping': 0.0,
      'Entertainment': 0.0,
    };

    for (var e in _expenses) {
      final categoryKey = e.category.trim();
      
      // Categorize properly or add to other
      if (categories.containsKey(categoryKey)) {
        categories[categoryKey] = (categories[categoryKey] ?? 0.0) + e.amount;
      } else {
        categories[categoryKey] = (categories[categoryKey] ?? 0.0) + e.amount;
      }
    }
    return categories;
  }

  void _showScannerBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReceiptScannerBottomSheet(
        apiBaseUrl: _apiBaseUrl,
        onExpenseParsed: (newExpense) {
          setState(() {
            _expenses.insert(0, newExpense);
          });
        },
      ),
    );
  }

  // Provider selector removed in favor of AISettingsScreen

  void _showBudgetEditor() {
    final controller = TextEditingController(text: _totalBudget.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title: const Text("Edit Total Budget Pool", style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8E2DE2))),
              labelText: "Budget (THB)",
              labelStyle: TextStyle(color: Colors.white70),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8E2DE2)),
              onPressed: () {
                final double? parsedVal = double.tryParse(controller.text);
                if (parsedVal != null && parsedVal > 0) {
                  setState(() {
                    _totalBudget = parsedVal;
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _showSettingsDialog() {
    final controller = TextEditingController(text: _apiBaseUrl);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title: const Text("Connection Settings", style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8E2DE2))),
              labelText: "API Server Base URL",
              labelStyle: TextStyle(color: Colors.white70),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8E2DE2)),
              onPressed: () {
                setState(() {
                  _apiBaseUrl = controller.text.trim();
                });
                Navigator.pop(context);
                _fetchBackendHealth();
              },
              child: const Text("Apply"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F16),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: BentoGrid(
        totalBudget: _totalBudget,
        totalSpent: _totalSpent,
        activeProvider: _activeProvider,
        isOcrReady: _isOcrReady,
        onSelectImage: _showScannerBottomSheet,
        onChangeProvider: _navigateToAiSettings,
        onChangeBudget: _showBudgetEditor,
        chartWidget: ExpenseBreakdownChart(categoryExpenses: _categoryExpenses),
        sankeyWidget: SankeyChart(income: _totalBudget, categoryExpenses: _categoryExpenses),
      ),
    );
  }
}

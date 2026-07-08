import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import '../widgets/bento_grid.dart';
import '../widgets/sankey_chart.dart';
import '../widgets/expense_chart.dart';
import '../widgets/receipt_scanner.dart';
import '../widgets/expense_list_widget.dart';
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

  // Categories list (Dynamic)
  List<String> _categories = ['Food', 'Travel', 'Utilities', 'Shopping', 'Entertainment', 'Other'];

  // Transaction list (Persisted dynamically)
  final List<Expense> _expenses = [];

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    _fetchBackendHealth();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load budget
    setState(() {
      _totalBudget = prefs.getDouble('total_budget') ?? 15000.00;
    });

    // Load categories
    final savedCats = prefs.getStringList('saved_categories');
    if (savedCats != null && savedCats.isNotEmpty) {
      setState(() {
        _categories = savedCats;
      });
    }

    // Load active provider
    await _loadActiveConfig();

    // Load expenses
    final savedList = prefs.getStringList('saved_expenses');
    if (savedList != null && savedList.isNotEmpty) {
      setState(() {
        _expenses.clear();
        for (var item in savedList) {
          try {
            _expenses.add(Expense.fromJson(jsonDecode(item)));
          } catch (e) {
            print("Error loading individual expense: $e");
          }
        }
      });
    } else {
      _loadMockData();
      _saveExpenses();
    }
  }

  void _loadMockData() {
    setState(() {
      _expenses.addAll([
        Expense(
          id: "mock-1",
          transactionDate: DateTime.now().subtract(const Duration(days: 1)),
          transactionTime: "12:30",
          amount: 350.00,
          receiverName: "Somtum Sab Zaap",
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
          receiverName: "BTS Skytrain",
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
          receiverName: "MEA Electricity",
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
          receiverName: "Uniqlo Siam Paragon",
          category: "Shopping",
          items: [ExpenseItem(name: "Premium Linen Shirt", price: 890.00, quantity: 1)],
          rawOcrText: "Krungthai NEXT\nTransaction: Transfer Success\nTo: UNIQLO THAILAND\nAmount: 890.00 THB",
          parsedProvider: "gemini (mock)",
        ),
      ]);
    });
  }

  Future<void> _saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _expenses.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('saved_expenses', list);
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_categories', _categories);
  }

  Future<void> _loadActiveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _activeProvider = prefs.getString('active_provider') ?? 'gemini';
    });
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

  // Dynamic Trend Forecasting Calculations
  double get _dailyAverage {
    if (_expenses.isEmpty) return 0.0;
    
    final now = DateTime.now();
    final elapsedDays = now.day;
    
    final currentMonthExpenses = _expenses.where((e) => 
      e.transactionDate.month == now.month && 
      e.transactionDate.year == now.year
    );
    
    final totalSpentThisMonth = currentMonthExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    
    return totalSpentThisMonth / (elapsedDays > 0 ? elapsedDays : 1);
  }

  double get _projectedSpent {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    return _dailyAverage * daysInMonth;
  }

  Map<String, double> get _categoryExpenses {
    final Map<String, double> categories = {};
    for (var c in _categories) {
      categories[c] = 0.0;
    }

    for (var e in _expenses) {
      final categoryKey = _getValidCategory(e.category);
      categories[categoryKey] = (categories[categoryKey] ?? 0.0) + e.amount;
    }
    return categories;
  }

  String _getValidCategory(String category) {
    return _categories.firstWhere(
      (c) => c.toLowerCase() == category.toLowerCase().trim(),
      orElse: () => _categories.contains('Other') ? 'Other' : _categories.first,
    );
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

  void _showScannerBottomSheet([XFile? file, String? pdfBase64, String? pdfName]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReceiptScannerBottomSheet(
        apiBaseUrl: _apiBaseUrl,
        initialFile: file,
        pdfBase64: pdfBase64,
        pdfName: pdfName,
        onExpenseParsed: (newExpense) {
          setState(() {
            _expenses.insert(0, newExpense);
          });
          _saveExpenses();
        },
      ),
    );
  }

  Future<void> _pickAndScanImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        _showScannerBottomSheet(pickedFile);
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e")),
      );
    }
  }

  Future<void> _pickAndScanPdf() async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.isEmpty) return;

      final PlatformFile file = result.files.first;
      String base64Data = '';

      if (kIsWeb) {
        if (file.bytes != null) {
          base64Data = base64Encode(file.bytes!);
        }
      } else {
        if (file.path != null) {
          final pdfFile = File(file.path!);
          final bytes = await pdfFile.readAsBytes();
          base64Data = base64Encode(bytes);
        }
      }

      if (base64Data.isNotEmpty) {
        _showScannerBottomSheet(null, base64Data, file.name);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ไม่สามารถอ่านข้อมูลไฟล์ PDF ได้")),
        );
      }
    } catch (e) {
      print("Error picking PDF: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาดในการเลือกไฟล์ PDF: $e")),
      );
    }
  }

  String translateCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food': return 'อาหาร';
      case 'travel': return 'การเดินทาง';
      case 'utilities': return 'สาธารณูปโภค';
      case 'shopping': return 'ช็อปปิ้ง';
      case 'entertainment': return 'ความบันเทิง';
      case 'other': return 'อื่นๆ';
      default: return category; // User custom categories returned as-is
    }
  }

  // --- CRUD OPERATIONS ---

  void _showCategoryManagerDialog() {
    final TextEditingController newCatController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E2C),
              title: const Text("จัดการหมวดหมู่ค่าใช้จ่าย", style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.maxFinite,
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _categories.length,
                      itemBuilder: (context, idx) {
                        final catName = _categories[idx];
                        final isDefault = ['Food', 'Travel', 'Utilities', 'Shopping', 'Entertainment', 'Other'].contains(catName);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(translateCategory(catName), style: const TextStyle(color: Colors.white, fontSize: 14)),
                          subtitle: isDefault ? const Text("หมวดหมู่เริ่มต้น", style: TextStyle(color: Colors.white38, fontSize: 10)) : null,
                          trailing: isDefault
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Color(0xFFFF5E62), size: 18),
                                  onPressed: () {
                                    setDialogState(() {
                                      _categories.removeAt(idx);
                                    });
                                    setState(() {});
                                    _saveCategories();
                                  },
                                ),
                        );
                      },
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: newCatController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: "เพิ่มหมวดหมู่ใหม่...",
                            hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8E2DE2))),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Color(0xFF00C6FF)),
                        onPressed: () {
                          final newCat = newCatController.text.trim();
                          if (newCat.isNotEmpty && !_categories.contains(newCat)) {
                            setDialogState(() {
                              _categories.add(newCat);
                              newCatController.clear();
                            });
                            setState(() {});
                            _saveCategories();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E2DE2),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("เสร็จสิ้น", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddManualDialog() {
    final merchantController = TextEditingController();
    final amountController = TextEditingController();
    final dateController = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    final timeController = TextEditingController(text: "12:00");
    String selectedCategory = _categories.contains('Food') ? 'Food' : _categories.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E2C),
              title: const Text("เพิ่มรายการใช้จ่ายด้วยตัวเอง", style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: merchantController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: "ร้านค้า / รายการ", labelStyle: TextStyle(color: Colors.white54)),
                  ),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: "จำนวนเงิน (บาท)", labelStyle: TextStyle(color: Colors.white54)),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: dateController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: "วันที่", labelStyle: TextStyle(color: Colors.white54)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: timeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: "เวลา", labelStyle: TextStyle(color: Colors.white54)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButton<String>(
                    dropdownColor: const Color(0xFF1E1E2C),
                    value: selectedCategory,
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white),
                    items: _categories.map((c) {
                      return DropdownMenuItem<String>(value: c, child: Text(translateCategory(c)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedCategory = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("ยกเลิก", style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E2DE2),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final double? amount = double.tryParse(amountController.text);
                    if (amount != null && merchantController.text.isNotEmpty) {
                      setState(() {
                        _expenses.insert(
                          0,
                          Expense(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            transactionDate: DateTime.tryParse(dateController.text) ?? DateTime.now(),
                            transactionTime: timeController.text,
                            amount: amount,
                            receiverName: merchantController.text,
                            category: selectedCategory,
                            items: [],
                            rawOcrText: "Manual Entry",
                            parsedProvider: "manual",
                          ),
                        );
                      });
                      _saveExpenses();
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("เพิ่มรายการ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditDialog(Expense expense) {
    final merchantController = TextEditingController(text: expense.receiverName ?? expense.senderName);
    final amountController = TextEditingController(text: expense.amount.toStringAsFixed(2));
    final dateController = TextEditingController(text: expense.transactionDate.toIso8601String().substring(0, 10));
    final timeController = TextEditingController(text: expense.transactionTime);
    String selectedCategory = _getValidCategory(expense.category);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E2C),
              title: const Text("แก้ไขรายการใช้จ่าย", style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: merchantController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: "ร้านค้า / รายการ", labelStyle: TextStyle(color: Colors.white54)),
                  ),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: "จำนวนเงิน (บาท)", labelStyle: TextStyle(color: Colors.white54)),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: dateController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: "วันที่", labelStyle: TextStyle(color: Colors.white54)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: timeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: "เวลา", labelStyle: TextStyle(color: Colors.white54)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButton<String>(
                    dropdownColor: const Color(0xFF1E1E2C),
                    value: selectedCategory,
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white),
                    items: _categories.map((c) {
                      return DropdownMenuItem<String>(value: c, child: Text(translateCategory(c)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedCategory = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("ยกเลิก", style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E2DE2),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final double? amount = double.tryParse(amountController.text);
                    if (amount != null && merchantController.text.isNotEmpty) {
                      final index = _expenses.indexWhere((e) => e.id == expense.id);
                      if (index != -1) {
                        setState(() {
                          _expenses[index] = Expense(
                            id: expense.id,
                            transactionDate: DateTime.tryParse(dateController.text) ?? expense.transactionDate,
                            transactionTime: timeController.text,
                            amount: amount,
                            receiverName: merchantController.text,
                            category: selectedCategory,
                            items: expense.items,
                            rawOcrText: expense.rawOcrText,
                            parsedProvider: expense.parsedProvider,
                          );
                        });
                        _saveExpenses();
                      }
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("บันทึก", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteExpense(Expense expense) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title: const Text("ลบรายการจ่ายนี้?", style: TextStyle(color: Colors.white)),
          content: Text("คุณแน่ใจหรือไม่ที่จะลบรายการใช้จ่ายจำนวน ฿${expense.amount.toStringAsFixed(2)} ที่ร้าน ${expense.receiverName}?", style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ยกเลิก", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5E62),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _expenses.removeWhere((e) => e.id == expense.id);
                });
                _saveExpenses();
                Navigator.pop(context);
              },
              child: const Text("ลบรายการ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _resetAllData() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title: const Text("รีเซ็ตข้อมูลทั้งหมด?", style: TextStyle(color: Colors.white)),
          content: const Text("ระบบจะลบงบประมาณและรายการการเงินที่คุณสร้างขึ้นทั้งหมด และโหลดข้อมูลตัวอย่างดั้งเดิมเข้ามาแทนที่ การกระทำนี้ไม่สามารถกู้คืนได้", style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ยกเลิก", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5E62),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('saved_expenses');
                await prefs.remove('total_budget');
                await prefs.remove('saved_categories');
                setState(() {
                  _expenses.clear();
                  _totalBudget = 15000.00;
                  _categories = ['Food', 'Travel', 'Utilities', 'Shopping', 'Entertainment', 'Other'];
                  _loadMockData();
                });
                _saveExpenses();
                _saveCategories();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("รีเซ็ตข้อมูลระบบเสร็จสิ้น")),
                  );
                }
              },
              child: const Text("รีเซ็ต", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _exportDataCSV() {
    if (_expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ไม่มีข้อมูลให้ส่งออก")),
      );
      return;
    }

    final csvBuffer = StringBuffer();
    csvBuffer.writeln("ID,Date,Time,Merchant,Amount,Category,AIProvider");
    
    for (var e in _expenses) {
      final merchant = (e.receiverName ?? e.senderName ?? 'Expense').replaceAll(',', ';');
      final date = e.transactionDate.toIso8601String().substring(0, 10);
      csvBuffer.writeln("${e.id},$date,${e.transactionTime},$merchant,${e.amount},${e.category},${e.parsedProvider}");
    }

    final csvText = csvBuffer.toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title: const Text("ส่งออกข้อมูล CSV", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("คัดลอกข้อความ CSV ด้านล่างเพื่อนำไปใช้งานบน Excel หรือ Google Sheets:", style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    csvText,
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8E2DE2),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("คัดลอก CSV ลงคลิปบอร์ดแล้ว!")),
                );
              },
              child: const Text("เสร็จสิ้น", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showBudgetEditor() {
    final controller = TextEditingController(text: _totalBudget.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title: const Text("แก้ไขงบประมาณหลัก", style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8E2DE2))),
              labelText: "งบประมาณรายเดือน (บาท)",
              labelStyle: TextStyle(color: Colors.white70),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ยกเลิก", style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8E2DE2),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final double? parsedVal = double.tryParse(controller.text);
                if (parsedVal != null && parsedVal > 0) {
                  setState(() {
                    _totalBudget = parsedVal;
                  });
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setDouble('total_budget', parsedVal);
                }
                Navigator.pop(context);
              },
              child: const Text("บันทึก", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          title: const Text("ตั้งค่าเซิร์ฟเวอร์เชื่อมต่อ", style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8E2DE2))),
              labelText: "ที่อยู่เซิร์ฟเวอร์หลัก (API Base URL)",
              labelStyle: TextStyle(color: Colors.white70),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ยกเลิก", style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8E2DE2),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _apiBaseUrl = controller.text.trim();
                });
                Navigator.pop(context);
                _fetchBackendHealth();
              },
              child: const Text("ตกลง", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            icon: const Icon(Icons.restart_alt, color: Colors.white70),
            onPressed: _resetAllData,
            tooltip: "รีเซ็ตข้อมูลทั้งหมด",
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: _showSettingsDialog,
            tooltip: "ตั้งค่าการเชื่อมต่อ",
          ),
        ],
      ),
      body: BentoGrid(
        totalBudget: _totalBudget,
        totalSpent: _totalSpent,
        dailyAverage: _dailyAverage,
        projectedSpent: _projectedSpent,
        activeProvider: _activeProvider,
        isOcrReady: _isOcrReady,
        onSelectImage: _pickAndScanImage,
        onSelectPdf: _pickAndScanPdf,
        onChangeProvider: _navigateToAiSettings,
        onChangeBudget: _showBudgetEditor,
        onAddManual: _showAddManualDialog,
        onManageCategories: _showCategoryManagerDialog,
        onExportData: _exportDataCSV,
        chartWidget: ExpenseBreakdownChart(categoryExpenses: _categoryExpenses),
        sankeyWidget: SankeyChart(income: _totalBudget, categoryExpenses: _categoryExpenses),
        expenseListWidget: ExpenseListWidget(
          expenses: _expenses,
          onEdit: _showEditDialog,
          onDelete: _deleteExpense,
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ocr_service.dart';
import '../services/api_service.dart';
import '../services/emvco_parser.dart';
import '../models/expense.dart';

class ReceiptScannerBottomSheet extends StatefulWidget {
  final String apiBaseUrl;
  final Function(Expense) onExpenseParsed;

  const ReceiptScannerBottomSheet({
    Key? key,
    required this.apiBaseUrl,
    required this.onExpenseParsed,
  }) : super(key: key);

  @override
  State<ReceiptScannerBottomSheet> createState() => _ReceiptScannerBottomSheetState();
}

class _ReceiptScannerBottomSheetState extends State<ReceiptScannerBottomSheet> {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();
  final ApiService _apiService = ApiService();

  XFile? _pickedFile;
  File? _imageFile;
  String _statusText = '';
  bool _isLoading = false;
  String _extractedOcrText = '';
  bool _showOcrEditor = false;
  final TextEditingController _ocrTextController = TextEditingController();

  // Confirm Form properties
  bool _showConfirmForm = false;
  final TextEditingController _merchantController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  String _selectedCategory = 'Food';
  String _parsedProvider = '';

  @override
  void dispose() {
    _ocrService.dispose();
    _ocrTextController.dispose();
    _merchantController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      setState(() {
        _pickedFile = pickedFile;
        _imageFile = kIsWeb ? null : File(pickedFile.path);
        _isLoading = true;
        _statusText = kIsWeb
            ? "Local OCR not supported on Web. Preparing image upload..."
            : "Performing offline Thai OCR...";
      });

      if (kIsWeb) {
        setState(() {
          _extractedOcrText = "Web Platform: Local offline OCR is skipped. Please select 'Submit Full Image' to parse using cloud AI.";
          _ocrTextController.text = _extractedOcrText;
          _statusText = "Local OCR skipped on Web. Please choose 'Submit Full Image'.";
          _isLoading = false;
          _showOcrEditor = true;
        });
        return;
      }

      // Step 1: Run local OCR
      final ocrText = await _ocrService.recognizeText(_imageFile!);
      
      // Step 2: Check for EMVCo PromptPay QR Code
      final emvcoData = EmvcoParser.parse(ocrText);
      String status = "OCR complete. Review the text below or proceed.";
      if (emvcoData != null) {
        status = "PromptPay QR code detected! Exact Amount ฿${(emvcoData['amount'] as double).toStringAsFixed(2)} pre-filled.";
      }

      setState(() {
        _extractedOcrText = ocrText;
        _ocrTextController.text = ocrText;
        if (ocrText.contains("MissingPluginException") || ocrText.contains("OCR recognition error")) {
          _statusText = "Local OCR not supported in this environment. Please choose 'Submit Full Image'.";
        } else {
          _statusText = status;
        }
        _isLoading = false;
        _showOcrEditor = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusText = "Error: ${e.toString()}";
      });
    }
  }

  String _getValidCategory(String category) {
    final validCategories = ['Food', 'Travel', 'Utilities', 'Shopping', 'Entertainment', 'Other'];
    return validCategories.firstWhere(
      (c) => c.toLowerCase() == category.toLowerCase().trim(),
      orElse: () => 'Other',
    );
  }

  Future<void> _submitToServer(bool sendAsImage) async {
    if (_pickedFile == null && !sendAsImage) return;

    setState(() {
      _isLoading = true;
      _statusText = sendAsImage 
          ? "Encoding image & sending base64 to server..." 
          : "Sending extracted text to server...";
    });

    try {
      String dataPayload = '';
      if (sendAsImage && _pickedFile != null) {
        final bytes = await _pickedFile!.readAsBytes();
        dataPayload = base64Encode(bytes);
      } else {
        dataPayload = _ocrTextController.text;
      }

      final prefs = await SharedPreferences.getInstance();
      final provider = prefs.getString('active_provider') ?? 'gemini';
      final model = prefs.getString('active_model') ?? 'gemini-1.5-flash';
      final apiKey = prefs.getString('key_$provider') ?? '';

      // Check EMVCo QR code local parsing first to augment payloads
      final emvcoData = EmvcoParser.parse(_ocrTextController.text);

      final result = await _apiService.parseReceipt(
        data: dataPayload,
        isImage: sendAsImage,
        baseUrl: widget.apiBaseUrl,
        provider: provider,
        model: model,
        apiKey: apiKey.isNotEmpty ? apiKey : null,
      );

      if (result['success'] == true) {
        final parsedData = result['data'] ?? {};
        
        // Resolve data with PromptPay EMVCo overrides if OCR found it
        final double finalAmount = emvcoData != null 
            ? (emvcoData['amount'] as double) 
            : ((parsedData['amount'] as num?)?.toDouble() ?? 0.0);

        final merchant = parsedData['receiver_name'] ?? parsedData['sender_name'] ?? 'Merchant';
        final date = parsedData['transaction_date'] ?? DateTime.now().toIso8601String().substring(0, 10);
        final time = parsedData['transaction_time'] ?? '00:00';
        final category = parsedData['category'] ?? 'Other';

        // Learning loop: check if we have a locally stored custom category mapping for this merchant name
        final merchantKey = merchant.toString().toLowerCase().trim();
        final localPrefCategory = prefs.getString('pref_cat_$merchantKey');
        final resolvedCategory = localPrefCategory ?? category;

        setState(() {
          _isLoading = false;
          _showConfirmForm = true;
          _merchantController.text = merchant.toString();
          _amountController.text = finalAmount.toStringAsFixed(2);
          _dateController.text = date.toString();
          _timeController.text = time.toString();
          _selectedCategory = _getValidCategory(resolvedCategory.toString());
          _parsedProvider = result['provider'] ?? provider;
        });

      } else {
        setState(() {
          _isLoading = false;
          _statusText = "Error: ${result['error']}";
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusText = "Error submitting: ${e.toString()}";
      });
    }
  }

  Future<void> _confirmAndSave() async {
    final double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount")),
      );
      return;
    }

    final merchantName = _merchantController.text.trim();
    if (merchantName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a merchant name")),
      );
      return;
    }

    // Save category override for learning loop
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_cat_${merchantName.toLowerCase()}', _selectedCategory);

    // Create the final expense log
    final finalExpense = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      transactionDate: DateTime.tryParse(_dateController.text) ?? DateTime.now(),
      transactionTime: _timeController.text,
      amount: amount,
      receiverName: merchantName,
      category: _selectedCategory,
      items: [],
      rawOcrText: _ocrTextController.text,
      parsedProvider: _parsedProvider,
    );

    widget.onExpenseParsed(finalExpense);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF2ECC71),
          content: Text("Transaction confirmed and logged!"),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: _showConfirmForm 
          ? _buildConfirmFormWidget() 
          : MainScannerColumn(
              imageFile: _imageFile,
              statusText: _statusText,
              isLoading: _isLoading,
              showOcrEditor: _showOcrEditor,
              ocrTextController: _ocrTextController,
              onPickImage: _pickImage,
              onSubmitToServer: _submitToServer,
            ),
    );
  }

  Widget _buildConfirmFormWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Verify Auto-Fill Details",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "AI automatically extracted these fields. Please review before saving.",
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // Merchant Field
        TextField(
          controller: _merchantController,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            labelText: "Merchant / Store",
            labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8E2DE2))),
          ),
        ),
        const SizedBox(height: 12),

        // Amount Field
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            labelText: "Amount (THB)",
            labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8E2DE2))),
          ),
        ),
        const SizedBox(height: 12),

        // Date and Time Fields Side-by-Side
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _dateController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: "Date (YYYY-MM-DD)",
                  labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8E2DE2))),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _timeController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: "Time (HH:MM)",
                  labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8E2DE2))),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Category Selector
        const Text("Category", style: TextStyle(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: const Color(0xFF1E1E2C),
              value: _selectedCategory,
              isExpanded: true,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              items: ['Food', 'Travel', 'Utilities', 'Shopping', 'Entertainment', 'Other'].map((c) {
                return DropdownMenuItem<String>(
                  value: c,
                  child: Text(c),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedCategory = val;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Action Button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2ECC71),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: _confirmAndSave,
          child: const Text("Confirm & Save", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// Extracted widget class for code organization
class MainScannerColumn extends StatelessWidget {
  final File? imageFile;
  final String statusText;
  final bool isLoading;
  final bool showOcrEditor;
  final TextEditingController ocrTextController;
  final Function(ImageSource) onPickImage;
  final Function(bool) onSubmitToServer;

  const MainScannerColumn({
    Key? key,
    required this.imageFile,
    required this.statusText,
    required this.isLoading,
    required this.showOcrEditor,
    required this.ocrTextController,
    required this.onPickImage,
    required this.onSubmitToServer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Scan or Upload Receipt",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "Localized offline Thai OCR processes text first, then forwards to cloud AI adapter.",
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (imageFile == null && !isLoading)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSelectionButton(
                icon: Icons.camera_alt,
                label: "Camera",
                onTap: () => onPickImage(ImageSource.camera),
              ),
              _buildSelectionButton(
                icon: Icons.photo_library,
                label: "Gallery",
                onTap: () => onPickImage(ImageSource.gallery),
              ),
            ],
          ),
        if (isLoading)
          Column(
            children: [
              const SizedBox(height: 16),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E2DE2)),
              ),
              const SizedBox(height: 16),
              Text(
                statusText,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
          ),
        if (imageFile != null && !isLoading) ...[
          if (showOcrEditor) ...[
            const Text(
              "Extracted Offline Thai Text",
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: TextField(
                controller: ocrTextController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Extracted receipt content will display here...",
                  hintStyle: TextStyle(color: Colors.white30),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              statusText,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.08),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => onSubmitToServer(false),
                    child: const Text("Process OCR Text"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8E2DE2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => onSubmitToServer(true),
                    child: const Text("Submit Full Image"),
                  ),
                ),
              ],
            ),
          ],
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSelectionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF8E2DE2), size: 36),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

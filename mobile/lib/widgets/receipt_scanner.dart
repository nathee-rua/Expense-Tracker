import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ocr_service.dart';
import '../services/api_service.dart';
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

  File? _imageFile;
  String _statusText = '';
  bool _isLoading = false;
  String _extractedOcrText = '';
  bool _showOcrEditor = false;
  final TextEditingController _ocrTextController = TextEditingController();

  @override
  void dispose() {
    _ocrService.dispose();
    _ocrTextController.dispose();
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
        _imageFile = File(pickedFile.path);
        _isLoading = true;
        _statusText = "Performing offline Thai OCR...";
      });

      // Step 1: Run local OCR
      final ocrText = await _ocrService.recognizeText(_imageFile!);
      
      setState(() {
        _extractedOcrText = ocrText;
        _ocrTextController.text = ocrText;
        _statusText = "OCR complete. Review the text below or proceed.";
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

  Future<void> _submitToServer(bool sendAsImage) async {
    if (_imageFile == null && !sendAsImage) return;

    setState(() {
      _isLoading = true;
      _statusText = sendAsImage 
          ? "Encoding image & sending base64 to server..." 
          : "Sending extracted text to server...";
    });

    try {
      String dataPayload = '';
      if (sendAsImage && _imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        dataPayload = base64Encode(bytes);
      } else {
        dataPayload = _ocrTextController.text;
      }

      final prefs = await SharedPreferences.getInstance();
      final provider = prefs.getString('active_provider') ?? 'gemini';
      final model = prefs.getString('active_model') ?? 'gemini-1.5-flash';
      final apiKey = prefs.getString('key_$provider') ?? '';

      final result = await _apiService.parseReceipt(
        data: dataPayload,
        isImage: sendAsImage,
        baseUrl: widget.apiBaseUrl,
        provider: provider,
        model: model,
        apiKey: apiKey.isNotEmpty ? apiKey : null,
      );

      if (result['success'] == true) {
        final parsedExpense = Expense.fromJson(
          result['data'],
          rawOcr: _ocrTextController.text,
          provider: result['provider'],
        );
        
        widget.onExpenseParsed(parsedExpense);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF2ECC71),
              content: Text("Parsed successfully with AI provider: ${result['provider']}"),
            ),
          );
          Navigator.pop(context);
        }
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
      child: MainScannerColumn(
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
}

// Extracted widget class to avoid nesting and keep code readable
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
          // OCR Editor view
          if (showOcrEditor) ...[
            const Text(
              "Extracted Offline Thai Text",
              style: TextStyle(color: Colors.white80, fontSize: 13, fontWeight: FontWeight.bold),
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
              style: const TextStyle(color: Colors.white50, fontSize: 11),
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

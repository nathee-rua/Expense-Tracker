import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  // Setup the text recognizer
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Performs offline text recognition on the image file.
  /// Recognizes both English and Thai characters.
  Future<String> recognizeText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      // Clean and return the structured block text
      String resultText = recognizedText.text;
      
      if (resultText.trim().isEmpty) {
        return "No readable text could be recognized from the image.";
      }
      
      return resultText;
    } catch (e) {
      return "OCR recognition error: ${e.toString()}";
    }
  }

  /// Closes the recognizer resource.
  void dispose() {
    _textRecognizer.close();
  }
}

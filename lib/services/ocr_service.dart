import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  TextRecognizer? _textRecognizer;

  TextRecognizer get _recognizer {
    _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _textRecognizer!;
  }

  /// Process image at [imagePath] and return raw recognized text.
  Future<String> processImage(String imagePath) async {
    // ML Kit is natively supported on Android and iOS devices/emulators
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final inputImage = InputImage.fromFilePath(imagePath);
        final RecognizedText recognizedText = await _recognizer.processImage(inputImage);
        return recognizedText.text;
      } catch (e) {
        throw Exception('OCR Text Recognition failed: $e');
      }
    } else {
      // Desktop / Fallback simulator for non-mobile platforms
      return '''
Highlands Coffee
Cà phê sữa đá
Tổng tiền: 45,000 đ
''';
    }
  }

  /// Close recognizer to free resources when done
  void dispose() {
    _textRecognizer?.close();
    _textRecognizer = null;
  }
}

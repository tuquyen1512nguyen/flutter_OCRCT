import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/parsed_receipt.dart';
import '../services/ocr_service.dart';
import '../services/receipt_parser.dart';

enum OcrStatus { initial, processing, success, error }

class OcrState {
  final OcrStatus status;
  final ParsedReceipt? parsedReceipt;
  final String? errorMessage;

  const OcrState({
    required this.status,
    this.parsedReceipt,
    this.errorMessage,
  });

  factory OcrState.initial() => const OcrState(status: OcrStatus.initial);
  factory OcrState.processing() => const OcrState(status: OcrStatus.processing);
  factory OcrState.success(ParsedReceipt receipt) =>
      OcrState(status: OcrStatus.success, parsedReceipt: receipt);
  factory OcrState.error(String message) =>
      OcrState(status: OcrStatus.error, errorMessage: message);
}

class OcrNotifier extends Notifier<OcrState> {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();

  @override
  OcrState build() {
    ref.onDispose(() {
      _ocrService.dispose();
    });
    return OcrState.initial();
  }

  /// Pick image from [ImageSource.camera] or [ImageSource.gallery] and run OCR pipeline
  Future<ParsedReceipt?> pickAndProcessImage(ImageSource source) async {
    try {
      state = OcrState.processing();

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) {
        state = OcrState.initial();
        return null;
      }

      return await processImagePath(image.path);
    } catch (e) {
      final errorMsg = 'Failed to select image or process OCR: $e';
      state = OcrState.error(errorMsg);
      return null;
    }
  }

  /// Run OCR pipeline on an image path directly
  Future<ParsedReceipt?> processImagePath(String imagePath) async {
    try {
      state = OcrState.processing();

      final rawText = await _ocrService.processImage(imagePath);

      if (rawText.trim().isEmpty) {
        state = OcrState.error('No text could be recognized in the image.');
        return null;
      }

      final parsedReceipt = ReceiptParser.parse(rawText, imagePath: imagePath);
      state = OcrState.success(parsedReceipt);
      return parsedReceipt;
    } catch (e) {
      final errorMsg = 'OCR Error: $e';
      state = OcrState.error(errorMsg);
      return null;
    }
  }

  void reset() {
    state = OcrState.initial();
  }
}

final ocrProvider = NotifierProvider<OcrNotifier, OcrState>(() {
  return OcrNotifier();
});

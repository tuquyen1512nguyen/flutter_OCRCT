import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../services/receipt_parser.dart';
import '../state/ocr_provider.dart';
import '../widgets/loading_overlay.dart';

class ScannerScreen extends ConsumerWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ocrState = ref.watch(ocrProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét Hóa Đơn'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Icon(
                  Icons.receipt_long_sharp,
                  size: 96,
                  color: Colors.teal,
                ),
                const SizedBox(height: 16),
                Text(
                  'Máy Quét Hóa Đơn OCR',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Chụp hoặc chọn ảnh hóa đơn để tự động trích xuất thông tin chi tiêu bằng AI OCR.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Camera Action Button
                ElevatedButton.icon(
                  onPressed: ocrState.status == OcrStatus.processing
                      ? null
                      : () => _handlePickImage(context, ref, ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 24),
                  label: const Text(
                    'Quét Hóa Đơn (Camera)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Gallery Action Button
                OutlinedButton.icon(
                  onPressed: ocrState.status == OcrStatus.processing
                      ? null
                      : () => _handlePickImage(context, ref, ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, size: 24),
                  label: const Text(
                    'Chọn Từ Thư Viện',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),

                const Spacer(),
                const Divider(),
                const SizedBox(height: 8),

                // Test Sample Receipts Section
                Text(
                  'Hóa Đơn Mẫu Thử Nghiệm (Yêu Cầu Tuần 8)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Mẫu 1 (150.000 VNĐ)'),
                      onPressed: () => _handleTestSample(
                        context,
                        'ABC MART\nSữa tươi\nBánh mì\nTổng tiền thanh toán: 150.000 VNĐ',
                      ),
                    ),
                    ActionChip(
                      label: const Text('Mẫu 2 (85,000 đ)'),
                      onPressed: () => _handleTestSample(
                        context,
                        'Cửa hàng XYZ\nNước uống\nTổng tiền: 85,000 đ\nTiền khách đưa: 100,000 đ\nTiền thừa: 15,000 đ',
                      ),
                    ),
                    ActionChip(
                      label: const Text('Mẫu 3 (1.250.000)'),
                      onPressed: () => _handleTestSample(
                        context,
                        'Shop Thời Trang Uniqlo\nÁo sơ mi\nThanh toán: 1.250.000',
                      ),
                    ),
                    ActionChip(
                      label: const Text('Mẫu 4 (Phúc Long 65.000đ)'),
                      onPressed: () => _handleTestSample(
                        context,
                        'Trà Sữa Phúc Long\nTrà đào cam sả\nKhách phải trả: 65.000đ',
                      ),
                    ),
                    ActionChip(
                      label: const Text('Mẫu 5 (Không tổng)'),
                      onPressed: () => _handleTestSample(
                        context,
                        'Cửa Hàng Tạp Hóa\nDanh sách đồ...\nChưa có dòng tổng',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Loading overlay during OCR processing
          if (ocrState.status == OcrStatus.processing)
            const LoadingOverlay(message: 'Đang đọc hóa đơn...'),
        ],
      ),
    );
  }

  Future<void> _handlePickImage(
      BuildContext context, WidgetRef ref, ImageSource source) async {
    final parsedReceipt =
        await ref.read(ocrProvider.notifier).pickAndProcessImage(source);

    if (!context.mounted) return;

    final currentState = ref.read(ocrProvider);

    if (currentState.status == OcrStatus.error && currentState.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentState.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    } else if (parsedReceipt != null) {
      context.push('/review', extra: parsedReceipt);
    }
  }

  void _handleTestSample(BuildContext context, String rawText) {
    final parsedReceipt = ReceiptParser.parse(rawText);
    context.push('/review', extra: parsedReceipt);
  }
}

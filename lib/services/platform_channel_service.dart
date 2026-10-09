import 'package:flutter/services.dart';

class PlatformChannelService {
  static const MethodChannel _platform = MethodChannel('vn.edu.vku/device_info');

  /// Fetches battery level from native Android / iOS via MethodChannel
  static Future<int> getBatteryLevel() async {
    try {
      final int? result = await _platform.invokeMethod<int>('getBatteryLevel');
      return result ?? -1;
    } on PlatformException {
      return -1;
    } catch (_) {
      return -1;
    }
  }
}

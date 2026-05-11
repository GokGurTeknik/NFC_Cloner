import 'package:flutter/services.dart';

class HceService {
  static const _channel = MethodChannel('com.example.nfc_cloner/hce');

  Future<void> startEmulation({
    required String uid,
    String? historicalBytes,
    String? hiLayerResponse,
  }) async {
    await _channel.invokeMethod('startEmulation', {
      'uid': uid.replaceAll(':', ''),
      'historicalBytes': historicalBytes ?? '',
      'hiLayerResponse': hiLayerResponse ?? '',
    });
  }

  Future<void> stopEmulation() async {
    await _channel.invokeMethod('stopEmulation');
  }

  Future<bool> isEmulationActive() async {
    return await _channel.invokeMethod<bool>('isEmulationActive') ?? false;
  }
}

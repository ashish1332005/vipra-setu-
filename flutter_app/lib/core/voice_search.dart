import 'package:flutter/services.dart';

class VoiceSearch {
  const VoiceSearch._();

  static const _channel = MethodChannel('vipra_setu/speech');

  static Future<String?> listen() async {
    try {
      final value = await _channel.invokeMethod<String>('listen');
      final text = value?.trim();
      return text == null || text.isEmpty ? null : text;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}

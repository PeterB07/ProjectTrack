import 'package:flutter/services.dart';

/// A service for handling Picture-in-Picture mode.
class PipService {
  // The method channel for platform communication.
  static const _channel = MethodChannel('org.traccar.client/pip');

  // Callback for when PiP mode changes.
  static Function(bool)? onPipModeChanged;

  /// Initializes the PiP service.
  static void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == "onPipModeChanged") {
        final isInPipMode = call.arguments as bool;
        onPipModeChanged?.call(isInPipMode);
      }
    });
  }

  /// Enters Picture-in-Picture mode.
  static Future<void> enterPipMode() async {
    try {
      // Invoke the 'enterPipMode' method on the platform side.
      await _channel.invokeMethod('enterPipMode');
    } on PlatformException catch (e) {
      // Handle any platform exceptions that may occur.
      print("Failed to enter PiP mode: '${e.message}'.");
    }
  }
}
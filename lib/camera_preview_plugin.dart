import 'dart:async';
import 'package:flutter/services.dart';

class CameraPreviewPlugin {
  static final MethodChannel _channel = MethodChannel('camera_texture');
  static final EventChannel eventChannel = EventChannel('camera_data');

  int textureId;

  bool get isInitialized => textureId != null;

  Future<int> initialize() async {
    textureId = await _channel.invokeMethod('create');

    return textureId;
  }

  Future<void> dispose() => _channel.invokeMethod('dispose');
}

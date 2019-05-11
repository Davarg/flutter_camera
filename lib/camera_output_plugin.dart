import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CameraOutputPlugin {
  static final MethodChannel _channel = MethodChannel('camera_output_texture');

  int textureId;

  bool get isInitialized => textureId != null;

  Future<int> initialize() async {
    textureId = await _channel.invokeMethod('create');

    return textureId;
  }

  Future<void> handleData(Uint8List data, Size size, int bytesPerRow) =>
      _channel.invokeMethod(
        'handle',
        {
          'buffer': data,
          'width': size.width,
          'height': size.height,
          'bytesPerRow': bytesPerRow,
        },
      );

  Future<void> dispose() => _channel.invokeMethod('dispose');
}

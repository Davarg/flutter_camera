import 'dart:async';
import 'dart:typed_data';
import 'package:camera/nalunit.dart';
import 'package:flutter/services.dart';

import './camera_method_codec.dart';

class CameraOutputPlugin {
  static final MethodChannel _channel = MethodChannel(
    'camera_output_texture',
    CameraMethodCodec(),
  );

  int textureId;

  bool get isInitialized => textureId != null;

  Future<int> initialize() async {
    textureId = await _channel.invokeMethod('create');

    return textureId;
  }

  Future<void> handleData({unit: NALUnit}) => _channel.invokeMethod(
        'handle',
        {
          'pts': unit.pts,
          'data': unit.data,
        },
      );

  Future<void> setPPS(Uint8List data) => _channel.invokeMethod(
        'setPPS',
        {
          'data': data,
        },
      );

  Future<void> setSPS(Uint8List data) => _channel.invokeMethod(
        'setSPS',
        {
          'data': data,
        },
      );

  Future<void> dispose() => _channel.invokeMethod('dispose');
}

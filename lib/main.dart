import 'dart:typed_data';

import 'package:camera/nalu_type.dart';
import 'package:flutter/material.dart';

import './camera_output_plugin.dart';
import './camera_preview_plugin.dart';
import './rtp_packer.dart';
import './rtp_unpacker.dart';
import 'nalunit.dart';

void main() => runApp(CameraApp());

class CameraApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _CameraAppState();
  }
}

class _CameraAppState extends State<CameraApp> {
  final double _previewHeight = 150.0;
  double get _previewWidth => _previewHeight / 1.333;

  final CameraPreviewPlugin _cameraPlugin = CameraPreviewPlugin();
  final CameraOutputPlugin _outputPlugin = CameraOutputPlugin();

  final RTPPacker _packer = RTPPacker();
  final RTPUnpacker _unpacker = RTPUnpacker();

  Future<void> _initializePlugin() async {
    await _cameraPlugin.initialize();
    await _outputPlugin.initialize();

    setState(() {});

    CameraPreviewPlugin.eventChannel
        .receiveBroadcastStream()
        .listen((dynamic event) {
      Map<dynamic, dynamic> data = event as Map<dynamic, dynamic>;

      _packer
          .pack(
        pts: data['pts'].toDouble(),
        data: data['data'],
      )
          .then((List<ByteData> frames) {
        for (ByteData item in frames) {
          _unpacker.unpack(item).then((List<NALUnit> units) {
            for (NALUnit unit in units) {
              switch (unit.type.type) {
                case NALUType.AVC_SPS:
                  _outputPlugin.setSPS(unit.data);
                  break;

                case NALUType.AVC_PPS:
                  _outputPlugin.setPPS(unit.data);
                  break;

                default:
                  _outputPlugin.handleData(unit: unit);
              }
            }
          });
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();

    _initializePlugin();
  }

  @override
  void dispose() {
    _cameraPlugin.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Camera'),
        ),
        body: Stack(
          children: <Widget>[
            Container(
              child: _outputPlugin.isInitialized
                  ? Texture(
                      textureId: _outputPlugin.textureId,
                    )
                  : Container(
                      color: Colors.black,
                    ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: SizedBox(
                height: _previewHeight,
                width: _previewWidth,
                child: _cameraPlugin.isInitialized
                    ? Texture(
                        textureId: _cameraPlugin.textureId,
                      )
                    : Container(
                        color: Colors.black,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

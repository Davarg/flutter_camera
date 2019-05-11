import 'package:flutter/material.dart';

import './camera_output_plugin.dart';
import './camera_preview_plugin.dart';

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

  Future<void> _initializePlugin() async {
    await _cameraPlugin.initialize();
    await _outputPlugin.initialize();

    setState(() {});

    CameraPreviewPlugin.eventChannel
        .receiveBroadcastStream()
        .listen((dynamic event) {
      Map<dynamic, dynamic> data = event as Map<dynamic, dynamic>;

      _outputPlugin.handleData(
        data['buffer'],
        Size(300, 300),
        data['bytesPerRow'],
      );
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
            SizedBox(
              height: 300,
              width: 300,
              child: _outputPlugin.isInitialized
                  ? Texture(
                      textureId: _outputPlugin.textureId,
                    )
                  : Container(
                      color: Colors.black,
                    ),
            ),
            SizedBox(
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
          ],
        ),
      ),
    );
  }
}

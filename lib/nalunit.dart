//  Original https://github.com/O2-Czech-Republic/RTPPlayer-iOS

import 'dart:typed_data';

import './nalu_type.dart';

class NALUnit {
  Uint8List data;
  double pts;

  NALUnit({this.data, this.pts});

  NALUType get type {
    return NALUType(rawValue: data.first & 0x1F);
  }

  bool get isForbiddenZeroBitSet {
    return (data.first & 0x80) == 0x80;
  }
}
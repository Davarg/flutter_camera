//  Original https://github.com/O2-Czech-Republic/RTPPlayer-iOS

import 'dart:typed_data';

import 'package:camera/nalu_type.dart';
import 'package:camera/nalunit.dart';

class NALUFragment extends NALUnit {
  int sequenceNumber;

  NALUFragment({Uint8List data, double pts, this.sequenceNumber}) : super(data: data, pts: pts);

  int get header {
    return data[1];
  }

  Uint8List get payload {
    return data.sublist(2);
  }

  @override
  NALUType get type {
    return NALUType(rawValue: header & 0x1F);
  }

  Uint8List get naluHeader {
    int nri = data[0] & 0x60;
    return Uint8List.fromList([type.type | nri]);
  }

  bool get isStartUnit {
    return (header & 0x80) == 0x80;
  }

  bool get isEndUnit {
    return (header & 0x40) == 0x40;
  }
}

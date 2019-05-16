//  Original https://github.com/O2-Czech-Republic/RTPPlayer-iOS

import 'dart:typed_data';

import 'package:camera/nalu_type.dart';

import 'nalu_fragment.dart';

class FragmentedNALU {
  List<NALUFragment> fragments = List<NALUFragment>();
  NALUType type = NALUType(rawValue: NALUType.FU);
  double pts;

  FragmentedNALU({this.pts});

  Uint8List get data {
    int lastFragmentSequence = -1;

    fragments.sort((a, b) => a.sequenceNumber.compareTo(b.sequenceNumber));
    List<NALUFragment> sortedFragments =
        fragments.where((NALUFragment fragment) {
      bool result = ((lastFragmentSequence < 0) ||
          (lastFragmentSequence == fragment.sequenceNumber - 1));

      return result;
    });

    if (!sortedFragments.first.isStartUnit) {
      return null;
    }

    if (sortedFragments.length != fragments.length) {
      return null;
    }

    int firstByte = sortedFragments.first.data[0];
    int secondByte = sortedFragments.first.data[1];
    int startByte = (firstByte & 0xE0) | (secondByte & 0x1F);

    return sortedFragments.fold(Uint8List.fromList([startByte]),
        (current, next) {
      current = current + next.data;
    });
  }

  bool get isForbiddenZeroBitSet {
    return (data[0] & 0x80) == 0x80;
  }
}

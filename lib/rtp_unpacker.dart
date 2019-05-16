//  Original https://github.com/O2-Czech-Republic/RTPPlayer-iOS

import 'dart:typed_data';

import 'package:camera/nalu_fragment.dart';
import 'package:camera/nalunit.dart';

import 'fragmented_nalu.dart';
import 'nalu_type.dart';

class _RTPUnpackerBufferUnit {
  NALUnit unit;
  int sequence;

  _RTPUnpackerBufferUnit({this.unit, this.sequence});
}

class RTPUnpacker {
  int _expectedRTPPacketSequence = -1;
  FragmentedNALU _fragmentedNALU;

  int _rtpHeaderLength = 12;
  int _rtpVersion = 0x02;
  int _videoPayloadType = 96;

  int _bufferTreshold = 5;
  List<_RTPUnpackerBufferUnit> _buffer = List<_RTPUnpackerBufferUnit>();

  final int _shortMax = 0xFFFF;

  Future<List<NALUnit>> unpack(ByteData data) async {
    bool isRTP = ((data.getUint8(0) & 0xC0) >> 6) == _rtpVersion;

    if (isRTP) {
      bool isVideo = (data.getUint8(1) & 0x7F) == _videoPayloadType;

      if (isVideo) {
        ByteData packetHeader = ByteData.view(
          Uint8List.fromList(
            data.buffer.asUint8List().sublist(0, _rtpHeaderLength),
          ).buffer,
        );

        int sequence = packetHeader.getUint16(2);
        int timestamp = packetHeader.getUint32(4);
        Uint8List payload = Uint8List.fromList(
          data.buffer.asUint8List().sublist(_rtpHeaderLength),
        );

        NALUnit nalUnit = NALUnit(data: payload, pts: timestamp.toDouble());

        _RTPUnpackerBufferUnit unit =
            _RTPUnpackerBufferUnit(unit: nalUnit, sequence: sequence);

        if (_expectedRTPPacketSequence < 0) {
          _expectedRTPPacketSequence = (sequence + 1) & _shortMax;

          NALUnit handledUnit = _handle(unit);
          if (handledUnit != null) {
            return [handledUnit];
          } else {
            return null;
          }
        }

        if ((sequence < _expectedRTPPacketSequence) &&
            (_expectedRTPPacketSequence < (_shortMax - _bufferTreshold)) &&
            (sequence <= _bufferTreshold)) {
          return null;
        }

        if (sequence == _expectedRTPPacketSequence) {
          _expectedRTPPacketSequence = (sequence + 1) & _shortMax;

          NALUnit handledUnit = _handle(unit);
          if (handledUnit != null) {
            return [handledUnit];
          } else {
            return null;
          }
        }

        _buffer.add(unit);
        _buffer.sort((a, b) => a.sequence.compareTo(b.sequence));

        if ((_buffer.first.sequence == _expectedRTPPacketSequence) ||
            (_buffer.length >= _bufferTreshold)) {
          List<NALUnit> result = List<NALUnit>();

          do {
            _RTPUnpackerBufferUnit u = _buffer.removeAt(0);
            _expectedRTPPacketSequence = (u.sequence + 1) & _shortMax;

            NALUnit handledUnit = _handle(u);
            if (handledUnit != null) {
              result.add(handledUnit);
            }
          } while ((_buffer.first.sequence == _expectedRTPPacketSequence) ||
              (_buffer.length >= _bufferTreshold));

          return result;
        }
      }
    }

    return null;
  }

  NALUnit _handle(_RTPUnpackerBufferUnit unit) {
    if (unit.unit.type.type == NALUType.AVC_RTP_FU_A) {
      if (_fragmentedNALU == null) {
        _fragmentedNALU = FragmentedNALU(pts: unit.unit.pts);
      }

      NALUFragment fragment = NALUFragment(
        data: unit.unit.data,
        pts: unit.unit.pts,
        sequenceNumber: unit.sequence,
      );
      _fragmentedNALU.fragments.add(fragment);

      if (_fragmentedNALU.pts.compareTo(unit.unit.pts) != 0) {
        Uint8List d = _fragmentedNALU.data;
        NALUnit result;

        if (d != null) {
          result = NALUnit(data: d, pts: _fragmentedNALU.pts);
        }

        _fragmentedNALU = FragmentedNALU(pts: unit.unit.pts);

        return result;
      } else {
        Uint8List d = _fragmentedNALU.data;
        NALUnit result;

        if (d != null) {
          result = NALUnit(data: d, pts: _fragmentedNALU.pts);
        }

        _fragmentedNALU = null;

        return result;
      }
    } else {
      return unit.unit;
    }
  }
}

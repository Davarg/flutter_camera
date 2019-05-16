import 'dart:math';
import 'dart:typed_data';

class RTPPacker {
  int _sequence = 1;
  final int _ssi = Random().nextInt(0xFFFFFFFF);
  final int _shortMax = 0xFFFF;
  final int _int32Max = 0xFFFFFFFF;

  Future<List<ByteData>> pack({pts: double, data: Uint8List}) async {
    const int headerLength = 12;
    ByteData rtpHeader = ByteData(headerLength);

    const int rtpVersion = 128;
    rtpHeader.setUint8(0, rtpVersion);

    const int payloadType = 96;
    rtpHeader.setUint8(1, payloadType);

    rtpHeader.setUint16(2, _sequence);

    int timestamp = ((pts * 90.0).toInt() % _int32Max);
    rtpHeader.setUint32(4, timestamp);

    rtpHeader.setUint32(8, _ssi);

    int nalUnitLength = data.elementSizeInBytes;
    const int udpPacketLength = 4096;
    const int treshold = 200;
    if (nalUnitLength <= (udpPacketLength - treshold)) {
      if (_sequence == _shortMax) {
        _sequence = 1;
      } else {
        _sequence++;
      }

      rtpHeader.setUint8(1, (payloadType | 0x80));

      return List<ByteData>.filled(
          1,
          ByteData.view(
              Uint8List.fromList((rtpHeader.buffer.asUint8List() + data))
                  .buffer));
    } else {
      //https://tools.ietf.org/html/rfc3984#section-5.8

      List<ByteData> result = List<ByteData>();

      int firstByte = data[0];
      data.removeAt(0);
      nalUnitLength--;

      const int fuaIndicatorLength = 1;
      const int fuaHeaderLength = 1;

      int fuaIndicator = ((firstByte & 0x60) & 0xFF) | 28;
      int fuaHeaderStart = ((firstByte & 0x1F) | 0x80) & ~(0x40);
      int fuaHeaderMiddle = ((firstByte & 0x1F) & ~(0x80)) & ~(0x40);
      int fuaHeaderEnd = ((firstByte & 0x1F) & ~(0x80)) | 0x40;

      int sum = 0;
      while (sum < nalUnitLength) {
        int limit = ((udpPacketLength - treshold) - headerLength) -
            (fuaIndicatorLength + fuaHeaderLength);
        int length =
            nalUnitLength - sum > limit ? limit : (nalUnitLength - sum);

        Uint8List splitData = data.sublist(sum, length);

        sum += length;

        if (sum >= nalUnitLength) {
          rtpHeader.setUint8(1, (payloadType | 0x80));

          ByteData fua = ByteData((fuaIndicatorLength + fuaHeaderLength));
          fua.setUint8(0, fuaIndicator);
          fua.setUint8(1, fuaHeaderEnd);

          ByteData frame = ByteData.view(Uint8List.fromList(
                  rtpHeader.buffer.asUint8List() +
                      fua.buffer.asUint8List() +
                      splitData)
              .buffer);

          result.add(frame);

          break;
        } else {
          if ((sum - length) == 0) {
            ByteData fua = ByteData((fuaIndicatorLength + fuaHeaderLength));
            fua.setUint8(0, fuaIndicator);
            fua.setUint8(1, fuaHeaderStart);

            ByteData frame = ByteData.view(Uint8List.fromList(
                    rtpHeader.buffer.asUint8List() +
                        fua.buffer.asUint8List() +
                        splitData)
                .buffer);

            result.add(frame);
          } else {
            ByteData fua = ByteData((fuaIndicatorLength + fuaHeaderLength));
            fua.setUint8(0, fuaIndicator);
            fua.setUint8(1, fuaHeaderMiddle);

            ByteData frame = ByteData.view(Uint8List.fromList(
                    rtpHeader.buffer.asUint8List() +
                        fua.buffer.asUint8List() +
                        splitData)
                .buffer);

            result.add(frame);
          }
        }
      }

      return result;
    }
  }
}

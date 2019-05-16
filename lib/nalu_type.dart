//  Original https://github.com/O2-Czech-Republic/RTPPlayer-iOS

// There are 2 basic types of NAL units:
//      - VCL (video coding layer) carry image information
//      - non-VCL carry metadata, most notably
//          - Video parameter set (VPS) - only HEVC/H.265
//          - Picture parameter set (PPS)
//          - Sequence parameter set (SPS)
class NALUType {
  int type;

  bool operator ==(dynamic other) {
    if (other is NALUType) {
      if (other.type == type) {
        return true;
      } 
    }
    return false;
  }

  NALUType({int rawValue}) {
    switch (rawValue) {
      case FU:
        type = NALUType.FU;
        break;

      case AVC_SEI:
        type = NALUType.AVC_SEI;
        break;

      case AVC_SPS:
        type = NALUType.AVC_SPS;
        break;

      case AVC_PPS:
        type = NALUType.AVC_PPS;
        break;

      case AVC_AUD:
        type = NALUType.AVC_AUD;
        break;

      case AVC_VCL_ISLICEA:
        type = NALUType.AVC_VCL_ISLICEA;
        break;

      case AVC_VCL_ISLICEB:
        type = NALUType.AVC_VCL_ISLICEB;
        break;

      case AVC_VCL_ISLICEC:
        type = NALUType.AVC_VCL_ISLICEC;
        break;

      case AVC_VCL_ISLICE_IDR:
        type = NALUType.AVC_VCL_ISLICE_IDR;
        break;

      case AVC_RTP_FU_A:
        type = NALUType.AVC_RTP_FU_A;
        break;

      case AVC_RTP_FU_B:
        type = NALUType.AVC_RTP_FU_B;
        break;

      case HEVC_VPS:
        type = NALUType.HEVC_VPS;
        break;

      case HEVC_SPS:
        type = NALUType.HEVC_SPS;
        break;

      case HEVC_PPS:
        type = NALUType.HEVC_PPS;
        break;

      case HEVC_AUD:
        type = NALUType.HEVC_AUD;
        break;

      case HEVC_SEI:
        type = NALUType.HEVC_SEI;
        break;

      case HEVC_AP:
        type = NALUType.HEVC_AP;
        break;

      case HEVC_FU:
        type = NALUType.HEVC_FU;
        break;

      case HEVC_PACI:
        type = NALUType.HEVC_PACI;
        break;

      case HEVC_VCL_BLA_W_LP:
        type = NALUType.HEVC_VCL_BLA_W_LP;
        break;

      case HEVC_VCL_BLA_W_RADL:
        type = NALUType.HEVC_VCL_BLA_W_RADL;
        break;

      case HEVC_VCL_BLA_N_LP:
        type = NALUType.HEVC_VCL_BLA_N_LP;
        break;

      case HEVC_VCL_IDR_W_RADL:
        type = NALUType.HEVC_VCL_IDR_W_RADL;
        break;

      case HEVC_VCL_IDR_N_LP:
        type = NALUType.HEVC_VCL_IDR_N_LP;
        break;

      case HEVC_VCL_CRA:
        type = NALUType.HEVC_VCL_CRA;
        break;

      case NALUType.VCL:
      default:
        type = NALUType.VCL;
    }
  }

  static const int FU = 255;

  // AVC non-VCL types for H.264 decoding
  static const int AVC_SEI = 6;
  static const int AVC_SPS = 7;
  static const int AVC_PPS = 8;
  static const int AVC_AUD = 9;

  // AVC VCL types of reference pictures
  static const int AVC_VCL_ISLICEA = 2;
  static const int AVC_VCL_ISLICEB = 3;
  static const int AVC_VCL_ISLICEC = 4;
  static const int AVC_VCL_ISLICE_IDR = 5;

  // RTP H.264 Fragmentation Units (RFC 6184)
  static const int AVC_RTP_FU_A = 28;
  static const int AVC_RTP_FU_B = 29;

  // HEVC NAL types for H.265 decoding
  static const int HEVC_VPS = 32; // Video Parameter Set
  static const int HEVC_SPS = 33; // Sequence Parameter Set
  static const int HEVC_PPS = 34; // Picture Parameter Set
  static const int HEVC_AUD = 35; // Access Unit Delimiter
  static const int HEVC_SEI = 39; // Supplemental Enhancement Information
  static const int HEVC_AP =
      48; // RTP Aggregation Packet as per https://tools.ietf.org/html/draft-ietf-payload-rtp-h265-15#section-4.4.2
  static const int HEVC_FU =
      49; // RTP Fragmentation Unit as per https://tools.ietf.org/html/draft-ietf-payload-rtp-h265-15#section-4.4.3
  static const int HEVC_PACI = 50; // Payload Content Information

  // HEVC VCL types of reference pictures
  static const int HEVC_VCL_BLA_W_LP = 16;
  static const int HEVC_VCL_BLA_W_RADL = 17;
  static const int HEVC_VCL_BLA_N_LP = 18;
  static const int HEVC_VCL_IDR_W_RADL = 19;
  static const int HEVC_VCL_IDR_N_LP = 20;
  static const int HEVC_VCL_CRA = 21;

  // Default type for frame data slice (VCL)
  static const int VCL = 0;
}

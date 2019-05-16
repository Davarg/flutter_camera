//
//  VideoDecompressor.swift
//  Runner
//
//  Created by Alex Makushkin on 5/16/19.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

import UIKit
import VideoToolbox

class VideoDecompressor: NSObject {
    weak var delegate: VideoDecompressorDelegate?
    
    private let avccPrefixLength: Int32 = 4
    
    private var session: VTDecompressionSession?
    private var queue: DispatchQueue!
    
    private var pps: NSData?
    private var sps: NSData?
    
    private var formatDescription: CMFormatDescription?
    
    //MARK: - Callback
    private var callback: VTDecompressionOutputCallback = { (selfPointer, sourceFrame, status, flags, imgBuffer, pts, duration) in
        if let sp = selfPointer {
            let wSelf = Unmanaged<VideoDecompressor>.fromOpaque(sp).takeUnretainedValue()
            
            guard imgBuffer != nil else {
                print("<VideoDecompressor>: no image buffer received from decoder, status code \(status)")
                return
            }
            
            var timingInfo = CMSampleTimingInfo(duration: kCMTimeIndefinite,
                                                presentationTimeStamp: pts,
                                                decodeTimeStamp: kCMTimeInvalid)
            
            var format: CMVideoFormatDescription? = nil
            CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault,
                                                         imgBuffer!,
                                                         &format)
            
            guard let f = format else {
                print("<VideoDecompressor>: can't create format")
                return
            }
            
            var sampleBuffer: CMSampleBuffer? = nil
            CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault,
                                               imgBuffer!,
                                               true,
                                               nil,
                                               nil,
                                               f,
                                               &timingInfo,
                                               &sampleBuffer)
            wSelf.delegate?.decodedData(sampleBuffer)
        }
    }
    
    private var callBackRecord: VTDecompressionOutputCallbackRecord?
    
    //MARK: - Life Cycle
    override init() {
        super.init()
        
        self.initQueue()
    }
    
    deinit {
        if let s = self.session {
            VTDecompressionSessionInvalidate(s)
        }
    }
    
    //MARK: -
    private func initQueue() {
        self.queue = DispatchQueue(label: "VideoDecompressor",
                                   qos: DispatchQoS.background)
    }
    
    private func initSession() {
        if self.session == nil {
            if let pps = self.pps
                , let sps = self.sps {
                let parameterSetPointers = Array<UnsafePointer<UInt8>>(arrayLiteral: sps.bytes.bindMemory(to: UInt8.self, capacity: sps.length),
                                                                       pps.bytes.bindMemory(to: UInt8.self, capacity: pps.length))
                let parameterSetSizes = Array<Int>(arrayLiteral: sps.length, pps.length)
                
                guard CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                          parameterSetPointers.count,
                                                                          parameterSetPointers,
                                                                          parameterSetSizes,
                                                                          self.avccPrefixLength,
                                                                          &self.formatDescription) == noErr else {
                                                                            print("<VideoDecompressor>: can't create format description")
                                                                            return
                }
                
                self.callBackRecord = VTDecompressionOutputCallbackRecord(decompressionOutputCallback: self.callback,
                                                                          decompressionOutputRefCon: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
                guard var cbr = self.callBackRecord else {
                    return
                }
                
                guard VTDecompressionSessionCreate(kCFAllocatorDefault,
                                                   self.formatDescription!,
                                                   NSMutableDictionary(),
                                                   [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA] as NSMutableDictionary,
                                                   &cbr,
                                                   &self.session) == noErr else {
                                                    print("<VideoDecompressor>: can't create session")
                                                    return
                }
                
                print("<VideoDecompressor>: inited session")
            }
        }
    }
    
    func setPPS(_ data: NSData) {
        if self.pps == nil {
            self.pps = data
            
            if self.sps != nil {
                self.initSession()
            }
        }
    }
    
    func setSPS(_ data: NSData) {
        if self.sps == nil {
            self.sps = data
            
            if self.pps != nil {
                self.initSession()
            }
        }
    }
    
    func decode(_ data: NSData, pts: Double) {
        guard let fd = self.formatDescription else {
            print("<VideoDecompressor>: can't get format description")
            return
        }
        
        guard let session = self.session else {
            print("<VideoDecompressor>: can't get session")
            return
        }
        
        var blockBuffer: CMBlockBuffer? = nil
        guard CMBlockBufferCreateEmpty(kCFAllocatorDefault,
                                       0,
                                       kCMBlockBufferPermitEmptyReferenceFlag,
                                       &blockBuffer) == noErr else {
                                        print("<VideoDecompressor>: can't allocate block buffer")
                                        return
        }
        
        guard CMBlockBufferAppendMemoryBlock(blockBuffer!,
                                             nil,
                                             Int(self.avccPrefixLength),
                                             kCFAllocatorDefault,
                                             nil,
                                             0,
                                             Int(self.avccPrefixLength),
                                             0) == noErr else {
                                                print("<VideoDecompressor>: can't append memory to block")
                                                return
        }
        
        var avccPrefix = CFSwapInt32HostToBig(UInt32(data.length))
        guard CMBlockBufferReplaceDataBytes(&avccPrefix,
                                            blockBuffer!,
                                            0,
                                            Int(self.avccPrefixLength)) == noErr else {
                                                print("<VideoDecompressor>: can't replace prefix in block")
                                                return
        }
        
        guard CMBlockBufferAppendMemoryBlock(blockBuffer!,
                                             UnsafeMutableRawPointer(mutating: data.bytes),
                                             data.length,
                                             kCFAllocatorNull,
                                             nil,
                                             0,
                                             data.length,
                                             0) == noErr else {
                                                print("<VideoDecompressor>: can't append payload")
                                                return
        }
        
        var timingInfo = CMSampleTimingInfo(duration: kCMTimeIndefinite,
                                            presentationTimeStamp: CMTimeMake(Int64(pts), 90000),
                                            decodeTimeStamp: kCMTimeInvalid)
        var sampleSize = [CMBlockBufferGetDataLength(blockBuffer!)]
        
        var sampleBuffer: CMSampleBuffer? = nil
        CMSampleBufferCreate(kCFAllocatorDefault,
                             blockBuffer!,
                             true,
                             nil,
                             nil,
                             fd,
                             1,
                             1,
                             &timingInfo,
                             1,
                             &sampleSize,
                             &sampleBuffer)
        
        var infoFlags = VTDecodeInfoFlags(rawValue: 0)
        VTDecompressionSessionDecodeFrame(session,
                                          sampleBuffer!,
                                          [._1xRealTimePlayback, ._EnableAsynchronousDecompression],
                                          nil,
                                          &infoFlags)
    }
    
    func stop() {
        if let s = self.session {
            VTDecompressionSessionFinishDelayedFrames(s)
            VTDecompressionSessionInvalidate(s)
            self.session = nil
            self.formatDescription = nil
            self.pps = nil
            self.sps = nil
            
            self.initQueue()
        }
    }
}

//
//  VideoCompressor.swift
//  Runner
//
//  Created by Alex Makushkin on 5/14/19.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

import UIKit
import VideoToolbox

class VideoCompressor: NSObject {
    weak var delegate: VideoCompressorDelegate?
    
    private var session: VTCompressionSession?
    private var bitrate = (200 * 1024)
    private var queue: DispatchQueue!
    
    private let videoWidth: Int32 = 240
    private let videoHeight: Int32 = 320
    
    //MARK: - Callback
    private var callback: VTCompressionOutputCallback = { (selfPointer, sourceFrame, status, flags, buffer) in
        if status != noErr {
            print("<VideoCompressor>: ~Callback~ error \(status)")
            
            return
        }
        
        guard let sampleBuffer = buffer else {
            print("<VideoCompressor>: ~Callback~ sample buffer is empty")
            
            return
        }
        
        if CMSampleBufferDataIsReady(sampleBuffer) == false {
            print("<VideoCompressor>: ~Callback~ data is not ready")
            
            return
        }
        
        guard let sp = selfPointer else {
            print("<VideoCompressor>: ~Callback~ can't get reference to self")
            
            return
        }
        let wSelf: VideoCompressor = Unmanaged.fromOpaque(sp).takeUnretainedValue()
        let pts = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
        
        if let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true) {
            let rawDic: UnsafeRawPointer = CFArrayGetValueAtIndex(attachments, 0)
            let dic: CFDictionary = Unmanaged.fromOpaque(rawDic).takeUnretainedValue()
            
            if CFDictionaryContainsKey(dic, Unmanaged.passUnretained(kCMSampleAttachmentKey_NotSync).toOpaque()) == false {
                if let format = CMSampleBufferGetFormatDescription(sampleBuffer) {
                    var spsSize = 0
                    var spsCount = 0
                    var nalHeaderLength: Int32 = 0
                    var sps: UnsafePointer<UInt8>? = nil
                    
                    let spsResult = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format,
                                                                                       0,
                                                                                       &sps,
                                                                                       &spsSize,
                                                                                       &spsCount,
                                                                                       &nalHeaderLength)
                    if spsResult == noErr {
                        let spsData = NSData(bytes: sps, length: spsSize)
                        
                        var ppsSize = 0
                        var ppsCount = 0
                        var pps: UnsafePointer<UInt8>? = nil
                        
                        let ppsResult = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format,
                                                                                           1,
                                                                                           &pps,
                                                                                           &ppsSize,
                                                                                           &ppsCount,
                                                                                           &nalHeaderLength)
                        if ppsResult == noErr {
                            let ppsData = NSData(bytes: pps, length: ppsSize)
                            
                            wSelf.delegate?.encodedData((CMTimeGetSeconds(pts) * 1000.0), data: spsData)
                            wSelf.delegate?.encodedData((CMTimeGetSeconds(pts) * 1000.0), data: ppsData)
                        } else {
                            print("<VideoCompressor>: ~Callback~ pps error \(ppsResult)")
                        }
                    } else {
                        print("<VideoCompressor>: ~Callback~ sps error \(spsResult)")
                    }
                }
            }
            
            guard let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
                print("<VideoCompressor>: ~Callback~ can't get data buffer")
                
                return
            }
            
            var lengthAtOffsetOut = 0
            var totalLengthOut = 0
            var dataPointer: UnsafeMutablePointer<Int8>? = nil
            var blockBufferResult = CMBlockBufferGetDataPointer(dataBuffer,
                                                                0,
                                                                &lengthAtOffsetOut,
                                                                &totalLengthOut,
                                                                &dataPointer)
            if blockBufferResult == noErr {
                var bufferOffset = 0
                let avccHeaderLength = 4
                
                while bufferOffset < (totalLengthOut - avccHeaderLength) {
                    var nalUnitLength: UInt32 = 0
                    
                    memcpy(&nalUnitLength, dataPointer?.advanced(by: bufferOffset), avccHeaderLength)
                    nalUnitLength = CFSwapInt32BigToHost(nalUnitLength)
                    
                    let data = NSData(bytes: dataPointer?.advanced(by: bufferOffset + avccHeaderLength),
                                      length: Int(nalUnitLength))
                    
                    wSelf.delegate?.encodedData((CMTimeGetSeconds(pts) * 1000.0), data: data)
                    
                    bufferOffset += (Int(nalUnitLength) + avccHeaderLength)
                }
            } else {
                print("<VideoCompressor>: ~Callback~ block buffer error \(blockBufferResult)")
            }
        }
    }
    
    //MARK: - Life Cycle
    override init() {
        super.init()
        
        self.initQueue()
    }
    
    deinit {
        if let s = self.session {
            VTCompressionSessionInvalidate(s)
        }
    }
    
    //MARK: -
    private func initQueue() {
        self.queue = DispatchQueue(label: "VideoCompressorQueue",
                                   qos: .background)
    }
    
    func encode(_ buffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else {
            return
        }
        
        if self.session == nil {
            VTCompressionSessionCreate(kCFAllocatorDefault,
                                       self.videoWidth,
                                       self.videoHeight,
                                       kCMVideoCodecType_H264,
                                       nil,
                                       nil,
                                       nil,
                                       self.callback,
                                       UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
                                       &self.session)
            
            guard let s = self.session else {
                return
            }
            
            let dic = [kVTCompressionPropertyKey_ProfileLevel: kVTProfileLevel_H264_Main_AutoLevel,
                       kVTCompressionPropertyKey_RealTime: true,
                       kVTCompressionPropertyKey_AverageBitRate: self.bitrate] as CFDictionary
            VTSessionSetProperties(s, dic)
            
            VTCompressionSessionPrepareToEncodeFrames(s)
        }
        
        guard let s = self.session else {
            return
        }
        
        self.queue.sync {
            //ReadWrite
            pixelBuffer.lock(withFlag: CVPixelBufferLockFlags(rawValue: 0), handler: {
                let presTime = CMSampleBufferGetOutputPresentationTimeStamp(buffer)
                let duration = CMSampleBufferGetOutputDuration(buffer)
                
                VTCompressionSessionEncodeFrame(s,
                                                pixelBuffer,
                                                presTime,
                                                duration,
                                                nil,
                                                nil,
                                                nil)
            })
        }
    }
    
    func stop() {
        if let s = self.session {
            VTCompressionSessionCompleteFrames(s, kCMTimeInvalid)
            VTCompressionSessionInvalidate(s)
            self.session = nil
            
            self.initQueue()
        }
    }
}

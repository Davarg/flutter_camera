//
//  CameraOutputPlugin.swift
//  Runner
//
//  Created by Александр Макушкин on 11/05/2019.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

import UIKit
import Flutter
import AVFoundation

class CameraOutputPlugin: NSObject {
    private var registry: FlutterTextureRegistry!
    private var output: CameraOutput!
    private var textureId: Int64 = -1
    
    convenience init(withRegistry registry: FlutterTextureRegistry) {
        self.init()
        
        self.registry = registry
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "create":
            self.output = CameraOutput()
            
            self.textureId = self.registry.register(self.output)
            
            result(self.textureId)
            
        case "handle":
            if let args = call.arguments as? Dictionary<String, Any> {
                if let buffer = args["buffer"] as? FlutterStandardTypedData
                    , let width = args["width"] as? Double
                    , let height = args["height"] as? Double
                    , let bytesPerRow = args["bytesPerRow"] as? Int {
                    var result: CVPixelBuffer? = nil
                    var b = buffer.data as NSData
                    
                    let dic = Dictionary<String, Any>()
                    CVPixelBufferCreate(kCFAllocatorDefault,
                                        Int(width),
                                        Int(height),
                                        kCVPixelFormatType_32BGRA,
                                        [kCVPixelBufferIOSurfacePropertiesKey: dic] as CFDictionary,
                                        &result)
                    
                    if let r = result {
                        CVPixelBufferLockBaseAddress(r, CVPixelBufferLockFlags(rawValue: 0))
                        
                        if let baseAddress = CVPixelBufferGetBaseAddress(r) {
                            memcpy(baseAddress, b.bytes, b.length)
                        }
                        
                        CVPixelBufferUnlockBaseAddress(r, CVPixelBufferLockFlags(rawValue: 0))
                    }
                    
                    self.output.latestPixelBuffer = result
                    
                    self.registry.textureFrameAvailable(self.textureId)
                }
            }
            
            result(nil)
            
        case "dispose":
            self.registry.unregisterTexture(self.textureId)
            
            result(nil)
            
        default:
            result(nil)
        }
    }
}

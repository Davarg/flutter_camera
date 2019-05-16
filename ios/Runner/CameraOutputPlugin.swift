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

class CameraOutputPlugin: NSObject, VideoDecompressorDelegate {
    private var registry: FlutterTextureRegistry!
    private var output: CameraOutput!
    private var textureId: Int64 = -1
    private let decompressor = VideoDecompressor()
    
    convenience init(withRegistry registry: FlutterTextureRegistry) {
        self.init()
        
        self.registry = registry
        self.decompressor.delegate = self
    }
    
    func decodedData(_ data: CMSampleBuffer?) {
        if let d = data {
            if let imageBuffer = CMSampleBufferGetImageBuffer(d) {
                self.output.latestPixelBuffer = imageBuffer as CVPixelBuffer
                self.registry.textureFrameAvailable(self.textureId)
            }
        }
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setPPS":
            if let args = call.arguments as? Dictionary<String, Any> {
                if let buffer = args["data"] as? FlutterStandardTypedData {
                    self.decompressor.setPPS(buffer.data as NSData)
                }
            }
            
        case "setSPS":
            if let args = call.arguments as? Dictionary<String, Any> {
                if let buffer = args["data"] as? FlutterStandardTypedData {
                    self.decompressor.setSPS(buffer.data as NSData)
                }
            }
            
        case "create":
            self.output = CameraOutput()
            
            self.textureId = self.registry.register(self.output)
            
            result(self.textureId)
            
        case "handle":
            if let args = call.arguments as? Dictionary<String, Any> {
                if let buffer = args["data"] as? FlutterStandardTypedData
                    , let pts = args["pts"] as? Double {
                    self.decompressor.decode(buffer.data as NSData, pts: pts)
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

//
//  CameraPreviewPlugin.swift
//  Runner
//
//  Created by Александр Макушкин on 11/05/2019.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

import UIKit
import Flutter

class CameraPreviewPlugin: NSObject {
    private var registry: FlutterTextureRegistry!
    private var messenger: FlutterBinaryMessenger!
    private var camera: CameraPreview!
    private var textureId: Int64 = -1
    
    convenience init(withRegistry registry: FlutterTextureRegistry,
                     messenger: FlutterBinaryMessenger) {
        self.init()
        
        self.messenger = messenger
        self.registry = registry
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "create":
            self.camera = CameraPreview(withMessenger: self.messenger)
            
            self.textureId = self.registry.register(self.camera)
            self.camera.onFrameAvailable = {
                self.registry.textureFrameAvailable(self.textureId)
            }
            
            self.camera.start()
            
            result(self.textureId)
            
        case "dispose":
            self.registry.unregisterTexture(self.textureId)
            
            self.camera.stop()
            
            result(nil)
            
        default:
            result(nil)
        }
    }
}

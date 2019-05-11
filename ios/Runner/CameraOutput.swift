//
//  CameraOutput.swift
//  Runner
//
//  Created by Александр Макушкин on 11/05/2019.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

import UIKit
import Flutter

class CameraOutput: NSObject, FlutterTexture {
    var latestPixelBuffer: CVPixelBuffer? = nil
    
    func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        if let buffer = self.latestPixelBuffer {
            return Unmanaged<CVPixelBuffer>.passRetained(buffer)
        } else {
            return nil
        }
    }
}

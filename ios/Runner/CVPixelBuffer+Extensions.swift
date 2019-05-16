//
//  CVPixelBuffer+Extensions.swift
//  Runner
//
//  Created by Alex Makushkin on 5/14/19.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

import UIKit
import VideoToolbox

extension CVPixelBuffer {
    func lock(withFlag flag: CVPixelBufferLockFlags, handler: (() -> Void)? = nil) {
        if CVPixelBufferLockBaseAddress(self, flag) == kCVReturnSuccess {
            handler?()
        }
        
        CVPixelBufferUnlockBaseAddress(self, flag)
    }
}

//
//  VideoDecompressorDelegate.swift
//  Runner
//
//  Created by Alex Makushkin on 5/16/19.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

import UIKit

protocol VideoDecompressorDelegate: NSObjectProtocol {
    func decodedData(_ data: CMSampleBuffer?)
}

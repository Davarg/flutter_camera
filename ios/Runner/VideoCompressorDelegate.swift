//
//  VideoCompressorDelegate.swift
//  Runner
//
//  Created by Alex Makushkin on 5/14/19.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

import UIKit

protocol VideoCompressorDelegate: NSObjectProtocol {
    func encodedData(_ pts: Double, data: NSData)
}

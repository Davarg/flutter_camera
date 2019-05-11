//
//  CameraPreview.swift
//  Runner
//
//  Created by Александр Макушкин on 11/05/2019.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

import UIKit
import Flutter
import AVFoundation

class CameraPreview: NSObject, FlutterTexture, AVCaptureVideoDataOutputSampleBufferDelegate, FlutterStreamHandler {
    var onFrameAvailable: (() -> Void)? = nil
    
    private var eventSink: FlutterEventSink? = nil
    
    private var eventChannel: FlutterEventChannel? = nil
    private let videoOutput = AVCaptureVideoDataOutput()
    private let captureSession = AVCaptureSession()
    
    private var latestPixelBuffer: CVPixelBuffer? = nil
    
    convenience init(withMessenger messenger: FlutterBinaryMessenger) {
        self.init()
        
        self.eventChannel = FlutterEventChannel(name: "camera_data",
                                                binaryMessenger: messenger)
        self.eventChannel?.setStreamHandler(self)
    }
    
    func onListen(withArguments arguments: Any?,
                  eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        
        return nil
    }
    
    private func createSession() {
        self.captureSession.sessionPreset = AVCaptureSession.Preset.medium
        
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                                mediaType: .video,
                                                                position: .front)
        
        guard let videoCaptureDevice = discoverySession.devices.first else {
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if self.captureSession.canAddInput(videoInput) == true {
            self.captureSession.addInput(videoInput)
        } else {
            return
        }
        
        self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        if self.captureSession.canAddOutput(self.videoOutput) == true {
            self.captureSession.addOutput(self.videoOutput)
        } else {
            return
        }
        
        self.videoOutput.setSampleBufferDelegate(self,
                                                 queue: DispatchQueue.global())
    }
    
    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async {
                self.createSession()
                self.captureSession.startRunning()
            }
            
        case .denied:
            fallthrough
        case .restricted:
            ()
            
        case .notDetermined:
            fallthrough
        default:
            AVCaptureDevice.requestAccess(for: .video,
                                          completionHandler: { [weak self] isGranted in
                                            if isGranted == true {
                                                DispatchQueue.main.async {
                                                    self?.createSession()
                                                    self?.captureSession.startRunning()
                                                }
                                            }
            })
        }
    }
    
    func stop() {
        self.captureSession.stopRunning()
    }
    
    func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        if let buffer = self.latestPixelBuffer {
            return Unmanaged<CVPixelBuffer>.passRetained(buffer)
        } else {
            return nil
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        connection.videoOrientation = .portrait
        connection.isVideoMirrored = true
        
        if let newBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let bytesPerRow = CVPixelBufferGetBytesPerRow(newBuffer)
            CVPixelBufferLockBaseAddress(newBuffer, CVPixelBufferLockFlags(rawValue: 0))
            
            if let baseAddress = CVPixelBufferGetBaseAddress(newBuffer) {
                let length = CVPixelBufferGetDataSize(newBuffer)
                
                let data = Data(bytes: baseAddress, count: length)
                let flutterData = FlutterStandardTypedData(bytes: data)
                
                self.eventSink?(["bytesPerRow": bytesPerRow,
                                 "buffer": flutterData])
            }
            
            CVPixelBufferUnlockBaseAddress(newBuffer, CVPixelBufferLockFlags(rawValue: 0))
            
            self.latestPixelBuffer = newBuffer as CVPixelBuffer
            self.onFrameAvailable?()
        }
    }
}

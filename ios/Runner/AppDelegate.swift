import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private var cameraPlugin: CameraPreviewPlugin!
    private var channelCamera: FlutterMethodChannel!
    
    private var outputPlugin: CameraOutputPlugin!
    private var channelOutput: FlutterMethodChannel!
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
        ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        
        let registrar = self.registrar(forPlugin: "xyz.amakushkin.camera")
        self.initPlugins(registrar)
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func initPlugins(_ registrar: FlutterPluginRegistrar) {
        self.channelCamera = FlutterMethodChannel(name: "camera_texture",
                                                  binaryMessenger: registrar.messenger())
        
        self.cameraPlugin = CameraPreviewPlugin(withRegistry: registrar.textures(),
                                                messenger: registrar.messenger())
        self.channelCamera.setMethodCallHandler { (call, result) in
            self.cameraPlugin.handle(call, result: result)
        }
        
        self.channelOutput = FlutterMethodChannel(name: "camera_output_texture",
                                                  binaryMessenger: registrar.messenger())
        
        self.outputPlugin = CameraOutputPlugin(withRegistry: registrar.textures())
        self.channelOutput.setMethodCallHandler { (call, result) in
            self.outputPlugin.handle(call, result: result)
        }
    }
}

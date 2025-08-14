import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    // The controller for Picture-in-Picture mode.
    private var pipController: PipController?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Get the Flutter view controller.
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        // Create a method channel for platform communication.
        let pipChannel = FlutterMethodChannel(name: "org.traccar.client/pip",
                                              binaryMessenger: controller.binaryMessenger)
        // Create a PipController instance.
        pipController = PipController(registrar: self.registrar(forPlugin: "pip-plugin")!)
        // Set up the Picture-in-Picture mode.
        pipController?.setupPip()

        // Set up the method call handler for the platform channel.
        pipChannel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            // Check if the method call is for entering PiP mode.
            guard call.method == "enterPipMode" else {
                // Return a not implemented result for other method calls.
                result(FlutterMethodNotImplemented)
                return
            }
            // Enter PiP mode.
            self?.pipController?.enterPipMode()
            // Return a success result.
            result(nil)
        })

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

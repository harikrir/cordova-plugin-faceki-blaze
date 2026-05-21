import Foundation
import UIKit
import FACEKI_BLAZE_IOS

@objc(FacekiBlaze)
class FacekiBlaze: CDVPlugin {

    private var callbackId: String?
    private var sdkWindow: UIWindow?

    @objc(startVerification:)
    func startVerification(command: CDVInvokedUrlCommand) {

        self.callbackId = command.callbackId

        // 1. Validate inputs
        guard command.arguments.count >= 2,
              let verificationLink = command.arguments[0] as? String,
              let workflowId = command.arguments[1] as? String else {
            sendError("Invalid parameters")
            return
        }

        // 2. Marshall directly onto the main UI thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // 3. Initialize Faceki SDK 
            let facekiVC = Logger.initiateSMSDK(
                verificationLink: verificationLink,
                workflowId: workflowId,
                setOnComplete: { [weak self] (data: [AnyHashable: Any]) in // 👈 Explicit type added here to prevent compilation errors
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        print("✅ FACEKI SUCCESS:", data)

                        var serialized: [String: Any] = [:]
                        for (k, v) in data {
                            if let key = k as? String {
                                serialized[key] = v
                            }
                        }

                        self.sendSuccess([
                            "status": "SUCCESS",
                            "data": serialized
                        ])

                        self.dismissSDK()
                    }
                },
                redirectBack: { [weak self] in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        print("⚠️ FACEKI CANCELLED")

                        self.sendErrorObject([
                            "status": "CANCELLED"
                        ])

                        self.dismissSDK()
                    }
                },
                selfieImageUrl: nil,
                cardGuideUrl: nil
            )

            // 4. Wrap Faceki VC inside our navigation controller directly
            let navController = UINavigationController(rootViewController: facekiVC)
            navController.modalPresentationStyle = .fullScreen
            
            // Explicitly force the navigation bar to stay visible for Faceki steps
            navController.setNavigationBarHidden(false, animated: false)

            // 5. Present the entire layout structural stack cleanly
            self.presentSDK(navController)
        }
    }

    // MARK: - Window Management Strategy

    private func presentSDK(_ navigationController: UINavigationController) {
        // Create an isolated window spanning the entire physical screen estate
        let window = UIWindow(frame: UIScreen.main.bounds)
        
        // NO MORE TIMING DELAYS: Make the navigation controller the direct root of the window
        window.rootViewController = navigationController
        
        // Elevate the level just above standard layers to visually hide background web content safely
        window.windowLevel = UIWindow.Level.alert + 1
        
        // Make it visible immediately (0ms transition window latency)
        window.makeKeyAndVisible()
        
        // Retain strongly to keep the UI pipeline active
        self.sdkWindow = window
        
        print("✅ SDK window mounted instantly as window root layout target.")
    }

    private func dismissSDK() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // Completely tear down and drop window resources to restore control to the Cordova Webview
            self.sdkWindow?.isHidden = true
            self.sdkWindow = nil
        }
    }

    // MARK: - Cordova Native Bridge Responses

    private func sendSuccess(_ data: [String: Any]) {
        guard let callbackId = callbackId else { return }

        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: data)
        result?.setKeepCallbackAs(false)

        self.commandDelegate.send(result, callbackId: callbackId)
        self.callbackId = nil
    }

    private func sendError(_ message: String) {
        sendErrorObject([
            "status": "ERROR",
            "message": message
        ])
    }

    private func sendErrorObject(_ obj: [String: Any]) {
        guard let callbackId = callbackId else { return }

        let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: obj)
        result?.setKeepCallbackAs(false)

        self.commandDelegate.send(result, callbackId: callbackId)
        self.callbackId = nil
    }
}

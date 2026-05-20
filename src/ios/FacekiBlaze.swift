import Foundation
import UIKit
import FACEKI_BLAZE_IOS

@objc(FacekiBlaze)
class FacekiBlaze: CDVPlugin {

    private var callbackId: String?

    @objc(startVerification:)
    func startVerification(command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId

        // 1. Parameter Validation
        guard command.arguments.count >= 2 else {
            sendError("verificationLink and workflowId required")
            return
        }

        guard let verificationLink = command.arguments[0] as? String,
              let workflowId = command.arguments[1] as? String else {
            sendError("Invalid parameters")
            return
        }

        // 2. Safely bounce to the Main Thread for UI operations
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            guard let cordovaVC = self.viewController else {
                self.sendError("NO_ACTIVE_VIEW_CONTROLLER")
                return
            }

            // Guard against multiple SDK initialization overlays
            if cordovaVC.presentedViewController != nil {
                self.sendError("VIEW_ALREADY_PRESENTED")
                return
            }

            // 3. Initialize Faceki SDK (Version 3.2 Spec)
            let sdkVC = Logger.initiateSMSDK(
                verificationLink: verificationLink,
                workflowId: workflowId,
                setOnComplete: { [weak self] data in
                    guard let self = self else { return }
                    print("✅ FACEKI SDK SUCCESS:", data)

                    // Adapt AnyHashable native dictionary elements cleanly to JSON-compatible data
                    let resultData = (data as? [AnyHashable: Any])?["result"] as? [String: Any] ?? [:]
                    
                    self.sendSuccess([
                        "status": "SUCCESS",
                        "data": resultData
                    ])

                    // Safely dismiss through parent context to avoid variable retention cycles
                    DispatchQueue.main.async {
                        cordovaVC.dismiss(animated: true)
                    }
                },
                redirectBack: { [weak self] in
                    guard let self = self else { return }
                    print("⚠️ FACEKI SDK CANCELLED")

                    self.sendErrorObject([
                        "status": "CANCELLED"
                    ])

                    DispatchQueue.main.async {
                        cordovaVC.dismiss(animated: true)
                    }
                },
                selfieImageUrl: nil, // Pass custom URLs if utilizing remote graphic assets
                cardGuideUrl: nil
            )

            // 4. Standard Native Present (Fixes layout bugs inside WebViews)
            sdkVC.modalPresentationStyle = .fullScreen
            sdkVC.modalTransitionStyle = .crossDissolve

            cordovaVC.present(sdkVC, animated: true)
        }
    }

    // MARK: - Cordova Bridge Response Handlers

    private func sendSuccess(_ data: [String: Any]) {
        guard let callbackId = callbackId else { return }
        
        // Cordova converts Swift Dictionaries natively; no stringifying needed!
        let result = CDVPluginResult(
            status: CDVCommandStatus_OK,
            messageAs: data
        )
        self.commandDelegate.send(result, callbackId: callbackId)
    }

    private func sendError(_ message: String) {
        sendErrorObject([
            "status": "ERROR",
            "message": message
        ])
    }

    private func sendErrorObject(_ obj: [String: Any]) {
        guard let callbackId = callbackId else { return }
        
        let result = CDVPluginResult(
            status: CDVCommandStatus_ERROR,
            messageAs: obj
        )
        self.commandDelegate.send(result, callbackId: callbackId)
    }
}

import Foundation
import UIKit
import FACEKI_BLAZE_IOS

@objc(FacekiBlaze)
class FacekiBlaze: CDVPlugin {

    private var callbackId: String?
    private weak var sdkVC: UIViewController?

    @objc(startVerification:)
    func startVerification(command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId

        guard command.arguments.count >= 2 else {
            sendError("verificationLink and workflowId required")
            return
        }

        guard let verificationLink = command.arguments[0] as? String,
              let workflowId = command.arguments[1] as? String else {
            sendError("Invalid parameters")
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Explicitly tie layout behavior down to Cordova's own view controller instance
            guard let cordovaVC = self.viewController else {
                self.sendError("NO_ACTIVE_VIEW_CONTROLLER")
                return
            }

            // 1. Initialize Faceki SDK directly
            let facekiVC = Logger.initiateSMSDK(
                verificationLink: verificationLink,
                workflowId: workflowId,
                setOnComplete: { [weak self] data in
                    guard let self = self else { return }
                    print("✅ FACEKI SDK SUCCESS:", data)

                    let resultData = (data as? [AnyHashable: Any])?["result"] as? [String: Any] ?? [:]
                    self.sendSuccess(["status": "SUCCESS", "data": resultData])

                    DispatchQueue.main.async {
                        self.removeSdkFromHierarchy()
                    }
                },
                redirectBack: { [weak self] in
                    guard let self = self else { return }
                    print("⚠️ FACEKI SDK CANCELLED")

                    self.sendErrorObject(["status": "CANCELLED"])

                    DispatchQueue.main.async {
                        self.removeSdkFromHierarchy()
                    }
                },
                selfieImageUrl: nil,
                cardGuideUrl: nil
            )

            self.sdkVC = facekiVC

            // 2. CHILD VIEW CONTROLLER INJECTION TECHNIQUE
            // Instead of .present(), we structurally attach facekiVC directly inside cordovaVC.
            // This forces MainViewController to become the actual, direct parent container.
            // If Faceki attempts to call alerts via MainViewController, it will work safely!
            cordovaVC.addChild(facekiVC)
            
            // Scale frame constraints to perfectly block/overlay the WebView area
            facekiVC.view.frame = cordovaVC.view.bounds
            facekiVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            cordovaVC.view.addSubview(facekiVC)
            facekiVC.didMove(toParent: cordovaVC)
        }
    }

    // MARK: - Safe Removal Handler

    private func removeSdkFromHierarchy() {
        guard let facekiVC = self.sdkVC else { return }
        
        // Formally untie child layout relationship structures smoothly 
        facekiVC.willMove(toParent: nil)
        facekiVC.view.removeFromSuperview()
        facekiVC.removeFromParent()
        self.sdkVC = nil
    }

    // MARK: - Cordova Native Bridge Communicators

    private func sendSuccess(_ data: [String: Any]) {
        guard let callbackId = callbackId else { return }
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: data)
        self.commandDelegate.send(result, callbackId: callbackId)
    }

    private func sendError(_ message: String) {
        sendErrorObject(["status": "ERROR", "message": message])
    }

    private func sendErrorObject(_ obj: [String: Any]) {
        guard let callbackId = callbackId else { return }
        let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: obj)
        self.commandDelegate.send(result, callbackId: callbackId)
    }
}

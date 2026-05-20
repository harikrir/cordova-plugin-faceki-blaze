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
            
            guard let cordovaVC = self.viewController else {
                self.sendError("NO_ACTIVE_VIEW_CONTROLLER")
                return
            }

            // 1. Initialize Faceki SDK matching documentation signatures exactly
            let facekiVC = Logger.initiateSMSDK(
                verificationLink: verificationLink,
                workflowId: workflowId,
                setOnComplete: { [weak self] (data: [AnyHashable: Any]) in // 👈 Match doc type exactly
                    guard let self = self else { return }
                    print("✅ FACEKI SDK SUCCESS:", data)

                    // Safely extract the result object exactly like the doc snippet
                    let resultData = data["result"] as? [AnyHashable: Any] ?? [:]
                    
                    // Convert to String-keyed dictionary for clean JS translation
                    var serializedData: [String: Any] = [:]
                    for (key, value) in resultData {
                        if let stringKey = key as? String {
                            serializedData[stringKey] = value
                        }
                    }

                    self.sendSuccess([
                        "status": "SUCCESS",
                        "data": serializedData
                    ])

                    DispatchQueue.main.async {
                        self.removeSdkFromHierarchy()
                    }
                },
                redirectBack: { [weak self] in // 👈 Match onRedirectBack signature
                    guard let self = self else { return }
                    print("⚠️ FACEKI SDK CANCELLED")

                    self.sendErrorObject([
                        "status": "CANCELLED"
                    ])

                    DispatchQueue.main.async {
                        self.removeSdkFromHierarchy()
                    }
                },
                selfieImageUrl: nil,
                cardGuideUrl: nil
            )

            self.sdkVC = facekiVC

            // 2. Child view integration loop to isolate MainViewController alert contexts
            cordovaVC.addChild(facekiVC)
            facekiVC.view.frame = cordovaVC.view.bounds
            facekiVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            cordovaVC.view.addSubview(facekiVC)
            facekiVC.didMove(toParent: cordovaVC)
        }
    }

    // MARK: - Safe Structural Removal Handler

    private func removeSdkFromHierarchy() {
        guard let facekiVC = self.sdkVC else { return }
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

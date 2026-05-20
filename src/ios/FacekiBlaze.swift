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

        DispatchQueue.main.async {

            guard let cordovaVC = self.viewController else {
                self.sendError("NO_ACTIVE_VIEW_CONTROLLER")
                return
            }

            let facekiVC = Logger.initiateSMSDK(
                verificationLink: verificationLink,
                workflowId: workflowId,

                // ✅ IMPORTANT FIX (use Any)
                setOnComplete: { [weak self] data in
                    guard let self = self else { return }

                    print("✅ FACEKI SUCCESS:", data)

                    let dict = data as? [AnyHashable: Any]
                    let resultData = dict?["result"] as? [AnyHashable: Any] ?? [:]

                    var serialized: [String: Any] = [:]
                    for (k, v) in resultData {
                        if let key = k as? String {
                            serialized[key] = v
                        }
                    }

                    self.sendSuccess([
                        "status": "SUCCESS",
                        "data": serialized
                    ])

                    self.removeSdkFromHierarchy()
                },

                redirectBack: { [weak self] in
                    guard let self = self else { return }

                    print("⚠️ FACEKI CANCELLED")

                    self.sendErrorObject([
                        "status": "CANCELLED"
                    ])

                    self.removeSdkFromHierarchy()
                },

                selfieImageUrl: nil,
                cardGuideUrl: nil
            )

            self.sdkVC = facekiVC

            // ✅ EMBED SDK VIEW (correct approach)
            cordovaVC.addChild(facekiVC)
            facekiVC.view.frame = cordovaVC.view.bounds
            facekiVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            cordovaVC.view.addSubview(facekiVC.view)
            facekiVC.didMove(toParent: cordovaVC)
        }
    }

    // ✅ CLEAN REMOVE
    private func removeSdkFromHierarchy() {
        guard let vc = sdkVC else { return }
        vc.willMove(toParent: nil)
        vc.view.removeFromSuperview()
        vc.removeFromParent()
        sdkVC = nil
    }

    // ✅ SUCCESS
    private func sendSuccess(_ data: [String: Any]) {
        guard let callbackId = callbackId else { return }
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: data)
        self.commandDelegate.send(result, callbackId: callbackId)
    }

    // ✅ ERROR
    private func sendError(_ message: String) {
        sendErrorObject(["status": "ERROR", "message": message])
    }

    private func sendErrorObject(_ obj: [String: Any]) {
        guard let callbackId = callbackId else { return }
        let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: obj)
        self.commandDelegate.send(result, callbackId: callbackId)
    }
}

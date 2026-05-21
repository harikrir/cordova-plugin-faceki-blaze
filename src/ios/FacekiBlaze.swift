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

        // ✅ Validate input
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

            // ✅ Initialize SDK
            let facekiVC = Logger.initiateSMSDK(
                verificationLink: verificationLink,
                workflowId: workflowId,

                // ✅ SUCCESS CALLBACK
                setOnComplete: { [weak self] data in
                    DispatchQueue.main.async {
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

                        self.dismissSDK()
                    }
                },

                // ✅ CANCEL / BACK CALLBACK
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

            // ✅ CRITICAL FIX: Present modally (NOT embed)
            let navController = UINavigationController(rootViewController: facekiVC)
            navController.modalPresentationStyle = .fullScreen

            cordovaVC.present(navController, animated: true)

            self.sdkVC = navController
        }
    }

    // ✅ DISMISS SDK SAFELY
    private func dismissSDK() {
        DispatchQueue.main.async {
            self.sdkVC?.dismiss(animated: true, completion: nil)
            self.sdkVC = nil
        }
    }

    // ✅ SUCCESS RESPONSE
    private func sendSuccess(_ data: [String: Any]) {
        guard let callbackId = callbackId else { return }

        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: data)
        result?.setKeepCallbackAs(false)

        self.commandDelegate.send(result, callbackId: callbackId)
        self.callbackId = nil
    }

    // ✅ ERROR RESPONSE
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

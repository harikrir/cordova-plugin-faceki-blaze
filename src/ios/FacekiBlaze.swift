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

            guard let topVC = self.getTopViewController() else {
                self.sendError("NO_TOP_VIEW_CONTROLLER")
                return
            }

            // ✅ IMPORTANT for .overCurrentContext SDKs
            topVC.definesPresentationContext = true

            // ✅ Initialize SDK
            let facekiVC = Logger.initiateSMSDK(
                verificationLink: verificationLink,
                workflowId: workflowId,

                // ✅ SUCCESS CALLBACK
                setOnComplete: { [weak self] data in
                    DispatchQueue.main.async {
                        guard let self = self else { return }

                        print("✅ FACEKI SUCCESS:", data)

                        if let dict = data as? [AnyHashable: Any] {
                            var serialized: [String: Any] = [:]

                            for (k, v) in dict {
                                if let key = k as? String {
                                    serialized[key] = v
                                }
                            }

                            self.sendSuccess([
                                "status": "SUCCESS",
                                "data": serialized
                            ])
                        } else {
                            self.sendError("INVALID_CALLBACK_DATA")
                        }

                        self.dismissSDK()
                    }
                },

                // ✅ CANCEL CALLBACK
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

            // ✅ Delay prevents hierarchy crash in Cordova
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {

                let navController = UINavigationController(rootViewController: facekiVC)
                navController.modalPresentationStyle = .fullScreen

                topVC.present(navController, animated: true) {
                    print("✅ SDK presented successfully")
                }

                self.sdkVC = navController
            }
        }
    }

    // ✅ Get top-most ViewController (CRITICAL FIX)
    private func getTopViewController() -> UIViewController? {

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }),
              var top = window.rootViewController else {
            return nil
        }

        while let presented = top.presentedViewController {
            top = presented
        }

        return top
    }

    // ✅ Dismiss safely
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

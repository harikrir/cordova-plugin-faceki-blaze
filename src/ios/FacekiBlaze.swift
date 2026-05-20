import Foundation
import UIKit
import FACEKI_BLAZE_IOS

@objc(FacekiBlaze)
class FacekiBlaze: CDVPlugin {

    var callbackId: String?
    var presentedNavController: UINavigationController? // ✅ store reference

    // MARK: - Entry Point
    @objc(startVerification:)
    func startVerification(command: CDVInvokedUrlCommand) {

        self.callbackId = command.callbackId

        // ✅ Validate params
        guard command.arguments.count >= 2 else {
            sendError("verificationLink and workflowId required")
            return
        }

        guard let verificationLink = command.arguments[0] as? String,
              let workflowId = command.arguments[1] as? String else {
            sendError("Invalid parameters")
            return
        }

        print("✅ verificationLink:", verificationLink)
        print("✅ workflowId:", workflowId)

        DispatchQueue.main.async {

            let sdkVC = Logger.initiateSMSDK(
                verificationLink: verificationLink,
                workflowId: workflowId,

                // ✅ SUCCESS CALLBACK
                setOnComplete: { data in
                    print("✅ SDK SUCCESS:", data)

                    self.dismissSDK {

                        let resultData = data as? [AnyHashable: Any] ?? [:]

                        let response: [String: Any] = [
                            "status": "SUCCESS",
                            "data": resultData
                        ]

                        self.sendSuccess(response)
                    }
                },

                // ✅ CANCEL CALLBACK
                redirectBack: {
                    print("⚠️ SDK CANCELLED")

                    self.dismissSDK {

                        let response: [String: Any] = [
                            "status": "CANCELLED"
                        ]

                        self.sendErrorObject(response)
                    }
                },

                selfieImageUrl: nil,
                cardGuideUrl: nil
            )

            guard let rootVC = self.viewController else {
                self.sendError("VIEW_CONTROLLER_MISSING")
                return
            }

            // ✅ Wrap SDK in navigation controller
            let navController = UINavigationController(rootViewController: sdkVC)

            // ✅ CRITICAL FIX: override SDK presentation behavior
            navController.modalPresentationStyle = .overFullScreen

            // ✅ Store reference for proper dismissal
            self.presentedNavController = navController

            // ✅ Present SDK
            rootVC.present(navController, animated: true)
        }
    }

    // ✅ PROPER DISMISS (FIXES YOUR ISSUE)
    private func dismissSDK(completion: @escaping () -> Void) {

        DispatchQueue.main.async {

            if let nav = self.presentedNavController {
                print("✅ Dismissing SDK navController")

                nav.dismiss(animated: true) {
                    self.presentedNavController = nil
                    completion()
                }

            } else {
                print("⚠️ No stored controller, fallback dismiss")

                self.viewController?.dismiss(animated: true, completion: completion)
            }
        }
    }

    // MARK: - SUCCESS
    private func sendSuccess(_ data: [String: Any]) {
        guard let callbackId = callbackId else { return }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8)

            let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: jsonString)
            self.commandDelegate.send(result, callbackId: callbackId)

        } catch {
            sendError("JSON_SERIALIZATION_FAILED")
        }
    }

    // MARK: - ERROR
    private func sendError(_ message: String) {
        let obj: [String: Any] = [
            "status": "ERROR",
            "message": message
        ]
        sendErrorObject(obj)
    }

    private func sendErrorObject(_ obj: [String: Any]) {
        guard let callbackId = callbackId else { return }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: obj, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8)

            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: jsonString)
            self.commandDelegate.send(result, callbackId: callbackId)

        } catch {
            let fallback = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "UNKNOWN_ERROR")
            self.commandDelegate.send(fallback, callbackId: callbackId)
        }
    }
}

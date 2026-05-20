import Foundation
import UIKit
import FACEKI_BLAZE_IOS

@objc(FacekiBlaze)
class FacekiBlaze: CDVPlugin {

    var callbackId: String?

    // MARK: - Entry Point
    @objc(startVerification:)
    func startVerification(command: CDVInvokedUrlCommand) {

        self.callbackId = command.callbackId

        // ✅ Expect verificationLink + workflowId
        guard command.arguments.count >= 2 else {
            sendError("verificationLink and workflowId required")
            return
        }

        guard let verificationLink = command.arguments[0] as? String,
              let workflowId = command.arguments[1] as? String else {

            sendError("Invalid parameters")
            return
        }

        // ✅ Debug logs
        print("✅ verificationLink:", verificationLink)
        print("✅ workflowId:", workflowId)

        DispatchQueue.main.async {

            let sdkVC = Logger.initiateSMSDK(
                verificationLink: verificationLink,
                workflowId: workflowId,

                // ✅ SUCCESS CALLBACK
                setOnComplete: { data in
                    print("✅ SDK SUCCESS:", data)

                    DispatchQueue.main.async {
                        self.dismissSDK {

                            let resultData = data as? [AnyHashable: Any] ?? [:]

                            let response: [String: Any] = [
                                "status": "SUCCESS",
                                "data": resultData
                            ]

                            self.sendSuccess(response)
                        }
                    }
                },

                // ✅ CANCEL CALLBACK
                redirectBack: {
                    print("⚠️ SDK CANCELLED")

                    DispatchQueue.main.async {
                        self.dismissSDK {

                            let response: [String: Any] = [
                                "status": "CANCELLED"
                            ]

                            self.sendErrorObject(response)
                        }
                    }
                },

                selfieImageUrl: nil,
                cardGuideUrl: nil
            )

            guard let rootVC = self.viewController else {
                self.sendError("VIEW_CONTROLLER_MISSING")
                return
            }

            // ✅ Always present modally
            let navController = UINavigationController(rootViewController: sdkVC)
            navController.modalPresentationStyle = .fullScreen

            rootVC.present(navController, animated: true)
        }
    }

    // ✅ Reusable dismiss function (important)
    private func dismissSDK(completion: @escaping () -> Void) {
        if let presented = self.viewController?.presentedViewController {
            presented.dismiss(animated: true, completion: completion)
        } else {
            completion()
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

    // MARK: - ERROR (String)
    private func sendError(_ message: String) {
        let response: [String: Any] = [
            "status": "ERROR",
            "message": message
        ]
        sendErrorObject(response)
    }

    // MARK: - ERROR (Object)
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

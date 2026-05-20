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

            guard let rootVC = self.viewController else {
                self.sendError("VIEW_CONTROLLER_MISSING")
                return
            }

            // ✅ Create SDK VC
            let sdkVC = Logger.initiateSMSDK(
                verificationLink: verificationLink,
                workflowId: workflowId,

                // ✅ SUCCESS CALLBACK
                setOnComplete: { data in
                    print("✅ SDK SUCCESS:", data)

                    let resultData = (data as? [AnyHashable: Any])?["result"] as? [AnyHashable: Any] ?? [:]

                    let response: [String: Any] = [
                        "status": "SUCCESS",
                        "data": resultData
                    ]

                    self.sendSuccess(response)
                },

                // ✅ CANCEL / BACK CALLBACK
                redirectBack: {
                    print("⚠️ SDK BACK / CANCEL")

                    DispatchQueue.main.async {
                        if let nav = rootVC.navigationController {
                            nav.popToRootViewController(animated: true)
                        } else {
                            rootVC.dismiss(animated: true)
                        }
                    }

                    let response: [String: Any] = [
                        "status": "CANCELLED"
                    ]

                    self.sendErrorObject(response)
                },

                selfieImageUrl: nil,
                cardGuideUrl: nil
            )

            // ✅ SAFE NAVIGATION HANDLING

            if let nav = rootVC.navigationController {
                // ✅ Case 1: Already inside navigation → PUSH
                print("✅ Using existing navigationController")
                nav.pushViewController(sdkVC, animated: true)

            } else {
                // ✅ Case 2: No navigation → PRESENT safely
                print("⚠️ No navigationController → presenting")

                let navController = UINavigationController(rootViewController: sdkVC)
                navController.modalPresentationStyle = .fullScreen

                rootVC.present(navController, animated: true)
            }
        }
    }

    // MARK: - SUCCESS
    private func sendSuccess(_ data: [String: Any]) {
        guard let callbackId = callbackId else { return }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            let jsonString = String(data: jsonData, encoding: .utf8)

            let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: jsonString)
            self.commandDelegate.send(result, callbackId: callbackId)

        } catch {
            sendError("JSON_SERIALIZATION_FAILED")
        }
    }

    // MARK: - ERROR
    private func sendError(_ message: String) {
        sendErrorObject([
            "status": "ERROR",
            "message": message
        ])
    }

    private func sendErrorObject(_ obj: [String: Any]) {
        guard let callbackId = callbackId else { return }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: obj)
            let jsonString = String(data: jsonData, encoding: .utf8)

            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: jsonString)
            self.commandDelegate.send(result, callbackId: callbackId)

        } catch {
            let fallback = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "UNKNOWN_ERROR")
            self.commandDelegate.send(fallback, callbackId: callbackId)
        }
    }
}

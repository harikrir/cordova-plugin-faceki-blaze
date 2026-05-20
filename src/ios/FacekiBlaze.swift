import Foundation
import UIKit
import FACEKI_BLAZE_IOS

@objc(FacekiBlaze)
class FacekiBlaze: CDVPlugin {

    var callbackId: String?

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

        print("✅ verificationLink:", verificationLink)
        print("✅ workflowId:", workflowId)

        DispatchQueue.main.async {

            guard let rootVC = self.viewController else {
                self.sendError("VIEW_CONTROLLER_MISSING")
                return
            }

            // ✅ SDK VC
            let sdkVC = Logger.initiateSMSDK(
                verificationLink: verificationLink,
                workflowId: workflowId,

                // ✅ SUCCESS
                setOnComplete: { data in
                    print("✅ SDK SUCCESS:", data)

                    let resultData = (data as? [AnyHashable: Any])?["result"] as? [AnyHashable: Any] ?? [:]

                    let response: [String: Any] = [
                        "status": "SUCCESS",
                        "data": resultData
                    ]

                    self.sendSuccess(response)
                },

                // ✅ BACK / CANCEL
                redirectBack: {
                    print("⚠️ User navigated back")
                    
                    DispatchQueue.main.async {
                        rootVC.navigationController?.popToRootViewController(animated: true)
                    }

                    let response: [String: Any] = [
                        "status": "CANCELLED"
                    ]

                    self.sendErrorObject(response)
                },

                selfieImageUrl: nil,
                cardGuideUrl: nil
            )

            // ✅ IMPORTANT: PUSH (not present)
            if let nav = rootVC.navigationController {
                print("✅ Using existing navigationController")
                nav.pushViewController(sdkVC, animated: true)

            } else {
                print("⚠️ No navigationController, creating one")

                let navController = UINavigationController(rootViewController: rootVC)

                // Replace app root (to enable push behavior)
                if let window = UIApplication.shared.windows.first {
                    window.rootViewController = navController
                    window.makeKeyAndVisible()
                }

                navController.pushViewController(sdkVC, animated: true)
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

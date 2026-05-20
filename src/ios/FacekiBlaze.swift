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

            guard let topVC = self.getTopViewController() else {
                self.sendError("NO_ACTIVE_VIEW_CONTROLLER")
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
                        if let topVC = self.getTopViewController() {
                            if let nav = topVC.navigationController {
                                nav.popToRootViewController(animated: true)
                            } else {
                                topVC.dismiss(animated: true)
                            }
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

            // ✅ SAFE NAVIGATION (TOP VC BASED)

            if let nav = topVC as? UINavigationController {
                print("✅ Top is navigation controller → push")
                nav.pushViewController(sdkVC, animated: true)

            } else if let nav = topVC.navigationController {
                print("✅ Using existing navigationController → push")
                nav.pushViewController(sdkVC, animated: true)

            } else {
                print("⚠️ No navigation → present safely")

                let navController = UINavigationController(rootViewController: sdkVC)
                navController.modalPresentationStyle = .fullScreen

                topVC.present(navController, animated: true)
            }
        }
    }

    // ✅ CRITICAL: Get TOP visible controller (fixes your error)
    private func getTopViewController() -> UIViewController? {

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return nil
        }

        var topVC = window.rootViewController

        while let presented = topVC?.presentedViewController {
            topVC = presented
        }

        return topVC
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

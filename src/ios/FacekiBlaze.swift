import Foundation
import UIKit
import FACEKI_BLAZE_IOS

@objc(FacekiBlaze)
class FacekiBlaze: CDVPlugin {

    var callbackId: String?

    // MARK: Entry Point
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

            guard let topVC = self.getTopViewController() else {
                self.sendError("NO_ACTIVE_VIEW_CONTROLLER")
                return
            }

            // ✅ Initialize SDK
            let sdkVC = Logger.initiateSMSDK(
                verificationLink: verificationLink,
                workflowId: workflowId,

                setOnComplete: { data in
                    print("✅ SDK SUCCESS:", data)

                    let resultData = (data as? [AnyHashable: Any])?["result"] as? [AnyHashable: Any] ?? [:]

                    let response: [String: Any] = [
                        "status": "SUCCESS",
                        "data": resultData
                    ]

                    self.sendSuccess(response)
                },

                redirectBack: {
                    print("⚠️ SDK BACK")

                    DispatchQueue.main.async {
                        self.handleBackNavigation()
                    }

                    self.sendErrorObject([
                        "status": "CANCELLED"
                    ])
                },

                selfieImageUrl: nil,
                cardGuideUrl: nil
            )

            // ✅ ✅ IMPORTANT: Always PRESENT (NOT PUSH)
            // 👉 This avoids all OutSystems navigation issues

            let navController = UINavigationController(rootViewController: sdkVC)
            navController.modalPresentationStyle = .fullScreen

            topVC.present(navController, animated: true)
        }
    }

    // ✅ Handle back safely
    private func handleBackNavigation() {
        if let topVC = getTopViewController() {
            if topVC.presentingViewController != nil {
                topVC.dismiss(animated: true)
            } else if let nav = topVC.navigationController {
                nav.popToRootViewController(animated: true)
            }
        }
    }

    // ✅ Get REAL visible controller (critical for OutSystems)
    private func getTopViewController() -> UIViewController? {

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }) else {
            return nil
        }

        var topVC = window.rootViewController

        while let presented = topVC?.presentedViewController {
            topVC = presented
        }

        return topVC
    }

    // MARK: SUCCESS
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

    // MARK: ERROR
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

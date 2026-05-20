import Foundation
import UIKit
import FACEKI_BLAZE_IOS

@objc(FacekiBlaze)
class FacekiBlaze: CDVPlugin {

    private var callbackId: String?
    private var navController: UINavigationController?

    // MARK: Entry Point
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

        DispatchQueue.main.async {

            // ✅ CRITICAL: always use top-most visible VC
            guard let topVC = self.getTopViewController() else {
                self.sendError("NO_ACTIVE_VIEW_CONTROLLER")
                return
            }

            // Prevent multiple presentations
            if topVC.presentedViewController != nil {
                self.sendError("VIEW_ALREADY_PRESENTED")
                return
            }

            var sdkVC: UIViewController!

            sdkVC = Logger.initiateSMSDK(

                verificationLink: verificationLink,
                workflowId: workflowId,

                // ✅ SUCCESS CALLBACK
                setOnComplete: { [weak self] data in
                    guard let self = self else { return }

                    print("✅ SDK SUCCESS:", data)

                    let resultData =
                        (data as? [AnyHashable: Any])?["result"]
                        as? [AnyHashable: Any] ?? [:]

                    DispatchQueue.main.async {
                        self.navController?.dismiss(animated: true)
                    }

                    self.sendSuccess([
                        "status": "SUCCESS",
                        "data": resultData
                    ])
                },

                // ✅ CANCEL / BACK
                redirectBack: { [weak self] in
                    guard let self = self else { return }

                    print("⚠️ SDK BACK")

                    DispatchQueue.main.async {
                        self.navController?.dismiss(animated: true)
                    }

                    self.sendErrorObject([
                        "status": "CANCELLED"
                    ])
                },

                selfieImageUrl: nil,
                cardGuideUrl: nil
            )

            // ✅ IMPORTANT: Wrap SDK inside navigation controller
            let navController = UINavigationController(rootViewController: sdkVC)
            navController.modalPresentationStyle = .fullScreen

            // ✅ Store reference for dismiss
            self.navController = navController

            // ✅ CRITICAL FIX: Present from TOP VC (not rootVC, not self.viewController)
            topVC.present(navController, animated: true)
        }
    }

    // ✅ Get top-most visible view controller (FIXES alert error)
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

            let result = CDVPluginResult(
                status: CDVCommandStatus_OK,
                messageAs: jsonString
            )

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

            let result = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: jsonString
            )

            self.commandDelegate.send(result, callbackId: callbackId)

        } catch {
            let fallback = CDVPluginResult(
                status: CDVCommandStatus_ERROR,
                messageAs: "UNKNOWN_ERROR"
            )

            self.commandDelegate.send(fallback, callbackId: callbackId)
        }
    }
}

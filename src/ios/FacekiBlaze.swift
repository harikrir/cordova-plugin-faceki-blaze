import Foundation
import UIKit
import FACEKI_BLAZE_IOS

@objc(FacekiBlaze)
class FacekiBlaze: CDVPlugin {

    private var callbackId: String?

    // MARK: - Entry Point

    @objc(startVerification:)
    func startVerification(command: CDVInvokedUrlCommand) {

        self.callbackId = command.callbackId

        // Validate parameters
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {

            // Cordova main controller
            guard let cordovaVC = self.viewController else {
                self.sendError("NO_ACTIVE_VIEW_CONTROLLER")
                return
            }

            // Initialize SDK
            let sdkVC = Logger.initiateSMSDK(

                verificationLink: verificationLink,
                workflowId: workflowId,

                setOnComplete: { data in

                    print("✅ SDK SUCCESS:", data)

                    let resultData =
                    (data as? [AnyHashable: Any])?["result"]
                    as? [AnyHashable: Any] ?? [:]

                    let response: [String: Any] = [
                        "status": "SUCCESS",
                        "data": resultData
                    ]

                    self.sendSuccess(response)

                    // Return safely
                    DispatchQueue.main.async {

                        if let nav = cordovaVC.navigationController {

                            nav.popToRootViewController(animated: true)

                        } else {

                            cordovaVC.dismiss(animated: true)
                        }
                    }
                },

                redirectBack: {

                    print("⚠️ SDK BACK")

                    DispatchQueue.main.async {

                        if let nav = cordovaVC.navigationController {

                            nav.popToRootViewController(animated: true)

                        } else {

                            cordovaVC.dismiss(animated: true)
                        }
                    }

                    self.sendErrorObject([
                        "status": "CANCELLED"
                    ])
                },

                selfieImageUrl: nil,
                cardGuideUrl: nil
            )

            sdkVC.modalPresentationStyle = .fullScreen

            // Preferred method (official SDK flow)
            if let nav = cordovaVC.navigationController {

                print("✅ PUSH SDK VC")

                nav.pushViewController(sdkVC, animated: true)

            } else {

                // Fallback only if navigation controller missing
                print("⚠️ NAVIGATION CONTROLLER NOT FOUND → PRESENT")

                let navController = UINavigationController(rootViewController: sdkVC)
                navController.modalPresentationStyle = .fullScreen

                cordovaVC.present(navController, animated: true)
            }
        }
    }

    // MARK: - SUCCESS

    private func sendSuccess(_ data: [String: Any]) {

        guard let callbackId = callbackId else {
            return
        }

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

    // MARK: - ERROR

    private func sendError(_ message: String) {

        sendErrorObject([
            "status": "ERROR",
            "message": message
        ])
    }

    private func sendErrorObject(_ obj: [String: Any]) {

        guard let callbackId = callbackId else {
            return
        }

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

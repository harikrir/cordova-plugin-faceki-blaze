import Foundation
import UIKit
import FACEKI_BLAZE_IOS

@objc(FacekiBlaze)
class FacekiBlaze: CDVPlugin {

    private var callbackId: String?

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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {

            // ✅ SAME AS JUMIO (CRITICAL FIX)
            guard let rootVC = UIApplication.shared.windows.first?.rootViewController else {
                self.sendError("NO_ROOT_VIEW_CONTROLLER")
                return
            }

            // Prevent duplicate presentation
            if rootVC.presentedViewController != nil {
                self.sendError("VIEW_ALREADY_PRESENTED")
                return
            }

            var sdkVC: UIViewController!

            sdkVC = Logger.initiateSMSDK(

                verificationLink: verificationLink,
                workflowId: workflowId,

                // ✅ SUCCESS
                setOnComplete: { [weak self] data in
                    guard let self = self else { return }

                    print("✅ SDK SUCCESS:", data)

                    let resultData =
                        (data as? [AnyHashable: Any])?["result"]
                        as? [AnyHashable: Any] ?? [:]

                    self.sendSuccess([
                        "status": "SUCCESS",
                        "data": resultData
                    ])

                    DispatchQueue.main.async {
                        sdkVC.dismiss(animated: true)
                    }
                },

                // ✅ CANCEL
                redirectBack: { [weak self] in
                    guard let self = self else { return }

                    print("⚠️ SDK BACK")

                    self.sendErrorObject([
                        "status": "CANCELLED"
                    ])

                    DispatchQueue.main.async {
                        sdkVC.dismiss(animated: true)
                    }
                },

                selfieImageUrl: nil,
                cardGuideUrl: nil
            )

            // ✅ IMPORTANT
            sdkVC.modalPresentationStyle = .fullScreen

            // ✅ SAME PATTERN AS JUMIO
            rootVC.present(sdkVC, animated: true)
        }
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

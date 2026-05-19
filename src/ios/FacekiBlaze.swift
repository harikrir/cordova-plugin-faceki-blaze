import Foundation
import UIKit
import Cordova
import FACEKI_BLAZE_IOS

@objc(FacekiBlaze)
class FacekiBlaze: CDVPlugin {

    var callbackId: String?

    @objc(startVerification:)
    func startVerification(command: CDVInvokedUrlCommand) {

        self.callbackId = command.callbackId

        // ✅ Validate input
        guard command.arguments.count >= 3 else {
            sendError("clientId, clientSecret, workflowId required")
            return
        }

        guard let clientId = command.arguments[0] as? String,
              let clientSecret = command.arguments[1] as? String,
              let workflowId = command.arguments[2] as? String else {

            sendError("Invalid parameters")
            return
        }

        DispatchQueue.main.async {

            let sdkVC = Logger.initiateSMSDK(
                setClientID: clientId,
                setClientSecret: clientSecret,
                workflowId: workflowId,
                setOnComplete: { data in

                    let response: [String: Any] = [
                        "status": "SUCCESS",
                        "data": data
                    ]

                    self.sendSuccess(response)
                },
                redirectBack: {

                    let response: [String: Any] = [
                        "status": "CANCELLED"
                    ]

                    self.sendErrorObject(response)
                },
                selfieImageUrl: nil,
                cardGuideUrl: nil
            )

            guard let rootVC = self.viewController else {
                self.sendError("VIEW_CONTROLLER_MISSING")
                return
            }

            if let nav = rootVC.navigationController {
                nav.pushViewController(sdkVC, animated: true)
            } else {
                let navController = UINavigationController(rootViewController: sdkVC)
                rootVC.present(navController, animated: true, completion: nil)
            }
        }
    }

    // ✅ SUCCESS
    private func sendSuccess(_ data: [String: Any]) {
        guard let callbackId = self.callbackId else { return }

        if let jsonData = try? JSONSerialization.data(withJSONObject: data),
           let jsonString = String(data: jsonData, encoding: .utf8) {

            let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: jsonString)
            self.commandDelegate.send(result, callbackId: callbackId)
        }
    }

    // ✅ ERROR (string)
    private func sendError(_ message: String) {
        guard let callbackId = self.callbackId else { return }

        let response = [
            "status": "ERROR",
            "message": message
        ]

        sendErrorObject(response)
    }

    // ✅ ERROR (object)
    private func sendErrorObject(_ obj: [String: Any]) {
        guard let callbackId = self.callbackId else { return }

        if let jsonData = try? JSONSerialization.data(withJSONObject: obj),
           let jsonString = String(data: jsonData, encoding: .utf8) {

            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: jsonString)
            self.commandDelegate.send(result, callbackId: callbackId)
        }
    }
}

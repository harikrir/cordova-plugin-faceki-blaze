import Foundation
import FACEKI_BLAZE_IOS

@objc(FacekiBlaze)
class FacekiBlaze: CDVPlugin {

    private var callbackId: String?
    private var isProcessing: Bool = false

    @objc(startVerification:)
    func startVerification(command: CDVInvokedUrlCommand) {

        // ✅ Prevent multiple calls
        if isProcessing {
            sendError("VERIFICATION_ALREADY_RUNNING")
            return
        }

        self.callbackId = command.callbackId

        guard command.arguments.count >= 1 else {
            sendError("verificationLink is required")
            return
        }

        guard let verificationLink = command.arguments[0] as? String else {
            sendError("Invalid verificationLink")
            return
        }

        // ✅ Get workflowId from arguments (instead of hardcoding)
        var workflowId = ""
        if command.arguments.count > 1,
           let wf = command.arguments[1] as? String {
            workflowId = wf
        }

        isProcessing = true

        DispatchQueue.main.async {

            let sdkVC = Logger.initiateSMSDK(
                verificationLink: verificationLink,
                workflowId: workflowId,
                setOnComplete: self.onComplete,
                redirectBack: self.onRedirectBack,
                selfieImageUrl: nil,
                cardGuideUrl: nil
            )

            // ✅ Navigation handling (important)
            if let nav = self.viewController.navigationController {
                nav.pushViewController(sdkVC, animated: true)
            } else {
                let navController = UINavigationController(rootViewController: sdkVC)
                self.viewController.present(navController, animated: true)
            }
        }
    }

    // ✅ SUCCESS CALLBACK (Faceki onComplete)
    private func onComplete(data: [AnyHashable: Any]) {

        do {
            self.isProcessing = false

            var response: [String: Any] = [:]
            response["status"] = "SUCCESS"
            response["data"] = data

            let jsonData = try JSONSerialization.data(withJSONObject: response, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8)

            let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: jsonString)
            self.commandDelegate.send(result, callbackId: self.callbackId)

        } catch {
            self.isProcessing = false
            sendError("PROCESSING_ERROR")
        }
    }

    // ✅ USER EXIT / BACK ACTION
    private func onRedirectBack() {
        DispatchQueue.main.async {

            self.isProcessing = false

            if let nav = self.viewController.navigationController {
                nav.popToViewController(self.viewController, animated: true)
            } else {
                self.viewController.dismiss(animated: true)
            }

            // ✅ Return cancel status to Cordova
            let response = ["status": "CANCELLED"]
            if let jsonData = try? JSONSerialization.data(withJSONObject: response),
               let jsonString = String(data: jsonData, encoding: .utf8) {

                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: jsonString)
                self.commandDelegate.send(result, callbackId: self.callbackId)
            }
        }
    }

    // ❌ ERROR HANDLER
    private func sendError(_ message: String) {
        self.isProcessing = false

        let response = ["status": "ERROR", "message": message]

        if let jsonData = try? JSONSerialization.data(withJSONObject: response),
           let jsonString = String(data: jsonData, encoding: .utf8) {

            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: jsonString)
            self.commandDelegate.send(result, callbackId: self.callbackId)
        } else {
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: message)
            self.commandDelegate.send(result, callbackId: self.callbackId)
        }
    }
}

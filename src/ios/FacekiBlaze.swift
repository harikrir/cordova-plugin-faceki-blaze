import Foundation
import FACEKI_BLAZE_IOS

@objc(FacekiBlaze)
class FacekiBlaze: CDVPlugin {

    private var callbackId: String?

    @objc(startVerification:)
    func startVerification(command: CDVInvokedUrlCommand) {

        self.callbackId = command.callbackId

        guard command.arguments.count >= 1 else {
            sendError("verificationLink is required")
            return
        }

        guard let verificationLink = command.arguments[0] as? String else {
            sendError("Invalid verificationLink")
            return
        }

        // ⚠️ IMPORTANT: You must configure your workflowId
        let workflowId = ""  // <-- SET THIS (or extend JS later)

        DispatchQueue.main.async {

            let sdkVC = Logger.initiateSMSDK(
                verificationLink: verificationLink,
                workflowId: workflowId,
                setOnComplete: self.onComplete,
                redirectBack: self.onRedirectBack,
                selfieImageUrl: nil,
                cardGuideUrl: nil
            )

            if let nav = self.viewController.navigationController {
                nav.pushViewController(sdkVC, animated: true)
            } else {
                self.viewController.present(sdkVC, animated: true)
            }
        }
    }

    // ✅ SUCCESS / RESULT
    private func onComplete(data: [AnyHashable: Any]) {

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8)

            let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: jsonString)
            self.commandDelegate.send(result, callbackId: self.callbackId)

        } catch {
            sendError("Failed to parse response")
        }
    }

    // ✅ USER EXIT
    private func onRedirectBack() {
        DispatchQueue.main.async {
            self.viewController.dismiss(animated: true)
        }
    }

    // ❌ ERROR
    private func sendError(_ message: String) {
        let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: message)
        self.commandDelegate.send(result, callbackId: self.callbackId)
    }
}

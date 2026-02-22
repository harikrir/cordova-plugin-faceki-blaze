import Foundation
import FACEKI_BLAZE_IOS

@objc(FacekiBlaze) class FacekiBlaze : CDVPlugin {
    @objc(startVerification:)
    func startVerification(command: CDVInvokedUrlCommand) {
        let verificationLink = command.arguments[0] as? String ?? ""
        
        DispatchQueue.main.async {
            let sdkVC = Logger.initiateSMSDK(
                verificationLink: verificationLink,
                workflowId: "", // Optional
                setOnComplete: { data in
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: data as? [String: Any])
                    self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
                },
                onRedirectBack: {
                    self.viewController.dismiss(animated: true, completion: nil)
                }
            )
            self.viewController.present(sdkVC, animated: true, completion: nil)
        }
    }
}

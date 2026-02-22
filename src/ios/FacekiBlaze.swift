import Foundation
import FACEKI_BLAZE_IOS

@objc(FacekiBlaze) class FacekiBlaze : CDVPlugin {
    @objc(startVerification:)
    func startVerification(command: CDVInvokedUrlCommand) {
        let url = command.arguments[0] as? String ?? ""
        let workflowId = command.arguments[1] as? String ?? "" // Get workflowId
        
        DispatchQueue.main.async {
            let sdkVC = Logger.initiateSMSDK(
                verificationLink: url,
                workflowId: workflowId, // Now using the passed workflowId
                setOnComplete: { data in
                    let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: data as? [String: Any])
                    self.commandDelegate!.send(result, callbackId: command.callbackId)
                },
                onRedirectBack: {
                    self.viewController.dismiss(animated: true, completion: nil)
                }
            )
            self.viewController.present(sdkVC, animated: true, completion: nil)
        }
    }
}

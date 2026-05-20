import Foundation
import UIKit
import FACEKI_BLAZE_IOS

@objc(FacekiBlaze)
class FacekiBlaze: CDVPlugin {

    private var callbackId: String?
    private weak var navController: UINavigationController?

    @objc(startVerification:)
    func startVerification(command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId

        // 1. Structural Parameter Safeguards
        guard command.arguments.count >= 2 else {
            sendError("verificationLink and workflowId required")
            return
        }

        guard let verificationLink = command.arguments[0] as? String,
              let workflowId = command.arguments[1] as? String else {
            sendError("Invalid parameters")
            return
        }

        // 2. Safely process entirely on Main Thread to protect layout targets
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            guard let topVC = self.getTopViewController() else {
                self.sendError("NO_ACTIVE_VIEW_CONTROLLER")
                return
            }

            // 3. Initialize Faceki SDK Instance
            let sdkVC = Logger.initiateSMSDK(
                verificationLink: verificationLink,
                workflowId: workflowId,
                setOnComplete: { [weak self] data in
                    guard let self = self else { return }
                    print("✅ FACEKI SDK SUCCESS:", data)

                    let resultData = (data as? [AnyHashable: Any])?["result"] as? [String: Any] ?? [:]
                    
                    self.sendSuccess([
                        "status": "SUCCESS",
                        "data": resultData
                    ])

                    // Safely dismiss via local parent stack assignment references
                    DispatchQueue.main.async {
                        self.navController?.dismiss(animated: true)
                    }
                },
                redirectBack: { [weak self] in
                    guard let self = self else { return }
                    print("⚠️ FACEKI SDK CANCELLED")

                    self.sendErrorObject([
                        "status": "CANCELLED"
                    ])

                    DispatchQueue.main.async {
                        self.navController?.dismiss(animated: true)
                    }
                },
                selfieImageUrl: nil,
                cardGuideUrl: nil
            )

            // 4. CRITICAL FIX FOR ALERT PRESENTATION WINDOW HIERARCHY
            // We pass the sdkVC as the explicit root view controller *immediately*.
            let navigationWrapper = UINavigationController(rootViewController: sdkVC)
            navigationWrapper.modalPresentationStyle = .fullScreen
            
            // Assign to tracking wrapper variable
            self.navController = navigationWrapper

            // We use animated: false here. This forces the Navigation window 
            // hierarchy to mount instantaneously, ensuring that if the SDK pops a 
            // camera/location/network error UIAlertController, it does not crash.
            topVC.present(navigationWrapper, animated: false, completion: nil)
        }
    }

    // MARK: - Window Hierarchy Resolver

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

    // MARK: - Cordova Native Bridge Communicators

    private func sendSuccess(_ data: [String: Any]) {
        guard let callbackId = callbackId else { return }
        
        // Cordova natively translates standard Swift Dictionaries into JS JSON Objects.
        let result = CDVPluginResult(
            status: CDVCommandStatus_OK,
            messageAs: data
        )
        self.commandDelegate.send(result, callbackId: callbackId)
    }

    private func sendError(_ message: String) {
        sendErrorObject([
            "status": "ERROR",
            "message": message
        ])
    }

    private func sendErrorObject(_ obj: [String: Any]) {
        guard let callbackId = callbackId else { return }
        
        let result = CDVPluginResult(
            status: CDVCommandStatus_ERROR,
            messageAs: obj
        )
        self.commandDelegate.send(result, callbackId: callbackId)
    }
}

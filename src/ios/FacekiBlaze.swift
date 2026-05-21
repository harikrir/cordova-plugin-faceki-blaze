import Foundation
import UIKit
import FACEKI_BLAZE_IOS

@objc(FacekiBlaze)
class FacekiBlaze: CDVPlugin {

    private var callbackId: String?
    private var sdkWindow: UIWindow?

    @objc(startVerification:)
    func startVerification(command: CDVInvokedUrlCommand) {

        self.callbackId = command.callbackId

        // ✅ Validate input
        guard command.arguments.count >= 2,
              let verificationLink = command.arguments[0] as? String,
              let workflowId = command.arguments[1] as? String else {
            sendError("Invalid parameters")
            return
        }

        DispatchQueue.main.async {

            // ✅ Initialize SDK
            let facekiVC = Logger.initiateSMSDK(
                verificationLink: verificationLink,
                workflowId: workflowId,

                // ✅ SUCCESS CALLBACK
                setOnComplete: { [weak self] data in
                    DispatchQueue.main.async {
                        guard let self = self else { return }

                        print("✅ FACEKI SUCCESS:", data ?? "")

                        var serialized: [String: Any] = [:]

                        if let dict = data as? [AnyHashable: Any] {
                            for (k, v) in dict {
                                if let key = k as? String {
                                    serialized[key] = v
                                }
                            }
                        }

                        self.sendSuccess([
                            "status": "SUCCESS",
                            "data": serialized
                        ])

                        self.dismissSDK()
                    }
                },

                // ✅ CANCEL CALLBACK
                redirectBack: { [weak self] in
                    DispatchQueue.main.async {
                        guard let self = self else { return }

                        print("⚠️ FACEKI CANCELLED")

                        self.sendErrorObject([
                            "status": "CANCELLED"
                        ])

                        self.dismissSDK()
                    }
                },

                selfieImageUrl: nil,
                cardGuideUrl: nil
            )

            // ✅ Wrap SDK in navigation controller
            let navController = UINavigationController(rootViewController: facekiVC)
            navController.modalPresentationStyle = .fullScreen

            // ✅ Present via isolated UIWindow (FIX)
            self.presentSDK(navController)
        }
    }

    // ✅ ✅ FINAL FIX: Stable UIWindow presentation
    private func presentSDK(_ vc: UIViewController) {

        let window = UIWindow(frame: UIScreen.main.bounds)

        let rootVC = UIViewController()
        rootVC.view.backgroundColor = .black

        window.rootViewController = rootVC
        window.windowLevel = UIWindow.Level.alert + 1

        // ✅ Step 1: Make visible
        window.makeKeyAndVisible()

        // ✅ Keep strong reference
        self.sdkWindow = window

        // ✅ Step 2: Ensure hierarchy is ready before presenting
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            rootVC.present(vc, animated: true) {
                print("✅ SDK Presented using UIWindow")
            }
        }
    }

    // ✅ Dismiss SDK cleanly
    private func dismissSDK() {
        DispatchQueue.main.async {
            self.sdkWindow?.isHidden = true
            self.sdkWindow = nil
        }
    }

    // ✅ SUCCESS RESPONSE
    private func sendSuccess(_ data: [String: Any]) {
        guard let callbackId = callbackId else { return }

        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: data)
        result?.setKeepCallbackAs(false)

        self.commandDelegate.send(result, callbackId: callbackId)
        self.callbackId = nil
    }

    // ✅ ERROR RESPONSE
    private func sendError(_ message: String) {
        sendErrorObject([
            "status": "ERROR",
            "message": message
        ])
    }

    private func sendErrorObject(_ obj: [String: Any]) {
        guard let callbackId = callbackId else { return }

        let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: obj)
        result?.setKeepCallbackAs(false)

        self.commandDelegate.send(result, callbackId: callbackId)
        self.callbackId = nil
    }
}

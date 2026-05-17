package com.faceki.blaze;

import android.app.Activity;

import com.faceki.android.FaceKi;
import com.faceki.android.interfaces.KycResponseHandler;
import com.faceki.android.models.VerificationResult;

import org.apache.cordova.*;
import org.json.JSONArray;

public class FacekiBlaze extends CordovaPlugin {

    private CallbackContext callbackContext;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) {

        if (!"startVerification".equals(action)) {
            return false;
        }

        this.callbackContext = callbackContext;

        try {
            String verificationLink = args.getString(0);
            String recordIdentifier = args.optString(1, "default");

            startKyc(verificationLink, recordIdentifier);

            return true;

        } catch (Exception e) {
            callbackContext.error("Invalid arguments: " + e.getMessage());
            return false;
        }
    }

    private void startKyc(String verificationLink, String recordIdentifier) {

        Activity activity = cordova.getActivity();

        activity.runOnUiThread(() -> {

            try {

                FaceKi.startKycVerification(
                        activity,
                        verificationLink,
                        recordIdentifier,
                        kycHandler
                );

            } catch (Exception e) {
                callbackContext.error("SDK start failed: " + e.getMessage());
            }
        });
    }

    // ✅ CALLBACK HANDLER
    private final KycResponseHandler kycHandler = new KycResponseHandler() {

        @Override
        public void handleKycResponse(String json, VerificationResult result) {

            try {
                if (result instanceof VerificationResult.ResultOk) {
                    callbackContext.success(json);   // ✅ return raw JSON string
                }
                else if (result instanceof VerificationResult.ResultCanceled) {
                    callbackContext.error("CANCELLED");
                }
                else {
                    callbackContext.error("UNKNOWN_RESULT");
                }
            } catch (Exception e) {
                callbackContext.error("Processing error: " + e.getMessage());
            }
        }
    };
}

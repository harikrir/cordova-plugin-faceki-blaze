package com.faceki.blaze;

import android.app.Activity;
import android.util.Log;

import com.faceki.android.FaceKi;
import com.faceki.android.interfaces.KycResponseHandler;
import com.faceki.android.models.VerificationResult;

import org.apache.cordova.*;
import org.json.JSONArray;
import org.json.JSONObject;

import java.util.HashMap;

public class FacekiBlaze extends CordovaPlugin {

    private static final String TAG = "FacekiBlaze";

    private CallbackContext callbackContext;
    private boolean isProcessing = false;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) {

        if (!"startVerification".equals(action)) {
            return false;
        }

        if (isProcessing) {
            callbackContext.error("VERIFICATION_ALREADY_RUNNING");
            return true;
        }

        this.callbackContext = callbackContext;

        try {
            String verificationLink = args.getString(0);
            String recordIdentifier = args.optString(1, "default");

            // ✅ Optional branding params
            JSONObject options = args.optJSONObject(2);

            String bgColor = null;
            if (options != null) {
                bgColor = options.optString("backgroundColor", null);
            }

            startKyc(verificationLink, recordIdentifier, bgColor);

            return true;

        } catch (Exception e) {
            callbackContext.error("INVALID_ARGUMENTS: " + e.getMessage());
            return false;
        }
    }

    private void startKyc(String verificationLink, String recordIdentifier, String bgColor) {

        Activity activity = cordova.getActivity();
        isProcessing = true;

        activity.runOnUiThread(() -> {
            try {
                Log.d(TAG, "Starting Faceki verification");

                // ✅ Optional Custom Colors
                if (bgColor != null && !bgColor.isEmpty()) {
                    HashMap<FaceKi.ColorElement, FaceKi.ColorValue> colorMap = new HashMap<>();
                    colorMap.put(
                            FaceKi.ColorElement.BackgroundColor,
                            new FaceKi.ColorValue.StringColor(bgColor)
                    );
                    FaceKi.setCustomColors(colorMap);
                }

                // ✅ Start SDK
                FaceKi.startKycVerification(
                        activity,
                        verificationLink,
                        recordIdentifier,
                        kycHandler
                );

            } catch (Exception e) {
                isProcessing = false;
                callbackContext.error("SDK_START_FAILED: " + e.getMessage());
            }
        });
    }

    // ✅ KYC CALLBACK HANDLER
    private final KycResponseHandler kycHandler = new KycResponseHandler() {

        @Override
        public void handleKycResponse(String json, VerificationResult result) {

            try {
                Log.d(TAG, "KYC response received");

                isProcessing = false;

                JSONObject response = new JSONObject();

                if (result instanceof VerificationResult.ResultOk) {

                    response.put("status", "SUCCESS");

                    if (json != null && !json.isEmpty()) {
                        response.put("data", new JSONObject(json));
                    } else {
                        response.put("data", new JSONObject());
                    }

                    callbackContext.success(response);

                }
                else if (result instanceof VerificationResult.ResultCanceled) {

                    response.put("status", "CANCELLED");
                    callbackContext.error(response.toString());

                }
                else {

                    response.put("status", "UNKNOWN");
                    callbackContext.error(response.toString());
                }

            } catch (Exception e) {
                isProcessing = false;
                callbackContext.error("PROCESSING_ERROR: " + e.getMessage());
            }
        }
    };
}

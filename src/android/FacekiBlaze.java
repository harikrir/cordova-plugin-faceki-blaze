package com.yourplugin;

import android.app.Activity;
import org.apache.cordova.*;
import org.json.JSONArray;
import org.json.JSONObject;

import com.faceki.android.FaceKi; // ✅ ONLY THIS IMPORT

public class FacekiBlaze extends CordovaPlugin {

    private CallbackContext callbackContext;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) {

        if ("startVerification".equals(action)) {

            this.callbackContext = callbackContext;

            try {
                String verificationLink = args.getString(0);
                String recordIdentifier = args.getString(1);

                startKyc(verificationLink, recordIdentifier);

            } catch (Exception e) {
                callbackContext.error("Invalid parameters");
            }

            return true;
        }

        return false;
    }

    private void startKyc(String verificationLink, String recordIdentifier) {

        Activity activity = cordova.getActivity();

        activity.runOnUiThread(() -> {

            FaceKi.startKycVerification(
                activity,
                verificationLink,
                recordIdentifier,

                new FaceKi.KycResponseHandler() { // ✅ FIX HERE
                    @Override
                    public void handleKycResponse(String json, FaceKi.VerificationResult result) { // ✅ FIX HERE

                        try {
                            JSONObject response = new JSONObject();

                            if (result instanceof FaceKi.VerificationResult.ResultOk) {

                                response.put("status", "SUCCESS");
                                response.put("data", json != null ? new JSONObject(json) : new JSONObject());

                                callbackContext.success(response);

                            } else if (result instanceof FaceKi.VerificationResult.ResultCanceled) {

                                response.put("status", "CANCELLED");
                                callbackContext.error(response);
                            }

                        } catch (Exception e) {
                            callbackContext.error("JSON_PARSE_ERROR");
                        }
                    }
                }
            );
        });
    }
}

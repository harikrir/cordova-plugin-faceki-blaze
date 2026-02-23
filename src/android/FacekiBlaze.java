package com.faceki.plugin;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.json.JSONArray;
import org.json.JSONException;

import com.faceki.android.FaceKi; // <-- correct package per FACEKI docs
import com.faceki.android.VerificationResult;
import com.faceki.android.KycResponseHandler;

public class FacekiBlaze extends CordovaPlugin {

    @Override
    public boolean execute(String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
        if ("startVerification".equals(action)) {
            final String verificationLink = args.getString(0);          // link id from FACEKI API (response.data)
            final String recordIdentifier = args.optString(1, "");      // Android expects a record identifier

            cordova.getActivity().runOnUiThread(() -> {
                KycResponseHandler handler = new KycResponseHandler() {
                    @Override
                    public void handleKycResponse(String json, VerificationResult result) {
                        if (result instanceof VerificationResult.ResultOk) {
                            callbackContext.success(json != null ? json : "{}");
                        } else {
                            callbackContext.error("Verification failed or canceled");
                        }
                    }
                };

                FaceKi.startKycVerification(
                    cordova.getActivity(),
                    verificationLink,
                    recordIdentifier,
                    handler
                );
            });
            return true;
        }
        return false;
    }
}

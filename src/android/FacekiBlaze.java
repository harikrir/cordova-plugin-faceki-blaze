package com.faceki.plugin;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.json.JSONArray;
import org.json.JSONException;
import com.faceki.blaze_android_sdk.FaceKi;
import com.faceki.blaze_android_sdk.VerificationResult;

public class FacekiBlaze extends CordovaPlugin {
    @Override
    public boolean execute(String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
        if (action.equals("startVerification")) {
            String url = args.getString(0);
            cordova.getActivity().runOnUiThread(() -> {
                FaceKi.INSTANCE.startKycVerification(
                    cordova.getActivity(),
                    url,
                    "os_request",
                    (json, result) -> {
                        if (result instanceof VerificationResult.ResultOk) {
                            callbackContext.success(json);
                        } else {
                            callbackContext.error("Verification failed");
                        }
                    }
                );
            });
            return true;
        }
        return false;
    }
}

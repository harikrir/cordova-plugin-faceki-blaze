package com.faceki.plugin;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import com.faceki.blaze_android_sdk.FaceKi;
import com.faceki.blaze_android_sdk.KycResponseHandler;
import com.faceki.blaze_android_sdk.VerificationResult;

public class FacekiBlaze extends CordovaPlugin {
    @Override
    public boolean execute(String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
        if (action.equals("startVerification")) {
            String url = args.getString(0);
            this.startFaceki(url, callbackContext);
            return true;
        }
        return false;
    }

    private void startFaceki(String url, final CallbackContext callbackContext) {
        cordova.getActivity().runOnUiThread(new Runnable() {
            public void run() {
                FaceKi.INSTANCE.startKycVerification(
                    cordova.getActivity(),
                    url,
                    "outsystems_record",
                    new KycResponseHandler() {
                        @Override
                        public void handleKycResponse(String json, VerificationResult result) {
                            if (result instanceof VerificationResult.ResultOk) {
                                callbackContext.success(json);
                            } else {
                                callbackContext.error("Verification Canceled or Failed");
                            }
                        }
                    }
                );
            }
        });
    }
}

var exec = require('cordova/exec');

var FacekiBlaze = {

  startVerification: function (verificationLink, recordIdentifier, options) {
    return new Promise(function (resolve, reject) {

      if (!verificationLink) {
        reject("verificationLink is required");
        return;
      }

      exec(
        function (result) {
          try {
            // ✅ Ensure JSON parsing (Android/iOS consistency)
            if (typeof result === 'string') {
              result = JSON.parse(result);
            }
            resolve(result);
          } catch (e) {
            resolve(result); // fallback
          }
        },
        function (err) {
          try {
            if (typeof err === 'string') {
              err = JSON.parse(err);
            }
          } catch (e) {
            // leave as is
          }
          reject(err);
        },
        'FacekiBlaze',
        'startVerification',
        [
          verificationLink,
          recordIdentifier || "",
          options || {}   // ✅ supports future params
        ]
      );
    });
  }
};

module.exports = FacekiBlaze;

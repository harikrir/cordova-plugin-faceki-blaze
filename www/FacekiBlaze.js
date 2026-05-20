var exec = require('cordova/exec');

var FacekiBlaze = {

  startVerification: function (verificationLink, workflowId, options) {
    return new Promise(function (resolve, reject) {

      // ✅ Updated validation
      if (!verificationLink || !workflowId) {
        reject("verificationLink and workflowId are required");
        return;
      }

      console.log("Calling SDK with:");
      console.log("verificationLink:", verificationLink);
      console.log("workflowId:", workflowId);

      exec(
        function (result) {
          try {
            if (typeof result === 'string') {
              result = JSON.parse(result);
            }
            resolve(result);
          } catch (e) {
            resolve(result);
          }
        },
        function (err) {
          try {
            if (typeof err === 'string') {
              err = JSON.parse(err);
            }
          } catch (e) {}
          reject(err);
        },
        'FacekiBlaze',
        'startVerification',
        [
          verificationLink,
          workflowId,
          options || {} // optional, ignored by native currently
        ]
      );
    });
  }
};

module.exports = FacekiBlaze;

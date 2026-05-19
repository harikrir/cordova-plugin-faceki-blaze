var exec = require('cordova/exec');

var FacekiBlaze = {

  startVerification: function (clientId, clientSecret, workflowId, options) {
    return new Promise(function (resolve, reject) {

      if (!clientId || !clientSecret || !workflowId) {
        reject("clientId, clientSecret, and workflowId are required");
        return;
      }

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
          clientId,
          clientSecret,
          workflowId,
          options || {}
        ]
      );
    });
  }
};

module.exports = FacekiBlaze;

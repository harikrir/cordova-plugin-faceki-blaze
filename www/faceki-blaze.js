var exec = require('cordova/exec');

var FacekiBlaze = {
  /**
   * @param {string} verificationLink - UUID from FACEKI "Generate KYC Link" API (response.data)
   * @param {string} recordIdentifier  - Optional identifier you track on Android (pass "" on iOS if not used)
   * @returns {Promise<string>} JSON string payload from FACEKI
   */
  startVerification: function (verificationLink, recordIdentifier) {
    return new Promise(function (resolve, reject) {
      exec(resolve, reject, 'FacekiBlaze', 'startVerification', [verificationLink, recordIdentifier]);
    });
  }
};

module.exports = FacekiBlaze;

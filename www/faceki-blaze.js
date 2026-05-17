var exec = require('cordova/exec');

var FacekiBlaze = {
  startVerification: function (verificationLink, recordIdentifier) {
    return new Promise(function (resolve, reject) {
      exec(resolve, reject, 'FacekiBlaze', 'startVerification', [verificationLink, recordIdentifier]);
    });
  }
};

module.exports = FacekiBlaze;

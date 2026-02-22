var exec = require('cordova/exec');

exports.startVerification = function (verificationUrl, success, error) {
    exec(success, error, 'FacekiBlaze', 'startVerification', [verificationUrl]);
};

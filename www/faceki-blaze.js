var exec = require('cordova/exec');

exports.startVerification = function (url, success, error) {
    exec(success, error, 'FacekiBlaze', 'startVerification', [url]);
};

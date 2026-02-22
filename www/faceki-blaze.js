var exec = require('cordova/exec');

/**
 * FacekiBlaze JavaScript Interface
 */
var FacekiBlaze = {
    startVerification: function (verificationUrl, success, error) {
        // The third parameter 'FacekiBlaze' must match the <feature name="..."> in plugin.xml
        // The fourth parameter 'startVerification' must match the action string in your Native code
        exec(success, error, 'FacekiBlaze', 'startVerification', [verificationUrl]);
    }
};

module.exports = FacekiBlaze;

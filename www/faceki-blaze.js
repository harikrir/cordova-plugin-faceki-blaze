var exec = require('cordova/exec');

var FacekiBlaze = {
    // Now accepting both URL and WorkflowID
    startVerification: function (verificationUrl, workflowId, success, error) {
        exec(success, error, 'FacekiBlaze', 'startVerification', [verificationUrl, workflowId]);
    }
};

module.exports = FacekiBlaze;

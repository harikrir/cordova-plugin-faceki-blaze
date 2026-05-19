#import "FacekiBlaze.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <FACEKI_BLAZE_IOS/FACEKI_BLAZE_IOS-Swift.h> // Adjust if needed

@interface FacekiBlaze ()

@property (nonatomic, strong) NSString *callbackId;
@property (nonatomic, assign) BOOL isProcessing;

@end

@implementation FacekiBlaze

- (void)startVerification:(CDVInvokedUrlCommand *)command {

    // ✅ Prevent multiple calls
    if (self.isProcessing) {
        [self sendError:@"VERIFICATION_ALREADY_RUNNING"];
        return;
    }

    self.callbackId = command.callbackId;

    // ✅ Validate arguments
    if (command.arguments.count < 1) {
        [self sendError:@"verificationLink is required"];
        return;
    }

    id verificationArg = command.arguments[0];
    if (![verificationArg isKindOfClass:[NSString class]]) {
        [self sendError:@"Invalid verificationLink"];
        return;
    }

    NSString *verificationLink = (NSString *)verificationArg;

    // ✅ Optional workflowId
    NSString *workflowId = @"";
    if (command.arguments.count > 1) {
        id wfArg = command.arguments[1];
        if ([wfArg isKindOfClass:[NSString class]]) {
            workflowId = (NSString *)wfArg;
        }
    }

    self.isProcessing = YES;

    dispatch_async(dispatch_get_main_queue(), ^{

        UIViewController *sdkVC = [Logger initiateSMSDKWithVerificationLink:verificationLink
                                                                 workflowId:workflowId
                                                              setOnComplete:^(NSDictionary * _Nonnull data) {
            [self onComplete:data];
        }
                                                               redirectBack:^{
            [self onRedirectBack];
        }
                                                          selfieImageUrl:nil
                                                            cardGuideUrl:nil];

        // ✅ Navigation handling
        if (self.viewController.navigationController) {
            [self.viewController.navigationController pushViewController:sdkVC animated:YES];
        } else {
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:sdkVC];
            [self.viewController presentViewController:navController animated:YES completion:nil];
        }
    });
}

#pragma mark - Callbacks

// ✅ SUCCESS CALLBACK
- (void)onComplete:(NSDictionary *)data {

    @try {
        self.isProcessing = NO;

        NSMutableDictionary *response = [NSMutableDictionary dictionary];
        response[@"status"] = @"SUCCESS";
        response[@"data"] = data;

        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:response options:0 error:nil];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonString];
        [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];

    } @catch (NSException *exception) {
        self.isProcessing = NO;
        [self sendError:@"PROCESSING_ERROR"];
    }
}

// ✅ USER EXIT / BACK ACTION
- (void)onRedirectBack {

    dispatch_async(dispatch_get_main_queue(), ^{

        self.isProcessing = NO;

        if (self.viewController.navigationController) {
            [self.viewController.navigationController popToViewController:self.viewController animated:YES];
        } else {
            [self.viewController dismissViewControllerAnimated:YES completion:nil];
        }

        NSDictionary *response = @{@"status": @"CANCELLED"};
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:response options:0 error:nil];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:jsonString];
        [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
    });
}

#pragma mark - Error Handler

- (void)sendError:(NSString *)message {

    self.isProcessing = NO;

    NSDictionary *response = @{
        @"status": @"ERROR",
        @"message": message
    };

    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:response options:0 error:&error];

    CDVPluginResult *result;

    if (!error && jsonData) {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:jsonString];
    } else {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:message];
    }

    [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
}

@end

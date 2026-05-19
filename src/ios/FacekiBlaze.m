#import "FacekiBlaze.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Cordova/CDV.h>

@import FACEKI_BLAZE_IOS;

@interface FacekiBlaze ()

@property (nonatomic, strong) NSString *callbackId;
@property (nonatomic, assign) BOOL isProcessing;

@end

@implementation FacekiBlaze

- (void)startVerification:(CDVInvokedUrlCommand *)command {

    if (self.isProcessing) {
        [self sendError:@"VERIFICATION_ALREADY_RUNNING"];
        return;
    }

    self.callbackId = command.callbackId;

    // ✅ Expecting arguments:
    // [clientId, clientSecret, workflowId]

    if (command.arguments.count < 3) {
        [self sendError:@"clientId, clientSecret, workflowId required"];
        return;
    }

    NSString *clientId = command.arguments[0];
    NSString *clientSecret = command.arguments[1];
    NSString *workflowId = command.arguments[2];

    if (![clientId isKindOfClass:[NSString class]] ||
        ![clientSecret isKindOfClass:[NSString class]] ||
        ![workflowId isKindOfClass:[NSString class]]) {

        [self sendError:@"Invalid parameters"];
        return;
    }

    self.isProcessing = YES;

    dispatch_async(dispatch_get_main_queue(), ^{

        UIViewController *sdkVC = nil;

        // ✅ Correct class lookup
        Class loggerClass = NSClassFromString(@"Logger");

        if (!loggerClass) {
            NSLog(@"Faceki ERROR: Logger class NOT found");
            self.isProcessing = NO;
            [self sendError:@"SDK_CLASS_NOT_FOUND"];
            return;
        }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

        // ✅ ✅ CORRECT selector (based on SDK)
        SEL selector = NSSelectorFromString(
            @"initiateSMSDKWithSetClientID:setClientSecret:workflowId:setOnComplete:redirectBack:selfieImageUrl:cardGuideUrl:"
        );

        if (![loggerClass respondsToSelector:selector]) {
            NSLog(@"Faceki ERROR: Selector NOT found");
            self.isProcessing = NO;
            [self sendError:@"SDK_METHOD_NOT_FOUND"];
            return;
        }

        // ✅ Function pointer
        IMP imp = [loggerClass methodForSelector:selector];

        UIViewController *(*func)(id, SEL, NSString *, NSString *, NSString *, id, id, id, id) = (void *)imp;

        sdkVC = func(
            loggerClass,
            selector,
            clientId,
            clientSecret,
            workflowId,
            ^(NSDictionary *data) {
                [self onComplete:data];
            },
            ^{
                [self onRedirectBack];
            },
            nil,
            nil
        );

#pragma clang diagnostic pop

        if (!sdkVC) {
            NSLog(@"Faceki ERROR: SDK returned nil VC");
            self.isProcessing = NO;
            [self sendError:@"SDK_INIT_FAILED"];
            return;
        }

        // ✅ Navigation
        if (self.viewController.navigationController) {
            [self.viewController.navigationController pushViewController:sdkVC animated:YES];
        } else {
            UINavigationController *navController =
            [[UINavigationController alloc] initWithRootViewController:sdkVC];

            [self.viewController presentViewController:navController animated:YES completion:nil];
        }
    });
}

#pragma mark - Callbacks

- (void)onComplete:(NSDictionary *)data {

    @try {
        self.isProcessing = NO;

        NSMutableDictionary *response = [NSMutableDictionary dictionary];
        response[@"status"] = @"SUCCESS";
        response[@"data"] = data;

        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:response options:0 error:nil];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

        CDVPluginResult *result =
        [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonString];

        [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];

    } @catch (NSException *exception) {
        self.isProcessing = NO;
        [self sendError:@"PROCESSING_ERROR"];
    }
}

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

        CDVPluginResult *result =
        [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:jsonString];

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


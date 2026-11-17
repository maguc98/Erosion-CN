#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <sys/sysctl.h>
#import <math.h>

static NSString * const kPreferenceDomain = @"com.maguc98.dynamicislandoffsetprefs";
static NSString * const kSettingsChangedNotification = @"com.maguc98.dynamicislandoffsetprefs/changed";
static NSString * const kRespringNotification = @"com.maguc98.dynamicislandoffsetprefs/respring";

static BOOL gOffsetEnabled = NO;
static CGFloat gYOffset = 30.0;

static char kBaseYAssociationKey;
static char kLastAppliedYAssociationKey;

@interface FBSystemService : NSObject
+ (instancetype)sharedInstance;
- (void)exitAndRelaunch:(BOOL)restart;
@end

static NSString *IOHardwareModel(void) {
    size_t size = 0;
    if (sysctlbyname("hw.machine", NULL, &size, NULL, 0) != 0 || size == 0) {
        return nil;
    }

    char *machine = (char *)calloc(size, sizeof(char));
    if (!machine) {
        return nil;
    }

    NSString *result = nil;
    if (sysctlbyname("hw.machine", machine, &size, NULL, 0) == 0) {
        result = [NSString stringWithUTF8String:machine];
    }
    free(machine);
    return result;
}

static void IOApplySettings(void) {
    @autoreleasepool {
        CFStringRef domain = (__bridge CFStringRef)kPreferenceDomain;
        CFPreferencesAppSynchronize(domain);

        NSDictionary *prefs = [[NSUserDefaults standardUserDefaults] persistentDomainForName:kPreferenceDomain];
        id enabledValue = prefs[@"Enabled"];
        id offsetValue = prefs[@"YOffset"];

        gOffsetEnabled = [enabledValue respondsToSelector:@selector(boolValue)]
            ? [enabledValue boolValue] : NO;

        CGFloat proposedOffset = [offsetValue respondsToSelector:@selector(doubleValue)]
            ? [offsetValue doubleValue] : 30.0;

        // Fail closed on invalid settings. The control is deliberately bounded.
        if (!isfinite(proposedOffset) || proposedOffset < 0.0 || proposedOffset > 80.0) {
            proposedOffset = 30.0;
        }
        gYOffset = proposedOffset;
    }
}

static void IORefreshApertureWindows(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        Class apertureClass = NSClassFromString(@"SBSystemApertureWindow");
        if (!apertureClass) {
            return;
        }

        UIApplication *application = [UIApplication sharedApplication];
        for (UIScene *scene in application.connectedScenes) {
            if (![scene isKindOfClass:[UIWindowScene class]]) {
                continue;
            }
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            for (UIWindow *window in windowScene.windows) {
                if ([window isKindOfClass:apertureClass]) {
                    [window setNeedsLayout];
                    [window layoutIfNeeded];
                }
            }
        }
    });
}

static void IOSettingsChanged(CFNotificationCenterRef center,
                              void *observer,
                              CFStringRef name,
                              const void *object,
                              CFDictionaryRef userInfo) {
    IOApplySettings();
    IORefreshApertureWindows();
}

static void IORespringRequested(CFNotificationCenterRef center,
                                void *observer,
                                CFStringRef name,
                                const void *object,
                                CFDictionaryRef userInfo) {
    Class serviceClass = NSClassFromString(@"FBSystemService");
    SEL sharedSelector = @selector(sharedInstance);
    SEL restartSelector = @selector(exitAndRelaunch:);

    if (!serviceClass || ![serviceClass respondsToSelector:sharedSelector]) {
        NSLog(@"[DynamicIslandOffset] FBSystemService is unavailable; respring manually.");
        return;
    }

    id service = ((id (*)(id, SEL))objc_msgSend)(serviceClass, sharedSelector);
    if ([service respondsToSelector:restartSelector]) {
        ((void (*)(id, SEL, BOOL))objc_msgSend)(service, restartSelector, YES);
    }
}

@interface SBSystemApertureWindow : UIView
@end

%group SpringBoardHooks

%hook SBSystemApertureWindow

- (void)layoutSubviews {
    %orig;

    // This build intentionally targets the physical iPhone 12 mini only.
    // ProductType spoofing is not used as a device detector.
    if (![IOHardwareModel() isEqualToString:@"iPhone13,1"]) {
        return;
    }

    CGRect frame = self.frame;
    if (!isfinite(frame.origin.y)) {
        return;
    }

    NSNumber *baseYValue = objc_getAssociatedObject(self, &kBaseYAssociationKey);
    NSNumber *lastYValue = objc_getAssociatedObject(self, &kLastAppliedYAssociationKey);

    // If the system has laid out a new frame, adopt its Y as the new baseline.
    // If our previous position is still present, retain the original baseline
    // so repeated layout passes do not accumulate the offset.
    if (!baseYValue || !lastYValue ||
        fabs(frame.origin.y - lastYValue.doubleValue) > 0.75) {
        baseYValue = @(frame.origin.y);
        objc_setAssociatedObject(self, &kBaseYAssociationKey,
                                 baseYValue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    CGFloat offset = gOffsetEnabled ? gYOffset : 0.0;
    CGFloat targetY = baseYValue.doubleValue + offset;

    if (fabs(frame.origin.y - targetY) > 0.75) {
        frame.origin.y = targetY;
        objc_setAssociatedObject(self, &kLastAppliedYAssociationKey,
                                 @(targetY), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        self.frame = frame;
    } else {
        objc_setAssociatedObject(self, &kLastAppliedYAssociationKey,
                                 @(targetY), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

%end
%end

%ctor {
    @autoreleasepool {
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        if (![bundleID isEqualToString:@"com.apple.springboard"]) {
            return;
        }

        IOApplySettings();

        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            NULL,
            IOSettingsChanged,
            (__bridge CFStringRef)kSettingsChangedNotification,
            NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately
        );

        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            NULL,
            IORespringRequested,
            (__bridge CFStringRef)kRespringNotification,
            NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately
        );

        Class apertureClass = NSClassFromString(@"SBSystemApertureWindow");
        if (apertureClass &&
            class_getInstanceMethod(apertureClass, @selector(layoutSubviews))) {
            %init(SpringBoardHooks);
            NSLog(@"[DynamicIslandOffset] Hook installed. Hardware=%@ enabled=%d offset=%.1fpt",
                  IOHardwareModel(), gOffsetEnabled, (double)gYOffset);
        } else {
            NSLog(@"[DynamicIslandOffset] SBSystemApertureWindow/layoutSubviews not found on this OS; no hook installed.");
        }
    }
}

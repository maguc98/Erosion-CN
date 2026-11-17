#import "IOCRootListController.h"
#import <CoreFoundation/CoreFoundation.h>
#import <UIKit/UIKit.h>

@implementation IOCRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

- (void)requestRespring:(id)sender {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"重新启动 SpringBoard"
        message:@"应用位置调整设置需要重新启动系统界面。"
        preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];

    [alert addAction:[UIAlertAction actionWithTitle:@"重新启动"
                                              style:UIAlertActionStyleDestructive
                                            handler:^(__unused UIAlertAction *action) {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFSTR("com.maguc98.dynamicislandoffsetprefs/respring"),
            NULL,
            NULL,
            YES
        );
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

@end

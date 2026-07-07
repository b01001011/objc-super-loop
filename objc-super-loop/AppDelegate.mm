#import "AppDelegate.h"
#import "WindowController.h"

#import <UserNotifications/UserNotifications.h>
#import <sys/event.h>

static void callout(CFFileDescriptorRef fdref, CFOptionFlags callBackTypes, void *info) {
    NSLog(@"# callout");
    if (callBackTypes & kCFFileDescriptorReadCallBack) {
        int kq = CFFileDescriptorGetNativeDescriptor(fdref);
        struct kevent event;
        
        struct timespec timeout = { 0, 0 };
        int result = kevent(kq, NULL, 0, &event, 1, &timeout);
        if (result > 0) {
            NSLog(@"kqueue event detected.");
            CFFileDescriptorEnableCallBacks(fdref, kCFFileDescriptorReadCallBack);
        } else if (result == -1) {
            perror("kevent");
        }
    }
}

@interface AppDelegate () <UNUserNotificationCenterDelegate>


@end

@implementation AppDelegate {
    int _fd;
    CFFileDescriptorRef _fd_ref;
    
    WindowController* _windowController;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    if(_windowController == nil) {
        _windowController = [WindowController new];
    }
    
    [_windowController.window orderFront:self];
    
    UNUserNotificationCenter *unc = UNUserNotificationCenter.currentNotificationCenter;
    unc.delegate = self;
    UNAuthorizationOptions opts = UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge;
    
    [unc requestAuthorizationWithOptions:opts completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (!granted) {
            NSLog(@"# Failed %@", error);
        }
    }];
    
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = @"Hello";
    content.body = @"This is a test notification.";
    content.sound = [UNNotificationSound defaultSound];

    UNTimeIntervalNotificationTrigger *trigger =
        [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];

    UNNotificationRequest *request =
        [UNNotificationRequest requestWithIdentifier:@"TestNotification"
                                             content:content
                                             trigger:trigger];

    [[UNUserNotificationCenter currentNotificationCenter]
        addNotificationRequest:request
        withCompletionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"Failed to schedule notification: %@", error);
            } else {
                NSLog(@"Notification scheduled.");
            }
        }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self->_fd = ::kqueue();
        
        self->_fd_ref = CFFileDescriptorCreate(kCFAllocatorDefault, self->_fd, true, callout, nullptr);
        CFRunLoopSourceRef source = CFFileDescriptorCreateRunLoopSource(kCFAllocatorDefault, self->_fd_ref, 0);
        CFRunLoopAddSource(CFRunLoopGetMain(), source, kCFRunLoopDefaultMode);
        CFRelease(source);
        
        CFFileDescriptorEnableCallBacks(self->_fd_ref, kCFFileDescriptorReadCallBack);
        
        while(true) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSDate *expiration = nil;
                
                NSEvent *event = [NSApp nextEventMatchingMask:NSEventMaskAny untilDate:expiration inMode:NSDefaultRunLoopMode dequeue:YES];
                
                if(event.type == 14) {
                    NSLog(@"# %@", event);
                }
                
                if ([NSThread isMainThread]) {
                    NSEvent *e = [NSApp currentEvent];
                    [NSApp sendEvent:e];
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSEvent *e = [NSApp currentEvent];
                        [NSApp sendEvent:e];
                    });
                }
            });
            usleep(5000);
        }
    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Another block on the main thread.");
    });
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void (^)(void))completionHandler
{

    NSString *identifier = response.notification.request.identifier;
    NSDictionary *userInfo = response.notification.request.content.userInfo;
    
    NSLog(@"Notification clicked!");
    NSLog(@"Identifier: %@", identifier);
    NSLog(@"UserInfo: %@", userInfo);

    [NSApp activateIgnoringOtherApps:YES];
    [_windowController.window makeKeyAndOrderFront:self];

    completionHandler();
}

@end

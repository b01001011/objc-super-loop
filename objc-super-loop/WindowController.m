#import "WindowController.h"
#import "ViewController.h"

@interface WindowController ()

@end

@implementation WindowController

- (id)init {
    self = [super init];
    if(self) {
        NSPanel* panel = [
            [NSPanel alloc]
            initWithContentRect:NSZeroRect
            styleMask: NSWindowStyleMaskTitled | NSWindowStyleMaskClosable
            backing:NSBackingStoreBuffered
            defer:YES
        ];
        
        panel.floatingPanel = YES;
        panel.titlebarAppearsTransparent = YES;
        [panel setFrame:NSMakeRect(0, 0, 720, 480) display:YES animate:NO];
        
        ViewController* controller = [ViewController new];
        
        [panel setContentViewController:controller];
        [panel setRestorable:NO];
        [panel center];
        self.window = panel;
    }
    return self;
}

@end

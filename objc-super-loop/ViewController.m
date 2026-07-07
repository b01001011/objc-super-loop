#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)mouseDown:(NSEvent *)event {
    [super mouseDown:event];
    NSLog(@"# mouseDown");
}

@end

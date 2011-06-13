// Code taken from http://www.cocoabuilder.com/archive/cocoa/147000-fullscreen-enter-exit-notification-after-panther.html#147073

#import "FullscreenNotifier.h"

#import <Carbon/Carbon.h>
#import <ApplicationServices/ApplicationServices.h>

id target;
SEL enterSelector, exitSelector;

OSErr menuBarShownHidden(EventHandlerCallRef inHandlerRef, EventRef inEvent, void *data)
{
    if (GetEventKind(inEvent) == kEventMenuBarHidden) {
        if (target && enterSelector) {
            [target performSelector:enterSelector];
        }
    } else {
        if (target && exitSelector) {
            [target performSelector:exitSelector];
        }
    }
    
    return 0;
}



@implementation FullscreenNotifier

- (id)init
{
    self = [super init];
    if (self) {
        EventTypeSpec opts[] = {
            { kEventClassMenu, kEventMenuBarShown },
            { kEventClassMenu, kEventMenuBarHidden }
        };
        
        OSStatus err;
        err = InstallEventHandler(GetEventDispatcherTarget(),
                                  NewEventHandlerUPP((EventHandlerProcPtr)menuBarShownHidden),
                                  2, opts, nil, nil);
        
        if (err != 0) {
            NSLog(@"Error: InstallEventHandler %d",err);
        }
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)setFullscreenCallbackTarget:(id)target_ enterSelector:(SEL)enterSel exitSelector:(SEL)exitSel
{
    target        = target_;
    enterSelector = enterSel;
    exitSelector  = exitSel;
}

@end

#import "FullscreenNotifier.h"

#import <Carbon/Carbon.h>

/**
 
 The FullscreenNotifier sends out notifications whenever the primary screen (the
 one with the menu bar) enters or exits the fullscreen mode (e.g. when playing
 a game or watching a movie).
 
 
 About the implementation:
 
 When the menu bar is shown or hidden, a timer with a delay of <delay> is
 started to perform an appropriate action (post a notification).
 When a workspace change is triggered, a timer with a delay of <delay>/2 is
 started to check if the new space is running a fullscreen app. If it does, the
 menu bar timer will be canceled and the appropriate action will be performed
 after a delay of <delay>/2.
 
 Because both events can happen at the same time, the actual action will not be
 triggered before <delay>. When the menu bar is shown (not hidden), the fullscreen
 mode has definitely been changed. When the workspace is changed, the fullscreen
 mode could have been changed, when the new space is running a fullscreen app on
 another screen. Example: if there was a fullscreen app on the primary screen
 before, and there now is a fullscreen app on a secondary screen, then the menu
 bar is still hidden, but the fullscreen mode of the primary screen has changed.
 
*/


const NSTimeInterval delay = 0.01;

static FullscreenNotifier *sharedFullscreenNotifier;


OSErr menuBarVisibilityChangedCallback(EventHandlerCallRef inHandlerRef, EventRef inEvent, void *fullscreenNotifier)
{
    return [(FullscreenNotifier *)fullscreenNotifier performSelector:@selector(menuBarVisibilityChanged:) withObject:(id)inEvent];
}


@interface FullscreenNotifier ()

@property (getter=isFullscreenMode) BOOL fullscreenMode;
@property (getter=isMenuBarVisible) BOOL menuBarVisible;

@property id target;
@property SEL enterSelector;
@property SEL exitSelector;

@property (retain) NSTimer *timer;


- (void)workspaceChanged:(id)trigger;
- (OSErr)menuBarVisibilityChanged:(EventRef)event;

- (void)fullscreenModeCouldHaveChanged:(id)trigger;

- (void)enterFullscreenMode;
- (void)exitFullscreenMode;

- (BOOL)hasOpenWindowOnPrimaryScreen;

@end

@implementation FullscreenNotifier

+ (FullscreenNotifier *)sharedFullscreenNotifier
{
    return sharedFullscreenNotifier;
}

+ (void)initialize
{
    static BOOL initialized = NO;
    
    if (!initialized) {
        sharedFullscreenNotifier = [FullscreenNotifier new];
        initialized = YES;
    }
}

- (id)init
{
    self = [super init];
    if (self) {
        EventTypeSpec events[] = {
            { kEventClassMenu, kEventMenuBarShown },
            { kEventClassMenu, kEventMenuBarHidden }
        };
        
        InstallEventHandler(GetEventDispatcherTarget(), NewEventHandlerUPP((EventHandlerProcPtr)menuBarVisibilityChangedCallback), 2, events, self, nil);
        
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(workspaceChanged:) name:NSWorkspaceActiveSpaceDidChangeNotification object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
    [self.timer release];
    [super dealloc];
}

- (void)setFullscreenCallbackTarget:(id)target_ enterSelector:(SEL)enterSel exitSelector:(SEL)exitSel
{
    self.target        = target_;
    self.enterSelector = enterSel;
    self.exitSelector  = exitSel;
}

#pragma mark -

- (void)workspaceChanged:(id)trigger
{
    // NSWorkspaceActiveSpaceDidChangeNotification can arrive before kEventMenuBarShown/Hidden but we rely on calculations done in that listener.
    // therefore we have to wait a little (on another thread)
    [self.timer invalidate];
    [NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector(fullscreenModeCouldHaveChanged:) userInfo:nil repeats:NO];
}

- (OSErr)menuBarVisibilityChanged:(EventRef)event
{
    if (GetEventKind(event) == kEventMenuBarHidden) {
        self.menuBarVisible = NO;
    } else {
        self.menuBarVisible = YES;
    }
    
    [self.timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector(fullscreenModeCouldHaveChanged:) userInfo:nil repeats:NO];
    
    return noErr;
}

- (void)fullscreenModeCouldHaveChanged:(id)trigger
{
    if (!self.isMenuBarVisible && self.hasOpenWindowOnPrimaryScreen) {
        [self enterFullscreenMode];
    } else if (self.isFullscreenMode) {
        [self exitFullscreenMode];
    }
}

- (void)enterFullscreenMode
{
    self.fullscreenMode = YES;
    
    if (self.target && self.enterSelector) {
        [self.target performSelector:self.enterSelector];
    }
}

- (void)exitFullscreenMode
{
    self.fullscreenMode = NO;
    
    if (self.target && self.exitSelector) {
        [self.target performSelector:self.exitSelector];
    }
}

- (BOOL)hasOpenWindowOnPrimaryScreen
{
    NSArray *windowNumbers = CFBridgingRelease(CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements, kCGNullWindowID));
    CGRect primaryScreenFrame = NSRectToCGRect([[[NSScreen screens] objectAtIndex:0] frame]);
    BOOL result = NO;
    
    for (NSDictionary *info in windowNumbers) {
        if ([[info objectForKey:(id)kCGWindowSharingState] intValue] != kCGWindowSharingNone &&
            [[info objectForKey:(id)kCGWindowLayer] intValue] >= 0) // the linen pattern windows of the native (lion) fullscreen impl have a layer of -1
        {
            CGRect bounds;
            CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)[info objectForKey:(id)kCGWindowBounds], &bounds);
            
            if (CGRectContainsRect(primaryScreenFrame, bounds)) {
                result = YES;
                break;
            }
        }
    }
    
    return result;
}


@end

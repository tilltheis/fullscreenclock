//
//  ClocksController.m
//  fullscreenclock
//
//  Created by Till Theis on 23.12.13.
//  Copyright (c) 2013 Till Theis. All rights reserved.
//

#import "ClocksController.h"
#import "FullscreenObserver.h"
#import "ClockView.h"


NSString *const ClocksControllerVisibleKeyPath = @"visible";
NSString *const ClocksControllerBackgroundAlphaKeyPath = @"backgroundAlpha";
NSString *const ClocksControllerFaceAlphaKeyPath = @"faceAlpha";
NSString *const ClocksControllerHandsAlphaKeyPath = @"handsAlpha";

NSString *const ScreensKeyPath = @"screens";


@interface ClocksController ()

@property (assign, getter = isVisible) BOOL visible;
@property (strong) NSArray *windows;
@property (weak) FullscreenObserver *fullscreenObserver;
@property (strong) NSTimer *minuteTimer;

@end

@implementation ClocksController

- (id)initWithScreens:(NSArray *)screens backgroundAlpha:(CGFloat)backgroundAlpha handsAlpha:(CGFloat)handsAlpha faceAlpha:(CGFloat)faceAlpha
{
    self = [super init];

    if (self) {
        self.backgroundAlpha = backgroundAlpha;
        self.handsAlpha = handsAlpha;
        self.faceAlpha = faceAlpha;
        
        // call this last because it uses the alpha values
        self.screens = screens;
//        self.windows has been set by [self setScreens:]
        
        self.fullscreenObserver = [FullscreenObserver sharedFullscreenObserver];
        [self.fullscreenObserver addObserver:self forKeyPath:FullscreenObserverFullscreenModeKeyPath options:NSKeyValueObservingOptionNew context:nil];
        
        // start/stop minute timer automatically when visibility changes
        [self addObserver:self forKeyPath:ClocksControllerVisibleKeyPath options:NSKeyValueObservingOptionNew context:nil];
    }
    
    return self;
}

- (void)setBackgroundAlpha:(float)backgroundAlpha
{
    [self willChangeValueForKey:ClocksControllerBackgroundAlphaKeyPath];
    _backgroundAlpha = backgroundAlpha;
    [self.windows makeObjectsPerformSelector:@selector(setBackgroundColor:) withObject:[self windowBackgroundColorForAlpha:backgroundAlpha]];
    [self didChangeValueForKey:ClocksControllerBackgroundAlphaKeyPath];
}

- (void)setFaceAlpha:(float)faceAlpha
{
    [self willChangeValueForKey:ClocksControllerFaceAlphaKeyPath];
    _faceAlpha = faceAlpha;
    for (NSWindow *window in self.windows) {
        [(ClockView *)[window contentView] setFaceAlpha:faceAlpha];
    }
    [self didChangeValueForKey:ClocksControllerFaceAlphaKeyPath];
}

- (void)setHandsAlpha:(float)handsAlpha
{
    [self willChangeValueForKey:ClocksControllerHandsAlphaKeyPath];
    _handsAlpha = handsAlpha;
    for (NSWindow *window in self.windows) {
        [(ClockView *)[window contentView] setHandsAlpha:handsAlpha];
    }
    [self didChangeValueForKey:ClocksControllerHandsAlphaKeyPath];
}

- (void)windowWillClose:(NSNotification *)notification
{
    // a single clock window will close
    self.visible = [[NSPredicate predicateWithFormat:@"@sum.isVisible > 1"] evaluateWithObject:self.windows];
}

- (void)show
{
    self.visible = YES;
    [self.windows makeObjectsPerformSelector:@selector(orderFront:) withObject:self];
}

- (void)hide
{
    self.visible = NO;
    [self.windows makeObjectsPerformSelector:@selector(close)];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.fullscreenObserver && [keyPath isEqualToString:FullscreenObserverFullscreenModeKeyPath]) {
        if ([[change objectForKey:NSKeyValueChangeNewKey] boolValue]) {
            [self show];
        } else {
            [self hide];
        }
    } else if (object == self && [keyPath isEqualToString:ClocksControllerVisibleKeyPath]) {
        if ([[change objectForKey:NSKeyValueChangeNewKey] boolValue]) {
            // start timer
            NSTimeInterval oneMinute = 60;
            NSDate *now = [NSDate date];
            NSInteger elapsedSeconds = [[NSCalendar currentCalendar] component:NSSecondCalendarUnit fromDate:now];
            NSDate *nextMinute = [now dateByAddingTimeInterval:oneMinute - elapsedSeconds];
            
            self.minuteTimer = [[NSTimer alloc] initWithFireDate:nextMinute interval:oneMinute target:self selector:@selector(updateClockViewTimes:) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:self.minuteTimer forMode:NSDefaultRunLoopMode];
            
            // set current time
            [self updateClockViewTimes:nil];
        } else {
            // stop timer
            [self.minuteTimer invalidate];
            self.minuteTimer = nil;
        }
    }
}

- (void)updateClockViewTimes:(NSTimer *)timer
{
    NSDate *now = [NSDate date];
    for (NSWindow *window in self.windows) {
        ClockView *view = [window contentView];
        [view setTime:now];
    }
}

- (void)setScreens:(NSArray *)screens
{
    [self willChangeValueForKey:ScreensKeyPath];
    _screens = screens;
    self.windows = [self createWindowsForScreens:screens];
    if (self.isVisible) {
        [self show];
    }
    [self didChangeValueForKey:ScreensKeyPath];
}

- (NSArray *)createWindowsForScreens:(NSArray *)screens
{
    NSMutableArray *windows = [NSMutableArray arrayWithCapacity:[screens count]];
    
    [screens enumerateObjectsUsingBlock:^(id screen, NSUInteger idx, BOOL *stop) {
        // screen is included in frame coordinates
        NSWindow *window = [[NSWindow alloc] initWithContentRect:[screen frame] styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
        
        [window setReleasedWhenClosed:NO];
        [window setOpaque:NO];
        [window setLevel:NSMainMenuWindowLevel + 1]; // above menu bar
        [window setBackgroundColor:[self windowBackgroundColorForAlpha:self.backgroundAlpha]];
        [window setHasShadow:NO];
        [window setAnimationBehavior:NSWindowAnimationBehaviorUtilityWindow]; // enable fading
        [window setDelegate:self];
        
        ClockView *view = [[ClockView alloc] initWithFrame:[screen frame] faceAlpha:self.faceAlpha handsAlpha:self.handsAlpha time:[NSDate date]];
        [window setContentView:view];
        
        [windows addObject:window];
    }];
    
    return windows;
}

- (NSColor *)windowBackgroundColorForAlpha:(CGFloat)alpha
{
    return [NSColor colorWithCalibratedWhite:0 alpha:alpha];
}

@end

//
//  AppDelegate.m
//  fullscreenclock
//
//  Created by Till Theis on 23.12.13.
//  Copyright (c) 2013 Till Theis. All rights reserved.
//

#import "AppDelegate.h"
#import "ClocksController.h"
#import "ClockView.h"


static NSString *const ShowMenuBarIconKey = @"show_menu_bar_icon";
static NSString *const BackgroundAlphaKey = @"background_alpha";
static NSString *const FaceAlphaKey = @"face_alpha";
static NSString *const HandsAlphaKey = @"hands_alpha";

static NSString *const UserDefaultsResourceName = @"UserDefaults";
static NSString *const UserDefaultsResourceType = @"plist";

static NSString *const ShowClocksUIString = @"Show Clocks";
static NSString *const HideClocksUIString = @"Hide Clocks";


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self initDefaults];
    
    // init clocks controller (together with its properties)
    self.clocksController = [[ClocksController alloc] initWithScreens:[self secondaryScreens] backgroundAlpha:[self.defaults floatForKey:BackgroundAlphaKey] handsAlpha:[self.defaults floatForKey:HandsAlphaKey] faceAlpha:[self.defaults floatForKey:FaceAlphaKey]];
    [self.clocksController addObserver:self forKeyPath:ClocksControllerVisibleKeyPath options:NSKeyValueObservingOptionNew context:nil];
    
    [self.window setReleasedWhenClosed:NO];
    [self.window setLevel:NSMainMenuWindowLevel + 2]; // above menu bar and clock windows
    
    if ([self.defaults boolForKey:ShowMenuBarIconKey]) {
        [self showMenuBarIcon];
    }
    
        
    [self.clocksController bind:ClocksControllerBackgroundAlphaKeyPath toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[@"values." stringByAppendingString:BackgroundAlphaKey] options:nil];
    [self.clocksController bind:ClocksControllerFaceAlphaKeyPath toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[@"values." stringByAppendingString:FaceAlphaKey] options:nil];
    [self.clocksController bind:ClocksControllerHandsAlphaKeyPath toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[@"values." stringByAppendingString:HandsAlphaKey] options:nil];
    
    
    
    // debug
//    [self.window orderFront:self];
}


#pragma mark Delegate Methods


- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    [self.window makeKeyAndOrderFront:self];
    return NO;
}

- (void)applicationDidChangeScreenParameters:(NSNotification *)notification
{
    [self.clocksController setScreens:[self secondaryScreens]];
}


#pragma mark IBActions


- (IBAction)toggle_clocks:(id)sender
{
    if ([self.clocksController isVisible]) {
        [self.clocksController hide];
    } else {
        [self.clocksController show];
    }
}

- (IBAction)restoreDefaults:(id)sender
{
    NSDictionary *values = [self defaultValues];
    [self.defaults setObject:[values objectForKey:BackgroundAlphaKey] forKey:BackgroundAlphaKey];
    [self.defaults setObject:[values objectForKey:FaceAlphaKey] forKey:FaceAlphaKey];
    [self.defaults setObject:[values objectForKey:HandsAlphaKey] forKey:HandsAlphaKey];
}

- (IBAction)showAboutPanel:(id)sender;
{
    [NSApp orderFrontStandardAboutPanel:self];
    [NSApp activateIgnoringOtherApps:YES]; // or won't show if called via status bar menu
}

- (IBAction)showPreferencesWindow:(id)sender
{
    [self.window makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)changeMenuBarIconVisibility:(id)sender
{
    if ([sender state] == 0) {
        [self hideMenuBarIcon];
    } else {
        [self showMenuBarIcon];
    }
}


#pragma mark Miscellaneous

- (NSArray *)secondaryScreens
{
    NSMutableArray *secondaryScreens = [NSMutableArray arrayWithArray:[NSScreen screens]];
    [secondaryScreens removeObjectAtIndex:0];
    return secondaryScreens;
}



- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.clocksController && [keyPath isEqualToString:ClocksControllerVisibleKeyPath]) {
        BOOL isVisible = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        NSString *title = isVisible ? NSLocalizedString(HideClocksUIString, nil) : NSLocalizedString(ShowClocksUIString, nil);
        
        [self.toggleClocksButton setTitle:title];
        [self.toggleClocksMenuItem setTitle:title];
        
        // float command window above the clock windows
        if ([self.window isKeyWindow]) {
            [self.window orderFront:self];
        }
    }
}


#pragma mark Menu Bar Icon


- (void)showMenuBarIcon
{
    self.statusItem = nil;
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    [self.statusItem setMenu:self.statusItemMenu];
    [self.statusItem setHighlightMode:YES];
    [self.statusItem setToolTip:[[NSRunningApplication currentApplication] localizedName]];
    [self.statusItem setImage:[[[ClockView alloc] initWithFrame:NSMakeRect(0, 0, 16, 16) time:[NSDate dateWithNaturalLanguageString:@"06:50"]] toImage]];
}

- (void)hideMenuBarIcon
{
    [[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
}


#pragma mark Defaults


- (NSDictionary *)defaultValues
{
    NSString *path = [[NSBundle mainBundle] pathForResource:UserDefaultsResourceName ofType:UserDefaultsResourceType];
    return [NSDictionary dictionaryWithContentsOfFile:path];
}

- (void)initDefaults
{
    self.defaults = [NSUserDefaults standardUserDefaults];
    [self.defaults registerDefaults:[self defaultValues]];
}

@end

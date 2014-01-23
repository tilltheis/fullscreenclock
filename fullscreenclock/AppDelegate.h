//
//  AppDelegate.h
//  fullscreenclock
//
//  Created by Till Theis on 23.12.13.
//  Copyright (c) 2013 Till Theis. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ClocksController.h"


@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSWindow *window;

@property (weak) IBOutlet NSSlider *backgroundAlphaSlider;
@property (weak) IBOutlet NSSlider *faceAlphaSlider;
@property (weak) IBOutlet NSSlider *handsAlphaSlider;

@property (weak) IBOutlet id defaults;


@property (strong) IBOutlet NSStatusItem *statusItem;
@property (weak) IBOutlet NSMenu *statusItemMenu;
@property (weak) IBOutlet NSMenuItem *toggleClocksMenuItem;
@property (weak) IBOutlet NSButton *toggleClocksButton;

@property (strong) IBOutlet ClocksController *clocksController;


-(IBAction)toggle_clocks:(id)sender;
-(IBAction)restoreDefaults:(id)sender;
-(IBAction)showAboutPanel:(id)sender;
-(IBAction)showPreferencesWindow:(id)sender;
-(IBAction)changeMenuBarIconVisibility:(id)sender;

@end

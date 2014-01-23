//
//  ClockView.h
//  fullscreenclock
//
//  Created by Till Theis on 06.01.14.
//  Copyright (c) 2014 Till Theis. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ClockView : NSView

// who should call setNeedsDisplay:?
@property (nonatomic, assign) CGFloat faceAlpha;
@property (nonatomic, assign) CGFloat handsAlpha;
@property (nonatomic, strong) NSDate *time;

- (id)initWithFrame:(NSRect)frame faceAlpha:(CGFloat)faceAlpha handsAlpha:(CGFloat)handsAlpha time:(NSDate *)time;

- (id)initWithFrame:(NSRect)frame time:(NSDate *)time;

- (NSImage *)toImage;

@end

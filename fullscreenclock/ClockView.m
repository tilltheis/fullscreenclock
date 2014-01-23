//
//  ClockView.m
//  fullscreenclock
//
//  Created by Till Theis on 06.01.14.
//  Copyright (c) 2014 Till Theis. All rights reserved.
//

#import "ClockView.h"

const NSPoint MaxPointSize = (NSPoint) { 200, 200 };

NSString *const TimeKeyPath = @"time";
NSString *const FaceAlphaKeyPath = @"faceAlpha";
NSString *const HandsAlphaKeyPath = @"handsAlpha";

CGFloat defaultFaceAlpha = 0.4;
CGFloat defaultHandsAlpha = 0.4;

@implementation ClockView


- (id)initWithFrame:(NSRect)frame faceAlpha:(CGFloat)faceAlpha handsAlpha:(CGFloat)handsAlpha time:(NSDate *)time
{
    self = [super initWithFrame:frame];
    if (self) {
        self.faceAlpha = faceAlpha;
        self.handsAlpha = handsAlpha;
        self.time = time;
    }
    return self;
}

- (id)initWithFrame:(NSRect)frame time:(NSDate *)time
{
    return [self initWithFrame:frame faceAlpha:defaultFaceAlpha handsAlpha:defaultHandsAlpha time:time];
}

- (id)initWithFrame:(NSRect)frame
{
    return [self initWithFrame:frame time:[NSDate date]];
}

- (void)setTime:(NSDate *)time
{
    [self willChangeValueForKey:TimeKeyPath];
    _time = time;
    [self setNeedsDisplay:YES];
    [self didChangeValueForKey:TimeKeyPath];
}

- (void)setFaceAlpha:(CGFloat)faceAlpha
{
    [self willChangeValueForKey:TimeKeyPath];
    _faceAlpha = faceAlpha;
    [self setNeedsDisplay:YES];
    [self didChangeValueForKey:TimeKeyPath];
}


- (void)setHandsAlpha:(CGFloat)handsAlpha
{
    [self willChangeValueForKey:TimeKeyPath];
    _handsAlpha = handsAlpha;
    [self setNeedsDisplay:YES];
    [self didChangeValueForKey:TimeKeyPath];
}

- (NSImage *)toImage
{
    NSBitmapImageRep *representation = [self bitmapImageRepForCachingDisplayInRect:[self bounds]];
    [self cacheDisplayInRect:[self bounds] toBitmapImageRep:representation];
    
    NSImage *image = [[NSImage alloc] initWithSize:[self bounds].size];
    [image addRepresentation:representation];
    
    return image;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
    
    [self drawFace];
    [self drawHourHand];
    [self drawMinuteHand];
}

- (void)drawFace
{
    NSRect rect = [self bounds];
    
    if (rect.size.width > rect.size.height) {
        rect.origin.x += (rect.size.width - rect.size.height) / 2;
        rect.size.width = rect.size.height;
    } else {
        rect.origin.y += (rect.size.height - rect.size.width) / 2;
        rect.size.height = rect.size.width;
    }
    
    NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:rect];
    [[NSColor colorWithCalibratedWhite:0.0 alpha:self.faceAlpha] set];
    [path fill];
}

- (void)drawHourHand
{
    // polygon points on 200x200 grid
    NSPoint points[] = { NSMakePoint(100, 158), NSMakePoint(107, 101), NSMakePoint(100, 86), NSMakePoint(93, 101) };
    NSUInteger pointsCount = sizeof(points) / sizeof(NSPoint);
    [self scalePoints:points count:pointsCount];
    
    NSInteger hours = [[NSCalendar currentCalendar] component:NSHourCalendarUnit fromDate:self.time];
    NSInteger minutes = [[NSCalendar currentCalendar] component:NSMinuteCalendarUnit fromDate:self.time];
    CGFloat units = 5.0 * hours + 5.0 / 60 * minutes;
    CGFloat degrees = (-360 / 60) * units;
    [self drawHandWithScaledPoints:points count:pointsCount rotatedByDegrees:degrees];
}

- (void)drawMinuteHand
{
    // polygon points on 200x200 grid
    NSPoint points[] = { NSMakePoint(100, 190), NSMakePoint(105, 101), NSMakePoint(100, 86), NSMakePoint(95, 101) };
    NSUInteger pointsCount = sizeof(points) / sizeof(NSPoint);
    [self scalePoints:points count:pointsCount];
    
    NSInteger minutes = [[NSCalendar currentCalendar] component:NSMinuteCalendarUnit fromDate:self.time];
    CGFloat degrees = (-360 / 60) * minutes; // rotation on face
    [self drawHandWithScaledPoints:points count:pointsCount rotatedByDegrees:degrees];
}

- (void)drawHandWithScaledPoints:(NSPointArray)points count:(NSUInteger)count rotatedByDegrees:(CGFloat)degrees
{
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path appendBezierPathWithPoints:points count:count];
    
    NSPoint center = NSMakePoint(NSMidX([self bounds]), NSMidY([self bounds]));
    NSAffineTransform *transform = [self transformRotatingAroundPoint:center byDegrees:degrees];
    [path transformUsingAffineTransform:transform];
    
    [[NSColor colorWithCalibratedWhite:1.0 alpha:self.handsAlpha] set];
    [path fill];
}

- (void)scalePoints:(NSPointArray)points count:(NSUInteger)count
{
    CGFloat xMulitiplier = [self bounds].size.width / MaxPointSize.x;
    CGFloat yMultiplier = [self bounds].size.height / MaxPointSize.y;

    for (int i = 0; i < count; i++) {
        points[i].x *= xMulitiplier;
        points[i].y *= yMultiplier;
    }
}

- (NSAffineTransform *)transformRotatingAroundPoint:(NSPoint)point byDegrees:(CGFloat)degrees
{
    NSAffineTransform * transform = [NSAffineTransform transform];
    [transform translateXBy: point.x yBy: point.y];
    [transform rotateByDegrees:degrees];
    [transform translateXBy: -point.x yBy: -point.y];
    return transform;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    // this may not belong in the view but it's the easiest way
    // it's ok to do it here since its the only exception from 'clean' design
    [[self window] close];
}

@end

//
//  ClocksController.h
//  fullscreenclock
//
//  Created by Till Theis on 23.12.13.
//  Copyright (c) 2013 Till Theis. All rights reserved.
//

#import <Foundation/Foundation.h>


FOUNDATION_EXPORT NSString *const ClocksControllerVisibleKeyPath;
FOUNDATION_EXPORT NSString *const ClocksControllerBackgroundAlphaKeyPath;
FOUNDATION_EXPORT NSString *const ClocksControllerFaceAlphaKeyPath;
FOUNDATION_EXPORT NSString *const ClocksControllerHandsAlphaKeyPath;

@interface ClocksController : NSObject <NSWindowDelegate>

@property (assign, readonly, getter = isVisible) BOOL visible;

@property (strong, nonatomic) NSArray *screens;

@property (nonatomic, assign) float backgroundAlpha;
@property (nonatomic, assign) float handsAlpha;
@property (nonatomic, assign) float faceAlpha;


- (id)initWithScreens:(NSArray *)screens backgroundAlpha:(CGFloat)backgroundAlpha handsAlpha:(CGFloat)handsAlpha faceAlpha:(CGFloat)faceAlpha;

- (void)show;
- (void)hide;

@end

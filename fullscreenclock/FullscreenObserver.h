//
//  MyClass.h
//  fullscreenclock
//
//  Created by Till Theis on 11.06.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FullscreenObserver : NSObject {
@private
    
}

@property (readonly,getter=isFullscreenMode) BOOL fullscreenMode;

+ (FullscreenObserver *)sharedFullscreenObserver;

@end

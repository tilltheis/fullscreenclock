//
//  MyClass.h
//  fullscreenclock
//
//  Created by Till Theis on 11.06.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FullscreenNotifier : NSObject {
@private
    
}

- (void)setFullscreenCallbackTarget:(id)target enterSelector:(SEL)enterSel exitSelector:(SEL)exitSel;

@end

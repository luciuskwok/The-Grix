//
//  UIView+Setup.h
//  eboy
//
//  Created by Lucius Kwok on 2/2/12.
//  Copyright (c) 2012 Felt Tip Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Setup)

- (void)setupSubviewsToBePixelatedAndExclusiveTouch;
- (void)setSubviewsEnabled:(BOOL)enabled;

@end

//
//  UIView+Setup.m
//  eboy
//
//  Created by Lucius Kwok on 2/2/12.
//  Copyright (c) 2012 Felt Tip Inc. All rights reserved.
//

#import "UIView+Setup.h"
#import <QuartzCore/QuartzCore.h>

@implementation UIView (Setup)

- (void)setupSubviewsToBePixelatedAndExclusiveTouch {
	// Set the layer's magnification filter to nearest so that it scales properly on the iPad at 2x, and set exclusiveTouch to YES on buttons so that multiple touches are not allowed.
	for (UIView *view in self.subviews) {
		if ([view isKindOfClass:[UIButton class]]) {
			UIButton *buttonView = (UIButton *)view;
			buttonView.exclusiveTouch = YES;
			buttonView.imageView.layer.magnificationFilter = kCAFilterNearest;
		} else if ([view isKindOfClass:[UIImageView class]]) {
			view.layer.magnificationFilter = kCAFilterNearest;
		}
	}
}

- (void)setSubviewsEnabled:(BOOL)enabled {
	for (UIButton *button in self.subviews) {
		if ([button isKindOfClass:[UIButton class]]) {
			button.enabled = enabled;
		}
	}
}

@end

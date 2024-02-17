//
//  DragGestureRecognizer.m
//  GRIX
//
//  Created by Lucius Kwok on 11/5/16.
//  Copyright © 2016 Felt Tip Inc. All rights reserved.
//

#import "DragGestureRecognizer.h"

@implementation DragGestureRecognizer

- (void)touchesBegan:(NSSet <UITouch *>*)touches withEvent:(UIEvent *)event {
	[super touchesBegan:touches withEvent:event];

	if (self.minimumNumberOfTouches <= event.allTouches.count && event.allTouches.count <= self.maximumNumberOfTouches) {
		self.state = UIGestureRecognizerStateBegan;
	} else {
		self.state = UIGestureRecognizerStateFailed;
	}
}

@end

//
//  GalleryArtboardFrame.m
//  eboy
//
//  Created by Lucius Kwok on 11/23/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import "GalleryArtboardFrame.h"

const CGFloat GalleryArtboardFrameBoxWidthFactor = 32.0;

@implementation GalleryArtboardFrame

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();

	// Draw the outer shadow.
	CGRect box = CGRectInset(self.bounds, 2.0, 2.0);
	[[UIColor colorWithRed:1.0 / 255.0 green:1.0 / 255.0 blue:4.0 / 255.0 alpha:1.0] set];
	UIBezierPath *path = [UIBezierPath bezierPath];
	CGFloat right = box.origin.x + box.size.width;
	CGFloat bottom = box.origin.y + box.size.height;
	[path moveToPoint:CGPointMake(box.origin.x, bottom)];
	[path addLineToPoint:CGPointMake(right + 1.0, bottom + 1.0)];
	[path addLineToPoint:CGPointMake(right + 2.0, box.origin.y + 2.0)];
	[path addLineToPoint:CGPointMake(right - 1.0, box.origin.y + 2.0)];
	[path addLineToPoint:CGPointMake(right - 1.0, bottom - 1.0)];
	[path addLineToPoint:CGPointMake(box.origin.x + 1.0, bottom - 1.0)];
	[path fill];
	
	// Draw the box and outer shadow.
    CGFloat boxWidth = self.bounds.size.width / GalleryArtboardFrameBoxWidthFactor;
	UIColor *boxColor = [UIColor colorWithRed:213.0/255.0 green:213.0/255.0 blue:206.0/255.0 alpha:1.0];
	CGContextSetStrokeColorWithColor(context, [boxColor CGColor]);
	box = CGRectInset(self.bounds, 3.0, 3.0);
	CGContextStrokeRectWithWidth(context, box, boxWidth);
}

@end

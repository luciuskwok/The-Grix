//
//  SelectedColorView.m
//  eboy
//
//  Created by Brian Papa on 8/12/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import "SelectedColorView.h"
#import <QuartzCore/QuartzCore.h>

const CGFloat SelectedColorViewIsRightOrigin = 280.0;
const CGFloat SelectedColorViewTopHeight = 60.0;
const CGFloat SelectedColorViewStemWidth = 40.0;
const CGFloat SelectedColorVerticalShadowOffset = 10.0;
const CGFloat SelectedColorHorizontalShadowOffset = 10.0;
const CGFloat SelectedColorShadowFactor = 0.798;
const CGFloat SelectedColorShadowLimit = 0.16;

@implementation SelectedColorView

- (id)initWithFrame:(CGRect)frame color:(UIColor*)aColor style:(SelectedColorViewStyle)aStyle {
    self = [super initWithFrame:frame];
    if (self) {
        self.color = aColor;
        self.backgroundColor = [UIColor clearColor];
        self.style = aStyle;
    }
    return self;
}

- (UIColor *)bottomSideColor {
	CGFloat red, green, blue, alpha;
    [self.color getRed:&red green:&green blue:&blue alpha:&alpha];
	red = red * SelectedColorShadowFactor;
	green = green * SelectedColorShadowFactor;
	blue = blue * SelectedColorShadowFactor;
	if (red + green + blue < 0.05) {
		red += SelectedColorShadowLimit;
		green += SelectedColorShadowLimit;
		blue += SelectedColorShadowLimit;
	}
	return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

- (void)drawRect:(CGRect)rect {
	const CGFloat kShadowOffset = 10.0;
	const CGFloat kOutlineWidth = 1.0;
	const CGFloat kBackInset = 10.0;
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// Front side of cube metrics.
	CGRect frontBox = CGRectInset(self.bounds, kShadowOffset, kShadowOffset);
	frontBox.size.height -= 10.0;
	CGFloat left = frontBox.origin.x;
	CGFloat right = frontBox.origin.x + frontBox.size.width;
	CGFloat top = frontBox.origin.y;
	CGFloat bottom = frontBox.origin.y + frontBox.size.height;
	
	// Back side of cube metrics.
	CGFloat backBottom = self.bounds.origin.y + self.bounds.size.height;
	CGFloat backLeft, backRight;
    switch (self.style) {
        case SelectedColorViewStyleLeftEdge:
            backLeft = left;
            backRight = right - 2.0 * kBackInset;
            break;
        case SelectedColorViewStyleRightEdge:
			backLeft = left + 2.0 * kBackInset;
            backRight = right;
            break;
		case SelectedColorViewStyleCentered:
        default:
 			backLeft = left + kBackInset;
            backRight = right - kBackInset;
            break;
	}
	
	// Shadow.
	CGContextSetFillColorWithColor(context, [[UIColor blackColor] CGColor]);
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, left - kOutlineWidth, top - kOutlineWidth);
	CGContextAddLineToPoint(context, right + kOutlineWidth, top - kOutlineWidth);
	CGContextAddLineToPoint(context, right + kOutlineWidth, top + kShadowOffset);
	CGContextAddLineToPoint(context, right + kShadowOffset, top + kShadowOffset);
	CGContextAddLineToPoint(context, right + kShadowOffset, bottom);
	CGContextAddLineToPoint(context, backRight, backBottom);
	CGContextAddLineToPoint(context, backLeft, backBottom);
	CGContextAddLineToPoint(context, left - kOutlineWidth, bottom);
	CGContextClosePath(context);
	CGContextFillPath(context);
	
	// Front side of cube.
	CGContextSetFillColorWithColor(context, [self.color CGColor]);
	CGContextFillRect(context, frontBox);
	UIImage *overlay = [UIImage imageNamed:@"color-selector-overlay"];
	[overlay drawInRect:frontBox];
	
	// Bottom side of cube, in perspective.
	CGContextSetFillColorWithColor(context, [[self bottomSideColor] CGColor]);
 	CGContextBeginPath(context);
	CGContextMoveToPoint(context, left, bottom);
	CGContextAddLineToPoint(context, right, bottom);
	CGContextAddLineToPoint(context, backRight, backBottom);
	CGContextAddLineToPoint(context, backLeft, backBottom);
	CGContextClosePath(context);
	CGContextFillPath(context);
	
	// Bottom lip.
	CGContextSetFillColorWithColor(context, [self.color CGColor]);
	CGFloat lipInflectionLeft = backLeft + (backRight - backLeft) * 0.4375;
	CGFloat lipInflectionRight = backLeft + (backRight - backLeft) * 0.5625;
 	CGContextBeginPath(context);
	CGContextMoveToPoint(context, backLeft, backBottom); 
	CGContextAddLineToPoint(context, lipInflectionLeft, backBottom - 1.0);
	CGContextAddLineToPoint(context, lipInflectionRight, backBottom - 1.0);
	CGContextAddLineToPoint(context, backRight, backBottom);
	CGContextAddLineToPoint(context, backRight, backBottom - 1.0);
	CGContextAddLineToPoint(context, lipInflectionRight, backBottom - 2.0);
	CGContextAddLineToPoint(context, lipInflectionLeft, backBottom - 2.0);
	CGContextAddLineToPoint(context, backLeft, backBottom - 1.0);
	CGContextClosePath(context);
	CGContextFillPath(context);

}


@end

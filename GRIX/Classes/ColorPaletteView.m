//
//  ColorPaletteColorView.m
//  eboy
//
//  Created by Brian Papa on 8/24/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import "ColorPaletteView.h"
#import "ColorPalette.h"
#import <QuartzCore/QuartzCore.h>

@implementation ColorPaletteView

- (id)initWithFrame:(CGRect)frame colorPalette:(ColorPalette*)aPalette {
    self = [super initWithFrame:frame];
    if (self) {
        self.colorPalette = aPalette;
		self.opaque = NO;
     }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    NSArray *palette = self.colorPalette.colorIndex;
    NSInteger colorsCount = palette.count;

	// Metrics
	const CGFloat oddOffset = 5.0;
    CGFloat boxWidth = floor((self.bounds.size.width - 2.0) / 4.0);
	CGFloat boxHeight = floor((self.bounds.size.height - 1.0) / 5.2);
	CGSize mainSize = CGSizeMake(boxWidth * 4.0, self.bounds.size.height - 1.0);
    CGRect box;
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// Shadow
	UIColor *shadowColor = [UIColor colorWithRed:1.0 / 255.0 green:1.0 / 255.0 blue:4.0 / 255.0 alpha:1.0];
	[shadowColor set];
	UIBezierPath *path = [UIBezierPath bezierPath];
	[path moveToPoint:CGPointMake(0.0, mainSize.height)];
	[path addLineToPoint:CGPointMake(mainSize.width + 1.0, mainSize.height + 1.0)];
	[path addLineToPoint:CGPointMake(mainSize.width + 2.0, oddOffset)];
	[path addLineToPoint:CGPointMake(mainSize.width - 1.0, oddOffset)];
	[path addLineToPoint:CGPointMake(mainSize.width - 1.0, mainSize.height - 1.0)];
	[path addLineToPoint:CGPointMake(1.0, mainSize.height - 1.0)];
	[path fill];
	
	// Turn off antialiasing
	CGContextSetAllowsAntialiasing(context, NO);
	CGContextSetShouldAntialias(context, NO);
	
	// Text background
	UIColor *color;
	if (_selected) {
		color = [UIColor colorWithRed:39.0/255.0 green:42.0/255.0 blue:43.0/255.0 alpha:1.0];
	} else {
		color = [UIColor colorWithRed:93.0/255.0 green:104.0/255.0 blue:107.0/255.0 alpha:1.0];
	}
	CGContextSetFillColorWithColor (context, [color CGColor]);
	box = CGRectMake(0.0, 4.0 * boxHeight, mainSize.width, mainSize.height - 4.0 * boxHeight);
	CGContextFillRect(context, box);
	
	// Text as image
	UIImage *labelImage = [UIImage imageNamed:[NSString stringWithFormat:@"palette-label-%@", self.colorPalette.eBoyName]];
	if (labelImage != nil) {
		CGRect labelBox = CGRectMake(0.0, mainSize.height - 12.0, mainSize.width, 12.0);
		
		[labelImage drawInRect:labelBox];
	}
	
	// Colors
	box = CGRectMake(0.0, 0.0, boxWidth, boxHeight);
	for (NSInteger i = 0; i < colorsCount; i++) {
		color = [palette objectAtIndex:i];
		CGContextSetFillColorWithColor (context, [color CGColor]);

		box.origin.x = (i % 4) * boxWidth;
		box.origin.y = (i / 4) * boxHeight + ((i + 1) % 2) * oddOffset;
		CGContextFillRect(context, box);
	}
}

- (void)setSelected:(BOOL)s {
	if (s != _selected) {
		_selected = s;
		[self setNeedsDisplay];
	}
}

@end

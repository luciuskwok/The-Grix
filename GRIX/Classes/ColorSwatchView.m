//
//  ColorSwatch.m
//  eboy
//
//  Created by Lucius Kwok on 12/3/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import "ColorSwatchView.h"

@implementation ColorSwatchView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGRect box = self.bounds;

	// Use the background color as the color swatch
	CGContextSetFillColorWithColor(context, [self.backgroundColor CGColor]);
	CGContextFillRect(context, box);
		
	// Draw the left and right gradient effects as an image overlay
	UIImage *overlay = [UIImage imageNamed:@"color-swatch-overlay"];
	[overlay drawInRect:box blendMode:kCGBlendModeNormal alpha:1.0];
}

@end

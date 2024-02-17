//
//  ColorPaletteColorView.h
//  eboy
//
//  Created by Brian Papa on 8/24/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ColorPalette;


@interface ColorPaletteView : UIView
{
	BOOL _selected;
}

@property (strong, nonatomic) ColorPalette *colorPalette;

- (id)initWithFrame:(CGRect)frame colorPalette:(ColorPalette*)aPalette;
- (void)setSelected:(BOOL)s;

@end

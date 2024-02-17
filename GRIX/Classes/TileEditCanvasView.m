//
//  TileEditCanvasView.m
//  eboy
//
//  Created by Brian Papa on 8/27/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import "TileEditCanvasView.h"
#import "ArtboardTile.h"
#import "ColorPalette.h"
#import "ArtboardTilePalette.h"
#import "Artboard.h"
#import "eboyAppDelegate.h"

@implementation TileEditCanvasView

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
    NSArray *paletteColorIndex = self.artboardTile.tilePalette.artboard.unsavedColorPalette.colorIndex;    
    
    for (int i = 0; i < self.artboardTile.colorsIndex.count; i++) {
        int colorIndex = [[self.artboardTile.colorsIndex objectAtIndex:i] intValue];
        UIColor *color = [paletteColorIndex objectAtIndex:colorIndex];
        [color setStroke];
        [color setFill];
        
        CGFloat originX = (i % TileUnitGridSize) * EditTileUnitSize;
        CGFloat originY = (i / TileUnitGridSize) * EditTileUnitSize;
        
        UIBezierPath *aPath = [UIBezierPath bezierPathWithRect:CGRectMake(originX,originY, EditTileUnitSize, EditTileUnitSize)];
        
        [aPath fill];
    }
}


@end

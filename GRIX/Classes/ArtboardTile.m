//
//  ArtboardTile.m
//  eboy
//
//  Created by Brian Papa on 8/30/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import "ArtboardTile.h"
#import "Artboard.h"
#import "eboyAppDelegate.h"

@implementation ArtboardTile

@dynamic tilePalette, colorsIndex, placedTiles;

- (void) setPixelValue:(int)value atRow:(int)unitRow col:(int)unitCol {
    int colorIndex = unitRow * TileUnitGridSize + unitCol;
    if ([[self.colorsIndex objectAtIndex:colorIndex] intValue] != value) {
        NSMutableArray *mutableColorsIndex = [NSMutableArray arrayWithArray:self.colorsIndex];
        [mutableColorsIndex replaceObjectAtIndex:colorIndex withObject:@(value)];
        self.colorsIndex = mutableColorsIndex;
    }
}

- (int)pixelValueAtRow:(int)unitRow col:(int)unitCol {
	return [[self.colorsIndex objectAtIndex:unitRow * TileUnitGridSize + unitCol] intValue];
}

- (NSData *)pixelData {
	// Convert NSArray of NSNumbers to a C array.
	NSArray *pixelArray = self.colorsIndex;
	NSMutableData *pixelData = [NSMutableData dataWithLength:pixelArray.count];
	UInt8 *pixelPtr = [pixelData mutableBytes];
	int i;
	for (i = 0; i < pixelArray.count; i++) {
		pixelPtr[i] = [[pixelArray objectAtIndex:i] intValue];
	}
	return pixelData;
}

@end

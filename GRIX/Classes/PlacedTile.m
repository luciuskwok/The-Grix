//
//  PlacedTile.m
//  eboy
//
//  Created by Brian Papa on 9/8/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import "PlacedTile.h"
#import "ArtboardTile.h"
#import "eboyAppDelegate.h"

@implementation PlacedTile

@dynamic gridX;
@dynamic gridY;
@dynamic orientationPersistentShadow;
@dynamic tile;
@dynamic artboard;

- (void)awakeFromInsert {
    self.orientation = PlacedTileRightSideUp;
}

- (void)setOrientation:(PlacedTileOrientation)orientation {
    self.orientationPersistentShadow = orientation;
}

- (PlacedTileOrientation)orientation {
    return self.orientationPersistentShadow;
}

- (BOOL)appearsBeforePlacedTile:(PlacedTile*)aTile {
    int index1 = (self.gridY * ArtboardTileGridSize) + self.gridX;
    int index2 = (aTile.gridY * ArtboardTileGridSize) + aTile.gridX;
    
    return index1 < index2;
}

- (void)rotate:(int)rotations {    
    self.orientation = [PlacedTile orientation:self.orientation withRotations:rotations];
}

- (double)rotationAngle {
    double angle;
    
    switch (self.orientation) {
        case PlacedTileRightSideUp:
            angle = 0;
            break;
        case PlacedTileOnRightSide:
            angle = -M_PI_2;
            break;
        case PlacedTileUpsideDown:
            angle = -M_PI;
            break;
        case PlacedTileOnLeftSide:
            angle = -3 * M_PI_2;
            break;
        default:
            break;
    }
    
    return angle;
}

- (NSData *)rotatedPixelData {
	NSData *pixelData = [self.tile pixelData];
	if (pixelData.length != 64) {
		NSLog (@"PlacedTile: tiles must have 64 pixels.");
		return nil; // Integrity check.
	}
	
	if (self.orientation == PlacedTileRightSideUp)
		return pixelData;
	
	// Rotate pixel data according to orientation.
	NSMutableData *rotatedPixelData = [NSMutableData dataWithLength:64];
	const UInt8 *pixelPtr = [pixelData bytes];
	UInt8 *rotatedPtr = [rotatedPixelData mutableBytes];
	int x, y, rx, ry;
	for (y = 0; y < 8; y++) {
		for (x = 0; x < 8; x++) {
			switch (self.orientation) {
				case PlacedTileOnRightSide:
					rx = 7 - y;
					ry = x;
					break;
				case PlacedTileUpsideDown:
					rx = 7 - x;
					ry = 7 - y;
					break;
				case PlacedTileOnLeftSide:
					rx = y;
					ry = 7 - x;
					break;
				default:
					rx = x;
					ry = y;
					break;
			}
			rotatedPtr[rx + ry * 8] = pixelPtr[x + y * 8];
		}
	}
	
	return rotatedPixelData;

}

+ (PlacedTileOrientation)orientation:(PlacedTileOrientation)orientation withRotations:(int)rotations {    
    switch (orientation) {
        case PlacedTileRightSideUp:
            switch (rotations) {
                case 1:
                case -3:
                    return PlacedTileOnRightSide;
                case 2:
                case -2:
                    return PlacedTileUpsideDown;
                case 3:
                case -1:
                    return PlacedTileOnLeftSide;
            }
            break;
            
        case PlacedTileOnRightSide:
            switch (rotations) {
                case 1:
                case -3:
                    return PlacedTileUpsideDown;
                case 2:
                case -2:
                    return PlacedTileOnLeftSide;
                case 3:
                case -1:
                    return PlacedTileRightSideUp;
            }
            break;
            
        case PlacedTileUpsideDown:
            switch (rotations) {
                case 1:
                case -3:
                    return PlacedTileOnLeftSide;
                case 2:
                case -2:
                    return PlacedTileRightSideUp;
                case 3:
                case -1:
                    return PlacedTileOnRightSide;
            }
            break;
            
        case PlacedTileOnLeftSide:
            switch (rotations) {
                case 1:
                case -3:
                    return PlacedTileRightSideUp;
                case 2:
                case -2:
                    return PlacedTileOnRightSide;
                case 3:
                case -1:
                    return PlacedTileUpsideDown;
            }
            break;
    }
    
    // in this case return -1 because something went wrong
    return -1;
}

@end

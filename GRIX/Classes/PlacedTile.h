//
//  PlacedTile.h
//  eboy
//
//  Created by Brian Papa on 9/8/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef enum _PlacedTileOrientation {
    PlacedTileRightSideUp = 0,
    PlacedTileOnRightSide = 1,
    PlacedTileUpsideDown = 2,
    PlacedTileOnLeftSide = 3,
} PlacedTileOrientation;

@class ArtboardTile, Artboard;

@interface PlacedTile : NSManagedObject

@property (nonatomic) int16_t gridX;
@property (nonatomic) int16_t gridY;
@property (nonatomic) PlacedTileOrientation orientation;
@property (nonatomic) int16_t orientationPersistentShadow;
@property (nonatomic, retain) ArtboardTile *tile;
@property (nonatomic, retain) Artboard *artboard;
@property (readonly) double rotationAngle;

- (BOOL)appearsBeforePlacedTile:(PlacedTile*)aTile;
- (void)rotate:(int)rotations;
- (NSData *)rotatedPixelData;
+ (PlacedTileOrientation)orientation:(PlacedTileOrientation)orientation withRotations:(int)rotations;

@end

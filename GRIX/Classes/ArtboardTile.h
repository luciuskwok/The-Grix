//
//  ArtboardTile.h
//  eboy
//
//  Created by Brian Papa on 8/30/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Artboard, ArtboardTilePalette, Tile;

@interface ArtboardTile : NSManagedObject

@property (nonatomic, retain) ArtboardTilePalette *tilePalette;
@property (nonatomic, retain) NSMutableArray *colorsIndex;
@property (nonatomic, retain) NSMutableSet *placedTiles;

- (void)setPixelValue:(int)x atRow:(int)unitRow col:(int)unitCol;
- (int)pixelValueAtRow:(int)unitRow col:(int)unitCol;
- (NSData *)pixelData;

@end

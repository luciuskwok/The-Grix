//
//  ArtboardTilePalette.h
//  eboy
//
//  Created by Brian Papa on 9/7/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Artboard, ArtboardTile;

@interface ArtboardTilePalette : NSManagedObject

@property (nonatomic, retain) Artboard *artboard;
@property (nonatomic, retain) NSMutableOrderedSet *artboardTiles;
@end

@interface ArtboardTilePalette (CoreDataGeneratedAccessors)

- (void)insertObject:(ArtboardTile *)value inArtboardTilesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromArtboardTilesAtIndex:(NSUInteger)idx;
- (void)insertArtboardTiles:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeArtboardTilesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInArtboardTilesAtIndex:(NSUInteger)idx withObject:(ArtboardTile *)value;
- (void)replaceArtboardTilesAtIndexes:(NSIndexSet *)indexes withArtboardTiles:(NSArray *)values;
- (void)addArtboardTilesObject:(ArtboardTile *)value;
- (void)removeArtboardTilesObject:(ArtboardTile *)value;
- (void)addArtboardTiles:(NSOrderedSet *)values;
- (void)removeArtboardTiles:(NSOrderedSet *)values;
@end

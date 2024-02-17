//
//  Artboard.m
//  eboy
//
//  Created by Brian Papa on 8/28/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import "Artboard.h"
#import "ColorPalette.h"
#import "ArtboardTile.h"
#import "eboyAppDelegate.h"
#import "PlacedTile.h"
#import "ArtboardTilePalette.h"
#import "ZlibCompressor.h"


// Constants
NSString *ArtboardEditedNotification = @"ArtboardEditedNotification";
NSString *ArtboardDuplicatedNotification = @"ArtboardDuplicatedNotification";
NSString *ArtboardDictionaryColorPaletteIDKey = @"colorPaletteID";
NSString *ArtboardDictionaryTilePalettesKey = @"tilePalettes";
NSString *ArtboardDictionaryArtboardTilesKey = @"artboardTiles";
NSString *ArtboardDictionaryArtboardColorsIndexKey = @"colorsIndex";
NSString *ArtboardDictionaryArtboardPlacedTilesKey = @"placedTiles";
NSString *ArtboardDictionaryPlacedTileGridXKey = @"gridX";
NSString *ArtboardDictionaryPlacedTileGridYKey = @"gridY";
NSString *ArtboardDictionaryPlacedTileOrientationKey = @"orientation";
NSString *ArtboardDictionaryArtboardTileIDKey = @"artboardTileID";
const NSInteger ArtboardBackgroundShadowThickness = 2;
const NSInteger TileShadowOffset = 2;

@implementation Artboard

@dynamic created;
@dynamic colorPalette;
@synthesize unsavedColorPalette;
@dynamic tilePalettes;
@dynamic placedTiles;

#pragma mark -
#pragma mark ManagedObject lifecycle methods
- (void) awakeFromInsert {
    [super awakeFromInsert];
    [self setCreated:[NSDate timeIntervalSinceReferenceDate]];
}

- (void) awakeFromFetch {
    [super awakeFromFetch];
    [self setUnsavedColorPalette:[self colorPalette]];
}

- (void) willSave {
    [super willSave];
    
    // first check that both color palettes are present - may not be if not yet assigned, or if deleting (then color palette will have been set to nil)
    if (self.unsavedColorPalette && self.colorPalette)
        if (self.colorPalette != self.unsavedColorPalette)
            self.colorPalette = self.unsavedColorPalette;
}

#pragma mark -
#pragma mark classh methods for fetching
+ (Artboard*)newArtboardWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext {
    Artboard *artboard = [NSEntityDescription insertNewObjectForEntityForName:@"Artboard" inManagedObjectContext:managedObjectContext];
    
    NSURL *palettePListURL = [[NSBundle mainBundle] URLForResource:@"tilePalettes" withExtension:@"plist"];
    NSArray *palettes = [[NSDictionary dictionaryWithContentsOfURL:palettePListURL] objectForKey:@"palettes"];
	
    NSMutableOrderedSet *artboardTilePalettes = [artboard mutableOrderedSetValueForKey:@"tilePalettes"];
    for (NSDictionary *palette in palettes) {
        ArtboardTilePalette *artboardTilePalette = [NSEntityDescription insertNewObjectForEntityForName:@"ArtboardTilePalette" inManagedObjectContext:managedObjectContext];
        [artboardTilePalettes addObject:artboardTilePalette];
        
        NSMutableOrderedSet *artboardTiles = [artboardTilePalette mutableOrderedSetValueForKey:@"artboardTiles"];
        for (NSDictionary *tileDictionary in [palette objectForKey:@"tiles"]) {
            ArtboardTile *tile = [NSEntityDescription insertNewObjectForEntityForName:@"ArtboardTile" inManagedObjectContext:managedObjectContext];
            [artboardTiles addObject:tile];
            
			// Use pixel data in hex if it exists
			NSString *pixelDataHex = [tileDictionary objectForKey:@"pixelDataHex"];
			if (pixelDataHex != nil && [pixelDataHex length] >= 64) {
				NSMutableArray *pixels = [NSMutableArray arrayWithCapacity:64];
				int pixelValue = 0;
				unichar c;
				for (int i = 0; i < 64; i++) {
					c = [pixelDataHex characterAtIndex:i];
					if (c >= '0' && c <= '9') {
						pixelValue = c - '0';
					} else if (c >= 'a' && c <= 'f') {
						pixelValue = 10 + c - 'a';
					}
					[pixels addObject:@(pixelValue)];
				}
				tile.colorsIndex = pixels;
			} else {
				tile.colorsIndex = [tileDictionary objectForKey:@"colorsIndex"];
			}
        }
    }

    ColorPalette *colorPalette = [ColorPalette selectedColorPalette:managedObjectContext];
    artboard.colorPalette = colorPalette;
    artboard.unsavedColorPalette = colorPalette;
    
	return artboard;
}

+ (Artboard*)tutorialArtboard:(NSManagedObjectContext*)managedObjectContext {
    return [Artboard artboardAtIndex:0 managedObjectContext:managedObjectContext];
}

+ (BOOL)artboardsOrderIsAscending {
	return NO; // Always newest on top. There is no setting for this any longer.
}

+ (NSArray*)artboardsWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext prefetch:(BOOL)prefetch {
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Artboard"];
	request.returnsObjectsAsFaults = NO;
	
	if (prefetch) {
		// prefetch the artboards relationships so that 1: drawing is faster, no need to fire faults for placedTiles, etc. and 2: it fixes buggy behaivor, it appears that EXC_BAD_ACCESS can happen when faults are fired using Nested MOCs. I haven't been able to determine if this is definitely the case but pre-fetching appears to have prevented the crash
		// Prefetching does come at a time penalty. Without it, loading 60 artboards takes 3 ms. With it, it takes around 1500 ms. 
		request.relationshipKeyPathsForPrefetching = [NSArray arrayWithObjects:@"colorPalette",@"placedTiles",@"placedTiles.tile", nil];
	}
  
    NSError *error = nil;
    NSArray *array = [managedObjectContext executeFetchRequest:request error:&error];
    if (array == nil)
        NSLog(@"managedObjectContext executeFetchRequest error: %@",error);
    
	BOOL ascending = [self artboardsOrderIsAscending];
    NSSortDescriptor *dateSortDescriptior = [[NSSortDescriptor alloc] initWithKey:@"created" ascending:ascending];
    array = [array sortedArrayUsingDescriptors:[NSArray arrayWithObject:dateSortDescriptior]];
 
	return array;
}

+ (NSArray*)artboardsInRange:(NSRange)range withManagedObjectContext:(NSManagedObjectContext*)managedObjectContext {
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"created" ascending:[self artboardsOrderIsAscending]];
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Artboard"];
	request.returnsObjectsAsFaults = NO;
	request.relationshipKeyPathsForPrefetching = [NSArray arrayWithObjects:@"colorPalette",@"placedTiles",@"placedTiles.tile", nil];
	request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
	request.fetchOffset = range.location;
	request.fetchLimit = range.length;
	
    NSError *error = nil;
    NSArray *results = [managedObjectContext executeFetchRequest:request error:&error];
    if (results == nil)
        NSLog(@"managedObjectContext executeFetchRequest error: %@",error);
	return results;
}

+ (Artboard*)artboardAtIndex:(NSInteger)index managedObjectContext:(NSManagedObjectContext*)managedObjectContext {
    // originally this code used to sort the artboards using Sort Descriptors on the fetch request, and then setting an offset equal to index as well as a limit so that only the desired object was returned. However that functionality stopped working properly after switching to Nested Managed Object Contexts. This may be an SDK bug or a sign of a larger bug within the application, but for now this works.
	
	// Anyway, use sort descriptors now that the app uses a single MOC.
	NSArray *artboards = [Artboard artboardsInRange:NSMakeRange(index, 1) withManagedObjectContext:managedObjectContext];
	Artboard *result = nil;
    if (artboards.count != 0)
		result = [artboards objectAtIndex:0];
	return result;
}

+ (void)deleteArtboard:(Artboard*)artboard {
    NSManagedObjectContext *managedObjectContext = artboard.managedObjectContext;
    [managedObjectContext deleteObject:artboard];
}

+ (NSInteger)countArtboardsWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext {
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Artboard"];
    
    NSError *error = nil;
	NSInteger count = [managedObjectContext countForFetchRequest:request error:&error];
	if (error)
		NSLog(@"%@",error);
	return count;
}

+ (Artboard*)artboardWithExportedData:(NSData*)exportedData managedObjectContext:(NSManagedObjectContext*)managedObjectContext {
	TimingLoggingStart
	
	NSData *uncompressedData = [ZlibCompressor uncompressData:exportedData];
	if (uncompressedData == nil) {
		NSLog(@"Could not uncompress data.");
		return nil;
	}

	TimingLoggingMark(Uncompression)

	// Write the uncompressed data to disk and then create a dictionary from it, since it seems there's no way to load a plist from memory into NSDictionary.
	NSString *tempFilename = [NSTemporaryDirectory() stringByAppendingPathComponent:@"temporaryArtboardImport.plist"];
	NSURL *tempURL = [NSURL fileURLWithPath:tempFilename];
	[uncompressedData writeToURL:tempURL atomically:NO];
	
	NSDictionary *fileDictionary = [NSDictionary dictionaryWithContentsOfURL:tempURL];
    NSDictionary *artboardDictionary = [fileDictionary objectForKey:@"artboard"];
    
    // uncomment this code if we need to manually fix a corrupted artboard, it will find a placed tile that has the same X/Y coords as another one. If you want to provide a test file, uncomment the first line below and put it above the line above that creates the artboard dictionary
    //  fileDictionary = [NSDictionary dictionaryWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"temporaryArtboardImport" withExtension:@"plist"]];
    /*
    NSArray *placedTiles = [artboardDictionary objectForKey:@"placedTiles"];
    NSMutableArray *existingPoints = [NSMutableArray array];
    for (int i = 0; i < placedTiles.count; i++) {
        NSDictionary *placedTileDictionary = [placedTiles objectAtIndex:i];
        int gridX = [[placedTileDictionary objectForKey:@"gridX"] intValue];
        int gridY = [[placedTileDictionary objectForKey:@"gridY"] intValue];
        CGPoint thePoint = CGPointMake(gridX, gridY);
        NSValue *thePointValue = [NSValue valueWithCGPoint:thePoint];
        if ([existingPoints containsObject:thePointValue])
            NSLog(@"point duplicated at index %d! %d %d", i, gridX, gridY);
        else
            [existingPoints addObject:[NSValue valueWithCGPoint:thePoint]];
    }*/
    
	Artboard *artboard = [Artboard artboardFromDictionary:artboardDictionary managedObjectContext:managedObjectContext];
    if (!artboard)
        return nil;
    
	// Delete temp file - comment this line out if you need to look at the plist in the temp directory
	NSError *error = nil;
	[[NSFileManager defaultManager] removeItemAtURL:tempURL error:&error];
	if (error)
		NSLog (@"Error deleting temp file: %@", error);

	TimingLoggingMark(Reading uncompressed data)
	TimingLoggingEnd
	
	return artboard;
}	

+ (BOOL)isValidArtboardDictionary:(NSDictionary*)artboardDictionary {
    NSNumber *colorPaletteID = [artboardDictionary objectForKey:ArtboardDictionaryColorPaletteIDKey];
    if (!colorPaletteID)
        return NO;
    
    NSArray *tilePalettes = [artboardDictionary objectForKey:ArtboardDictionaryTilePalettesKey];
    if (!tilePalettes)
        return NO;
    
    // every tile palette has an array of artboard tiles
    for (NSDictionary *tilePalette in tilePalettes) {
        NSArray *artboardTiles = [tilePalette objectForKey:ArtboardDictionaryArtboardTilesKey];
        if (!artboardTiles)
            return NO;
        
        for (NSDictionary *artboardTile in artboardTiles) {
            // every artboard tile has a color index and an ID
            if (![artboardTile objectForKey:ArtboardDictionaryArtboardColorsIndexKey] || ![artboardTile objectForKey:ArtboardDictionaryArtboardTileIDKey])
                return NO;
        }
    }
    
    // an artboard may or may not have placed tiles
    NSArray *placedTiles = [artboardDictionary objectForKey:ArtboardDictionaryArtboardPlacedTilesKey];
    for (NSDictionary *placedTileDictionary in placedTiles) {
        // every tile must have a grid position, orientation, and refer to an artboard tile
        if (![placedTileDictionary objectForKey:ArtboardDictionaryPlacedTileGridXKey] || ![placedTileDictionary objectForKey:ArtboardDictionaryPlacedTileGridYKey] || ![placedTileDictionary objectForKey:ArtboardDictionaryPlacedTileOrientationKey] || ![placedTileDictionary objectForKey:ArtboardDictionaryArtboardTileIDKey])
            return NO;
    }
    
    // all good!
    return YES;
}

+ (Artboard*)artboardFromDictionary:(NSDictionary*)artboardDictionary managedObjectContext:(NSManagedObjectContext*)managedObjectContext {
    if (![self isValidArtboardDictionary:artboardDictionary])
        return nil;
    
	Artboard *artboard = [NSEntityDescription insertNewObjectForEntityForName:@"Artboard" inManagedObjectContext:managedObjectContext];
    
    // assign color palette
    NSInteger colorPaletteID = [[artboardDictionary objectForKey:ArtboardDictionaryColorPaletteIDKey] integerValue];
    ColorPalette *colorPalette = [ColorPalette colorPaletteByEBoyID:colorPaletteID managedObjectContext:managedObjectContext];
    artboard.colorPalette = colorPalette;
    artboard.unsavedColorPalette = colorPalette;
    
    // a temporary dictionary of ids to artboard tiles, so that they can quickly be assigned to the placed tiles later
    NSMutableDictionary *artboardTileIDsToArtboardTiles = [NSMutableDictionary dictionary];
    
    // add artboard tiles by palette
    NSMutableOrderedSet *artboardTilePalettes = [NSMutableOrderedSet orderedSet];
    NSArray *tilePaletteArray = [artboardDictionary objectForKey:ArtboardDictionaryTilePalettesKey];
    for (NSDictionary *tilePaletteDictionary in tilePaletteArray) {
        ArtboardTilePalette *artboardTilePalette = [NSEntityDescription insertNewObjectForEntityForName:@"ArtboardTilePalette"  inManagedObjectContext:managedObjectContext];
        NSMutableOrderedSet *artboardTiles = [NSMutableOrderedSet orderedSet];
        NSArray *artboardTilesArray = [tilePaletteDictionary objectForKey:ArtboardDictionaryArtboardTilesKey];
        for (NSDictionary *artboardTileDictionary in artboardTilesArray) {
            ArtboardTile *artboardTile = [NSEntityDescription insertNewObjectForEntityForName:@"ArtboardTile" inManagedObjectContext:managedObjectContext];
            artboardTile.colorsIndex = [artboardTileDictionary objectForKey:ArtboardDictionaryArtboardColorsIndexKey];
            [artboardTiles addObject:artboardTile];
            [artboardTileIDsToArtboardTiles setObject:artboardTile forKey:[artboardTileDictionary objectForKey:ArtboardDictionaryArtboardTileIDKey]];
        }
        artboardTilePalette.artboardTiles = artboardTiles;
        [artboardTilePalettes addObject:artboardTilePalette];
    }
    artboard.tilePalettes = artboardTilePalettes;
    
    // add placed tiles
    NSMutableOrderedSet *placedTiles = [NSMutableOrderedSet orderedSet];
    NSArray *placedTilesArray = [artboardDictionary objectForKey:ArtboardDictionaryArtboardPlacedTilesKey];
    for (NSDictionary *placedTileDictionary in placedTilesArray) {
        PlacedTile *placedTile = [NSEntityDescription insertNewObjectForEntityForName:@"PlacedTile" inManagedObjectContext:managedObjectContext];
        placedTile.gridX = [[placedTileDictionary objectForKey:ArtboardDictionaryPlacedTileGridXKey] intValue];
        placedTile.gridY = [[placedTileDictionary objectForKey:ArtboardDictionaryPlacedTileGridYKey] intValue];
        placedTile.orientation = [[placedTileDictionary objectForKey:ArtboardDictionaryPlacedTileOrientationKey] intValue];
        
        NSNumber *artboardTileID = [placedTileDictionary objectForKey:ArtboardDictionaryArtboardTileIDKey];
        placedTile.tile = [artboardTileIDsToArtboardTiles objectForKey:artboardTileID];
        
        [placedTiles addObject:placedTile];
    }
    artboard.placedTiles = placedTiles;
    
    return artboard;
}

#pragma mark - Instance methods

- (Artboard*)duplicate {
    // create the artboard
    Artboard *duplicateArtboard = [NSEntityDescription insertNewObjectForEntityForName:@"Artboard" inManagedObjectContext:self.managedObjectContext];
    
    // copy artboard tiles by palette
    NSMutableOrderedSet *duplicateTilePalettes = [duplicateArtboard mutableOrderedSetValueForKey:@"tilePalettes"];
    for (ArtboardTilePalette *artboardTilePalette in self.tilePalettes) {
        ArtboardTilePalette *duplicateTilePalette = [NSEntityDescription insertNewObjectForEntityForName:@"ArtboardTilePalette" inManagedObjectContext:self.managedObjectContext];
        NSMutableOrderedSet *duplicateArtboardTiles = [duplicateTilePalette mutableOrderedSetValueForKey:@"artboardTiles"];
        for (ArtboardTile *artboardTile in artboardTilePalette.artboardTiles) {
            ArtboardTile *duplicateArtboardTile = [NSEntityDescription insertNewObjectForEntityForName:@"ArtboardTile" inManagedObjectContext:self.managedObjectContext];
            duplicateArtboardTile.colorsIndex = artboardTile.colorsIndex;
            [duplicateArtboardTiles addObject:duplicateArtboardTile];
        }
        [duplicateTilePalettes addObject:duplicateTilePalette];
    }
    
    // copy color palette
    duplicateArtboard.colorPalette = self.colorPalette;
    duplicateArtboard.unsavedColorPalette = self.colorPalette;
    
    // copy placed tiles
    NSMutableOrderedSet *duplicatedPlacedTiles = [duplicateArtboard mutableOrderedSetValueForKey:@"placedTiles"];
    for (PlacedTile *placedTile in self.placedTiles) {
        // the Artboard Tile in the existing placed tile has a corresponding Artboard Tile and Palette in the duplicate
        ArtboardTilePalette *placedTileArtboardTilePalette = placedTile.tile.tilePalette;
        NSInteger tilePaletteIndex = [self.tilePalettes indexOfObject:placedTileArtboardTilePalette];
        NSInteger artboardTileIndex = [placedTileArtboardTilePalette.artboardTiles indexOfObject:placedTile.tile];
        ArtboardTilePalette *duplicateArtboardTilePalette = [duplicateArtboard.tilePalettes objectAtIndex:tilePaletteIndex];
        ArtboardTile *duplicateArtboardTile = [duplicateArtboardTilePalette.artboardTiles objectAtIndex:artboardTileIndex];
        
        PlacedTile *duplicateTile = [NSEntityDescription insertNewObjectForEntityForName:@"PlacedTile" inManagedObjectContext:self.managedObjectContext];
        duplicateTile.tile = duplicateArtboardTile;
        duplicateTile.gridX = placedTile.gridX;
        duplicateTile.gridY = placedTile.gridY;
        duplicateTile.orientation = placedTile.orientation;
        [duplicatedPlacedTiles addObject:duplicateTile];
    }
    
	duplicateArtboard.placedTiles = duplicatedPlacedTiles;
    
    return duplicateArtboard;
}

- (PlacedTile*) tileAtX:(int)x Y:(int)y {
    PlacedTile *existingTile;
    for (PlacedTile *tile in self.placedTiles) {
        if ((tile.gridX == x) && (tile.gridY == y)) {
            existingTile = tile;
        }
    }
    
    return existingTile;
}

- (PlacedTile*) addTile:(ArtboardTile*)aTile gridX:(int)gridX gridY:(int)gridY {
    // if the tile is nil, something is wrong, so return nil
    if (aTile == nil) {
        NSLog(@"attempt to place tile at %d %d but tile was nil",gridX, gridY);
        return nil;
    }
    
    // the existing tile will be deleted
    PlacedTile *existingTile = [self tileAtX:gridX Y:gridY];
    
    PlacedTile *placedTile = [NSEntityDescription insertNewObjectForEntityForName:@"PlacedTile" inManagedObjectContext:self.managedObjectContext];
    placedTile.tile = aTile;
    placedTile.gridX = gridX;
    placedTile.gridY = gridY;
    
    NSMutableOrderedSet *mutablePlacedTiles = [self mutableOrderedSetValueForKey:@"placedTiles"];
    
    // if there was already an existing tile, replace it with the new one
    if (existingTile) {
        NSInteger index = [mutablePlacedTiles indexOfObject:existingTile];
        [mutablePlacedTiles replaceObjectAtIndex:index withObject:placedTile];
        [self.managedObjectContext deleteObject:existingTile]; 
    } else {
        // otherwise, add it and sort
        [mutablePlacedTiles addObject:placedTile];
        
        [mutablePlacedTiles sortUsingComparator:^(PlacedTile *tile1, PlacedTile *tile2) {
            if ([tile1 appearsBeforePlacedTile:tile2] ) {
                return (NSComparisonResult)NSOrderedAscending;
            } else {
                return (NSComparisonResult)NSOrderedDescending;
            }
        }];
    }
            
    return placedTile;
}

- (void)moveTileFromX:(int)fromX fromY:(int)fromY toX:(int)toX toY:(int)toY {    
    PlacedTile *existingTile = [self tileAtX:toX Y:toY];    
    PlacedTile *tileToMove = [self tileAtX:fromX Y:fromY];
    
    tileToMove.gridX = toX;
    tileToMove.gridY = toY;
    
    NSMutableOrderedSet *mutablePlacedTiles = [self mutableOrderedSetValueForKey:@"placedTiles"];
    
    // any existing tile is removed, and moved tile replaces it
    if (existingTile && (existingTile != tileToMove)) {
        NSInteger existingIndex = [mutablePlacedTiles indexOfObject:existingTile];
        [self.managedObjectContext deleteObject:existingTile];
        [mutablePlacedTiles insertObject:tileToMove atIndex:existingIndex];
    } else {
        // otherwise, just re-sort        
        [mutablePlacedTiles sortUsingComparator:^(PlacedTile *tile1, PlacedTile *tile2) {
            if ([tile1 appearsBeforePlacedTile:tile2] ) {
                return (NSComparisonResult)NSOrderedAscending;
            } else {
                return (NSComparisonResult)NSOrderedDescending;
            }
        }];
    }
}

- (void)deleteTileFromX:(int)x y:(int)y {
    PlacedTile *existingTile = [self tileAtX:x Y:y];
    [self.managedObjectContext deleteObject:existingTile];
}

- (PlacedTile*) tileAtGridX:(int)gridX gridY:(int)gridY {
    for (PlacedTile *placedTile in self.placedTiles) {
        if (placedTile.gridX == gridX && placedTile.gridY == gridY)
            return placedTile;
    }
    
    return nil;
}

- (NSData*)dataForExport {
 	TimingLoggingStart

	NSDictionary *artboardDictionary = [self exportDictionary];
	NSDictionary *exportDictionary = @{@"artboard":artboardDictionary};

	TimingLoggingMark(Create export dictionary)
	
    NSError *error = nil;
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:exportDictionary format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
    if (error)
        NSLog(@"%@",error);
	
	TimingLoggingMark(Create plist)
	
	// Compress data with bz2.
	NSData *compressedData = [ZlibCompressor compressData:plistData];

	TimingLoggingMark(Compress data)
	TimingLoggingEnd
	
    return compressedData;
}

- (NSDictionary*)exportDictionary {
    // Previously, this method would "get a fully not-faulted object to avoid firing faults through each pass of the forthcoming loops". However, testing shows that going to Core Data to prefetch the artboard and its entities ends up taking more time than allowing the faults to fire as needed.
                          
    // it's easiest to get the placed tiles per artboard tile and then sort them later
    NSMutableArray *unsortedExportPlacedTiles = [NSMutableArray array];
    
    // the id is only used to tie placed tiles to their corresponding artboard tiles
    int currentArtboardTileId = 0;
    NSMutableArray *exportArtboardTilePalettes = [NSMutableArray array];
    for (ArtboardTilePalette *artboardTilePalette in self.tilePalettes) {
        NSMutableArray *exportArtboardTiles = [NSMutableArray array];
        for (ArtboardTile *artboardTile in artboardTilePalette.artboardTiles) {
			NSDictionary *exportArtboardTile = @{
												 @"colorsIndex": artboardTile.colorsIndex,
												 ArtboardDictionaryArtboardTileIDKey: @(currentArtboardTileId) };
            for (PlacedTile *placedTile in artboardTile.placedTiles) {
				NSDictionary *exportPlacedTile = @{
												   ArtboardDictionaryPlacedTileGridXKey: @(placedTile.gridX),
												   ArtboardDictionaryPlacedTileGridYKey: @(placedTile.gridY),
												   ArtboardDictionaryPlacedTileOrientationKey: @(placedTile.orientation),
												   ArtboardDictionaryArtboardTileIDKey: @(currentArtboardTileId)
												   };
                [unsortedExportPlacedTiles addObject:exportPlacedTile];
            }
            
            [exportArtboardTiles addObject:exportArtboardTile];
            
            currentArtboardTileId++;
        }
        
		NSDictionary *exportTilePalette = @{@"artboardTiles": exportArtboardTiles};
        [exportArtboardTilePalettes addObject:exportTilePalette];
    }
    
    // sort the placed tiles
    NSArray *exportPlacedTiles = [unsortedExportPlacedTiles sortedArrayUsingComparator:^(NSDictionary *placedTile1, NSDictionary *placedTile2) {
        int gridX1 = [[placedTile1 objectForKey:ArtboardDictionaryPlacedTileGridXKey] intValue];
        int gridY1 = [[placedTile1 objectForKey:ArtboardDictionaryPlacedTileGridYKey] intValue];
        int gridX2 = [[placedTile2 objectForKey:ArtboardDictionaryPlacedTileGridXKey] intValue];
        int gridY2 = [[placedTile2 objectForKey:ArtboardDictionaryPlacedTileGridYKey] intValue];
        
        NSInteger index1 = (gridY1 * ArtboardTileGridSize) + gridX1;
        NSInteger index2 = (gridY2 * ArtboardTileGridSize) + gridX2;
        
        if (index1 < index2) {
            return (NSComparisonResult)NSOrderedAscending;
        } else {
            return (NSComparisonResult)NSOrderedDescending;
        }
    }];
	
	NSDictionary *exportArtboard = @{ArtboardDictionaryColorPaletteIDKey: @(self.colorPalette.eBoyID), @"tilePalettes":exportArtboardTilePalettes, ArtboardDictionaryArtboardPlacedTilesKey: exportPlacedTiles};
    
    return exportArtboard;
}

#pragma mark - Rendered image

- (UIImage *)renderedImage {
	// Rendered image with default settings
	UInt32 backgroundColor = [UIAppDelegate colorWithUIColor:UIAppDelegate.artboardBackgroundColor]; // Solid background color.
	UInt32 shadowColor = [UIAppDelegate colorWithUIColor:UIAppDelegate.shadowColor];
	UIImage *image = [self renderedImageWithTileToSkip:nil shadow:YES shadowColor:shadowColor backgroundColor:backgroundColor];
	return image;
}

- (UIImage *)renderedImageWithTileToSkip:(PlacedTile *)tileToSkip shadow:(BOOL)shadow shadowColor:(UInt32)shadowColor  backgroundColor:(UInt32)bkgndColor {
	// Create a UIImage of the artboard with shadow and background.
	UIImage *result = nil;
	CGImageRef cgImage = nil;
	
	const int bitmapWidth = 64;
	const int bitmapHeight = 64;
	const int tileWidth = 8;
	const int tileHeight = 8;
	int bitmapX, bitmapY, bitmapIndex;
	UInt32 pixelRGBAValue;
	
	// Color lookup table.
	NSData *clutData = [self.unsavedColorPalette colorLookupTable];
	if (clutData == nil) 
		return nil;
	const UInt32 *clut = [clutData bytes];
	const NSInteger clutCount = [clutData length] / sizeof(UInt32);
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	
	// Create bitmap context data.
	NSMutableData *bitmapContextData = [NSMutableData dataWithLength: bitmapHeight * bitmapWidth * 4];
	if (bitmapContextData != nil) {
		UInt32 *bitmapContext = [bitmapContextData mutableBytes];
		
		// Clear context to background color with shadow.
		for (bitmapY = 0; bitmapY < bitmapHeight; bitmapY++) {
			for (bitmapX = 0; bitmapX < bitmapWidth; bitmapX++) {
				bitmapIndex = bitmapX + bitmapY * bitmapWidth;
				pixelRGBAValue = bkgndColor;
				
				if (shadow) {
					if (bitmapX < ArtboardBackgroundShadowThickness || bitmapY < ArtboardBackgroundShadowThickness) {
						// Top and left side shadows.
						pixelRGBAValue = shadowColor;
					}
				}
				bitmapContext[bitmapIndex] = pixelRGBAValue;
			}
		}
		
		// Draw shadow under each tile first.
		int originX, originY;
		int tileX, tileY, tileIndex;
		if (shadow) {
			for (PlacedTile *placedTile in self.placedTiles) {
				if (tileToSkip == placedTile)
					continue; // Skip the currently moving tile.
				
				originX = placedTile.gridX * tileWidth;
				originY = placedTile.gridY * tileHeight;
				for (tileY = 0; tileY < tileHeight; tileY++) {
					for (tileX = 0; tileX < tileWidth; tileX++) {
						// Calculate the bitmap index.
						bitmapX = originX + tileX + TileShadowOffset;
						bitmapY = originY + tileY + TileShadowOffset;
						bitmapIndex = bitmapX + bitmapY * bitmapWidth;
						
						// Bounds check.
						if (bitmapX >= 0 && bitmapX < bitmapWidth && bitmapY >= 0 && bitmapY < bitmapHeight) {
							bitmapContext[bitmapIndex] = shadowColor;
						}
					}
				}
			}
		}
		
		// Draw each tile.
		for (PlacedTile *placedTile in self.placedTiles) {
			if (tileToSkip == placedTile)
				continue; // Skip the currently moving tile.
			
			originX = placedTile.gridX * tileWidth;
			originY = placedTile.gridY * tileHeight;
			NSData *tilePixelData = [placedTile rotatedPixelData];
			if (tilePixelData != nil) {
				const UInt8 *tilePixelPtr = [tilePixelData bytes];
				for (tileY = 0; tileY < tileHeight; tileY++) {
					for (tileX = 0; tileX < tileWidth; tileX++) {
						tileIndex = tileX + tileY * tileWidth;
						
						// Calculate the bitmap index.
						bitmapX = originX + tileX;
						bitmapY = originY + tileY;
						bitmapIndex = bitmapX + bitmapY * bitmapWidth;
						
						// Bounds check.
						if (bitmapX >= 0 && bitmapX < bitmapWidth && bitmapY >= 0 && bitmapY < bitmapHeight) {
							UInt8 pixelIndexValue = tilePixelPtr[tileIndex];
							pixelRGBAValue = (pixelIndexValue < clutCount) ? clut[pixelIndexValue] : 0;
							
							// Set the pixel RGBA value in the bitmap.
							bitmapContext[bitmapIndex] = pixelRGBAValue;
						}
					}
				}
			}
		}
		
		// Create a bitmap context with the image data
		CGContextRef context = CGBitmapContextCreate(bitmapContext, bitmapWidth, bitmapHeight, 8, bitmapWidth * 4, colorspace, kCGImageAlphaPremultipliedLast);
		if (context != nil) {
			cgImage = CGBitmapContextCreateImage (context);
			CGContextRelease(context);
		}
	}
	CGColorSpaceRelease(colorspace);
	result = [UIImage imageWithCGImage:cgImage];
	CGImageRelease(cgImage);
	return result;
}


@end

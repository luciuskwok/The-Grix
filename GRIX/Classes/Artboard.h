//
//  Artboard.h
//  eboy
//
//  Created by Brian Papa on 8/28/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ColorPalette, Tile, ArtboardTile, PlacedTile;

// Constants
UIKIT_EXTERN NSString *ArtboardEditedNotification;
UIKIT_EXTERN NSString *ArtboardDuplicatedNotification;

@interface Artboard : NSManagedObject

@property (nonatomic) NSTimeInterval created;
@property (nonatomic, retain) ColorPalette *colorPalette;
@property (nonatomic, retain) ColorPalette *unsavedColorPalette;
@property (nonatomic, retain) NSMutableOrderedSet *tilePalettes;
@property (nonatomic, retain) NSMutableOrderedSet *placedTiles;

+ (BOOL)artboardsOrderIsAscending;
+ (Artboard*)newArtboardWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;
+ (Artboard*)tutorialArtboard:(NSManagedObjectContext*)managedObjectContext;
+ (NSArray*)artboardsWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext prefetch:(BOOL)prefetch;
+ (NSArray*)artboardsInRange:(NSRange)range withManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;
+ (Artboard*)artboardAtIndex:(NSInteger)index managedObjectContext:(NSManagedObjectContext*)managedObjectContext;
+ (void)deleteArtboard:(Artboard*)artboard;
+ (NSInteger)countArtboardsWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;
+ (Artboard*)artboardWithExportedData:(NSData*)exportedData managedObjectContext:(NSManagedObjectContext*)managedObjectContext;
+ (Artboard*)artboardFromDictionary:(NSDictionary*)artboardDictionary managedObjectContext:(NSManagedObjectContext*)managedObjectContext;

- (Artboard*)duplicate;
- (PlacedTile*) addTile:(ArtboardTile*)aTile gridX:(int)gridX gridY:(int)gridY;
- (void)moveTileFromX:(int)fromX fromY:(int)fromY toX:(int)toX toY:(int)toY ;
- (void)deleteTileFromX:(int)x y:(int)y;
- (PlacedTile*) tileAtGridX:(int)gridX gridY:(int)gridY;
- (NSData*)dataForExport;
- (NSDictionary*)exportDictionary;

- (UIImage *)renderedImage;
- (UIImage *)renderedImageWithTileToSkip:(PlacedTile *)tileToSkip shadow:(BOOL)shadow shadowColor:(UInt32)shadowColor  backgroundColor:(UInt32)bkgndColor;

@end

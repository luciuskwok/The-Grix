//
//  ColorPalette.h
//  eboy
//
//  Created by Brian Papa on 8/23/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface ColorPalette : NSManagedObject

@property (nonatomic, assign) SInt64 eBoyID;
@property (nonatomic, retain) NSString *eBoyName;
@property (nonatomic, retain) NSArray *colorIndex;

- (NSData *)colorLookupTable;

- (void)makeSelectedPalette;
+ (ColorPalette*)selectedColorPalette:(NSManagedObjectContext*)managedObjectContext;
+ (ColorPalette*)colorPaletteByEBoyID:(SInt64)eBoyID managedObjectContext:(NSManagedObjectContext*)managedObjectContext;
+ (NSArray*)colorPalettes:(NSManagedObjectContext*)managedObjectContext;

@end

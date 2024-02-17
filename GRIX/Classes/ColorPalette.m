//
//  ColorPalette.m
//  eboy
//
//  Created by Brian Papa on 8/23/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import "ColorPalette.h"
#import "eboyAppDelegate.h"

NSString *ColorPaletteSelectedIDKey = @"selectedColorPaletteID";

@implementation ColorPalette

@dynamic eBoyID;
@dynamic colorIndex, eBoyName;

- (NSData *)colorLookupTable {
	NSMutableData *clutData = [NSMutableData dataWithLength:16 * 4];
	UInt8 *clutPtr = [clutData mutableBytes];
	
	// Convert color palette to array of UInt32s
	UIColor *colorObject;
    NSArray *colorsArray = self.colorIndex;
	if (colorsArray.count != 16) {
		NSLog (@"ArtboardView: color palettes must have 16 colors.");
		return nil; // Integrity check.
	}
	int i;
	CGFloat r, g, b, a;
	for (i=0; i<16; i++) {
		colorObject = [colorsArray objectAtIndex:i];
		[colorObject getRed:&r green:&g blue:&b alpha:&a];
		clutPtr[i * 4 + 0] = round (r * 255.0);
		clutPtr[i * 4 + 1] = round (g * 255.0);
		clutPtr[i * 4 + 2] = round (b * 255.0);
		clutPtr[i * 4 + 3] = 255;
	}
	return clutData;
}

- (void)makeSelectedPalette {
    [[NSUserDefaults standardUserDefaults] setObject:@(self.eBoyID) forKey:ColorPaletteSelectedIDKey];
}

+ (ColorPalette*)selectedColorPalette:(NSManagedObjectContext*)managedObjectContext {
    SInt64 selectedColorPaletteID = [[[NSUserDefaults standardUserDefaults] objectForKey:ColorPaletteSelectedIDKey] longLongValue];
    if (selectedColorPaletteID == 0) {
        selectedColorPaletteID = 1;
        [[NSUserDefaults standardUserDefaults] setObject:@(selectedColorPaletteID) forKey:ColorPaletteSelectedIDKey];
    }
    
    return [ColorPalette colorPaletteByEBoyID:selectedColorPaletteID managedObjectContext:managedObjectContext];
}

+ (ColorPalette*)colorPaletteByEBoyID:(SInt64)eBoyID managedObjectContext:(NSManagedObjectContext*)managedObjectContext {
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"ColorPalette" inManagedObjectContext:managedObjectContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"eBoyID == %d",eBoyID];
    [request setPredicate:predicate];

    NSError *error;
    NSArray *array = [managedObjectContext executeFetchRequest:request error:&error];
    if (array != nil)
        return [array objectAtIndex:0];
    else {
        NSLog(@"%@",error);
        return nil;
    }
}

+ (NSArray*)colorPalettes:(NSManagedObjectContext*)managedObjectContext {    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"eBoyID" ascending:YES]];
	[request setEntity:[NSEntityDescription entityForName:@"ColorPalette" inManagedObjectContext:managedObjectContext]];
    request.returnsObjectsAsFaults = NO;
	
    NSError *error;
    NSArray *array = [managedObjectContext executeFetchRequest:request error:&error];
    if (array != nil) {
		// Sort array here because setting the sortDescriptors on the request has no effect on the order of the results.
        return [array sortedArrayUsingDescriptors:sortDescriptors];
    } else {
        NSLog(@"%@",error);
        return nil;
    }
}

@end

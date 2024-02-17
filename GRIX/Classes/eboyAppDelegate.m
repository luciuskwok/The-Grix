//
//  eboyAppDelegate.m
//  eboy
//
//  Created by Brian Papa on 8/5/11.
//  Copyright 2011 Felt Tip Inc. All rights reserved.
//

#import "eboyAppDelegate.h"
#import "ColorPalette.h"
#import "Artboard.h"
#import "ArtboardTile.h"
#import "ArtboardTilePalette.h"
#import "PlacedTile.h"
#import "ViewerViewController.h"
#import "ArtboardViewController.h"
#import "GalleryViewController.h"
#import "TileEditorViewController.h"
#import "IntroViewController.h"

// Constants
int TileUnitGridSize = 8;
int ArtboardTileGridSize = 8;
CGFloat EBoyBackgroundGrayscaleColor = 0.18;
CGFloat ArtboardTileSize = 40.0;
CGFloat EditTileUnitSize = 40.0;
CGFloat ArtboardTileDragAndRotateScaleFactor = 1.5;
CGFloat GalleryThumbnailSize = 64.0;
NSString* DefaultsKeyCurrentTwitterAccountUsername = @"currentTwitterAccountUsername";
NSString* DefaultsKeyTumblrAuthToken = @"tumblrAuthToken";
NSString* DefaultsKeyTumblrAuthTokenSecret = @"tumblrAuthTokenSecret";
NSString* DefaultsKeyTumblrUsername = @"tumblrUsername";
NSString* DefaultsKeyTumblrPrimaryBlog = @"tumblrPrimaryBlog";
NSString* DefaultsKeyRestoreLocation = @"RestoreLocation";
NSString* FacebookAppID = @"186866844751818";
NSString* FacebookAccessTokenDefaultsKey = @"facebookAccessToken";
NSString* FacebookExpirationDateDefaultsKey = @"facebookExpirationDate";
NSString* FacebookUsernameDefaultsKey = @"facebookUsername";
NSString* TumblrConsumerKey = @"48JVwjsPBvNue7LIqkKFD23yUsRZdrjnTZztqTH4u6zxJA2CRw";
NSString* TumblrConsumerSecret = @"n2hDO2iIRSKTd4chvE4ramkPO70jf7rYWnpIzRNFQzHePz5IHa";
NSInteger ArtboardTilePaletteScrollViewTag = 838181;
NSInteger TileEditorSelectedColorAreaTag = 857371;
NSInteger TileEditorColorPickerTag = 456272;

CGPoint gridForTileFrame(CGRect tileFrame) {
    NSInteger gridX = tileFrame.origin.x / ArtboardTileSize;
    NSInteger gridY = tileFrame.origin.y / ArtboardTileSize;
    return CGPointMake(gridX, gridY);
}

CGPoint gridForUnitAtPoint(CGPoint point) {
    NSInteger unitRow = point.y / EditTileUnitSize;
    NSInteger unitCol = point.x / EditTileUnitSize;
    return CGPointMake(unitCol, unitRow);
}

@implementation eboyAppDelegate

@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;


#pragma mark -  Dev methods

- (UIColor*)createUIColorForHexString:(NSString*)hexString {
    NSString *cleanString = [hexString stringByReplacingOccurrencesOfString:@"#" withString:@""];
    if([cleanString length] == 3) {
        cleanString = [NSString stringWithFormat:@"%@%@%@%@%@%@", 
                       [cleanString substringWithRange:NSMakeRange(0, 1)],[cleanString substringWithRange:NSMakeRange(0, 1)],
                       [cleanString substringWithRange:NSMakeRange(1, 1)],[cleanString substringWithRange:NSMakeRange(1, 1)],
                       [cleanString substringWithRange:NSMakeRange(2, 1)],[cleanString substringWithRange:NSMakeRange(2, 1)]];
    }
    if([cleanString length] == 6) {
        cleanString = [cleanString stringByAppendingString:@"ff"];
    }
    
    unsigned int baseValue;
    [[NSScanner scannerWithString:cleanString] scanHexInt:&baseValue];
    
    float red = ((baseValue >> 24) & 0xFF)/255.0f;
    float green = ((baseValue >> 16) & 0xFF)/255.0f;
    float blue = ((baseValue >> 8) & 0xFF)/255.0f;
    float alpha = ((baseValue >> 0) & 0xFF)/255.0f;

    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

- (void)updateColorPalettes {
    // use this method to make changes to color palettes. Create a plist, put it in the project as a resource, then call this method from applicationDidFinishLaunching with an otherwise "clean" app install. Then, export the SQLite database from the Docs directory into the project as the new initial database
    NSURL *palettePListURL = [[NSBundle mainBundle] URLForResource:@"paletteUpdates" withExtension:@"plist"];
    NSArray *updatedPalettes = [[NSDictionary dictionaryWithContentsOfURL:palettePListURL] objectForKey:@"palettes"];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"ColorPalette"];
    NSError *theError;
    NSArray *persistedPalettes = [self.managedObjectContext executeFetchRequest:request error:&theError];
    if (theError)
        NSLog(@"%@",theError);
    
    for (NSDictionary *updatedPaletteDictionary in updatedPalettes) {
        NSString *eboyName = [updatedPaletteDictionary objectForKey:@"eBoyName"];
        
        ColorPalette *persistedPalette;
        for (ColorPalette *aPalette in persistedPalettes) {
            if ([aPalette.eBoyName isEqualToString:eboyName])
                persistedPalette = aPalette;
        }
        
        NSMutableArray *persistedColorIndex = [NSMutableArray arrayWithArray:persistedPalette.colorIndex];
        NSArray *updatedColorIndex = [updatedPaletteDictionary objectForKey:@"colorIndex"];
        for (NSInteger i = 0; i < updatedColorIndex.count; i++) {
            NSString *hexColor = [updatedColorIndex objectAtIndex:i];
            [persistedColorIndex replaceObjectAtIndex:i withObject:[self createUIColorForHexString:hexColor]];
        }
             
        persistedPalette.colorIndex = persistedColorIndex;
    }
    
    if (![self.managedObjectContext save:&theError])
        NSLog(@"%@",theError);
}

#pragma mark - Private Methods

- (ViewerViewController*)instantiateAndPushViewerViewControllerWithIndex:(NSInteger)index {
    UINavigationController *navController = (UINavigationController*)self.window.rootViewController;
    UIStoryboard *storyboard = navController.storyboard;
    ViewerViewController *viewer = [storyboard instantiateViewControllerWithIdentifier:@"Viewer"];
    viewer.visibleArtboardIndex = index;

    // pass along the current MOC
    viewer.managedObjectContext = self.managedObjectContext;
    
    // pop any view controllers that were being viewed (in the case of navigating to a screen, exiting the app, and then trying to open a file) and push the viewer onto the stack
    [navController popToRootViewControllerAnimated:NO];
    [navController pushViewController:viewer animated:NO];

    return viewer;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions { 

	// Status bar
	[application setStatusBarHidden:YES];
	
	// Sound Effects
	self.soundEffects = [[SoundEffects alloc] init];
	
	// Intro animation
	IntroViewController *intro = [[IntroViewController alloc] init];
	UINavigationController *navController = (UINavigationController*)self.window.rootViewController;
	[navController pushViewController:intro animated:NO];
	
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    
    // starting from the top-most visible view controller, save that child MOC and work backwards
    [self saveContext];
    
    [[NSUserDefaults standardUserDefaults] setObject:self.savedLocation forKey:DefaultsKeyRestoreLocation];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self saveContext];
    [[NSUserDefaults standardUserDefaults] setObject:self.savedLocation forKey:DefaultsKeyRestoreLocation];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(nonnull NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
	// == NOTE: In testing, this method is not called when trying to import a .grix file via AirDrop -LK, 2023-07-14
	
	// if this a request to open a Grix file
	if ([[url lastPathComponent]hasSuffix:@".grix"]) {
		NSData *compressedData = [NSData dataWithContentsOfURL:url];
		Artboard *artboard = [Artboard artboardWithExportedData:compressedData managedObjectContext:self.managedObjectContext];
		if (!artboard) return NO;
		
		NSError *error = [self saveContext];
		if (error) {
			NSLog(@"Error saving context after opening file %@",error);
		} else {
			// update the Gallery VC with the new artboard
			GalleryViewController *galleryVC = [((UINavigationController*)self.window.rootViewController).viewControllers objectAtIndex:0];
			[galleryVC addArtboard:artboard];
			
			// dismiss the info screen if it was being displayed
			[galleryVC dismissViewControllerAnimated:NO completion:nil];
			
			// push the Viewer VC
			NSInteger index = [galleryVC.artboards indexOfObject:artboard];
			[self instantiateAndPushViewerViewControllerWithIndex:index];
			
			return YES;
		}
	}
	
	return NO;
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
	return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Colors

- (UIColor*)shadowColor {
    return [UIColor colorWithRed:85.0/255.0 green: 93.0/255.0 blue: 96.0/255.0 alpha:1.0];
}

- (UIColor*)artboardBackgroundColor { 
    return [UIColor colorWithRed:94.0/255.0 green: 104.0/255.0 blue: 107.0/255.0 alpha:1.0];
}

- (UInt32)colorWithUIColor:(UIColor *)uiColor {
	CGFloat components[4] = {0, 0, 0, 0};
	UInt32 result = 0;
	UInt8 *resultPtr = (UInt8 *) &result;
	[uiColor getRed:&components[0] green:&components[1] blue:&components[2] alpha:&components[3]];
	resultPtr[0] = round(components[0] * 255.0);
	resultPtr[1] = round(components[1] * 255.0);
	resultPtr[2] = round(components[2] * 255.0);
	resultPtr[3] = round(components[3] * 255.0);
	return result;
}

#pragma mark - Getters

- (NSError*)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
	if ([managedObjectContext hasChanges]) {
		if ([managedObjectContext save:&error] == NO) {
            NSLog(@"Unresolved error saving Core Data context: %@, %@", error, [error userInfo]);
            [managedObjectContext rollback];
		}
	}
    
    return error;
}

#pragma mark - Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil)
    {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        __managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
        
    return __managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil)
    {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"eboy" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return __managedObjectModel;
}

- (NSURL*)storeURL {
    return [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"eboy.sqlite"];
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{    
    if (__persistentStoreCoordinator != nil)
    {
        return __persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [self storeURL];
    NSString *storePath = [storeURL path];
	NSLog(@"%@", storePath);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
	// If the expected store doesn't exist, copy the default store.
	if (![fileManager fileExistsAtPath:storePath]) {
		NSString *defaultStorePath = [[NSBundle mainBundle] pathForResource:@"FactoryDefautCoreData" ofType:@"sqlite"];
		if (defaultStorePath) {
			[fileManager copyItemAtPath:defaultStorePath toPath:storePath error:NULL];
		}
	}
	
	// Add persistent store
    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
	// Add the SQLite pragma journal_mode=delete to prevent the creation of a WAL file.
	// To export the Core Data store for use as a new FactoryDefaultsCoreData.sqlite file, go to the app's documents directory in the Simulator and copy the CoreData.sqlite file.
	NSDictionary *options = @{
							  NSMigratePersistentStoresAutomaticallyOption: @(YES),
							  NSInferMappingModelAutomaticallyOption:@(YES),
							  NSSQLitePragmasOption:@{ @"journal_mode": @"delete"}  };
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error])
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    return __persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end

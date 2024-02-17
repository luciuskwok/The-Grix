//
//  eboyAppDelegate.h
//  eboy
//
//  Created by Brian Papa on 8/5/11.
//  Copyright 2011 Felt Tip Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "SoundEffects.h"

UIKIT_EXTERN int TileUnitGridSize;
UIKIT_EXTERN int ArtboardTileGridSize;
UIKIT_EXTERN CGFloat EBoyBackgroundGrayscaleColor;
UIKIT_EXTERN CGFloat ArtboardTileSize;
UIKIT_EXTERN CGFloat EditTileUnitSize;
UIKIT_EXTERN CGFloat ArtboardTileDragAndRotateScaleFactor;
UIKIT_EXTERN CGFloat GalleryThumbnailSize;
UIKIT_EXTERN NSString* DefaultsKeyCurrentTwitterAccountUsername;
UIKIT_EXTERN NSString* DefaultsKeyTumblrAuthToken;
UIKIT_EXTERN NSString* DefaultsKeyTumblrAuthTokenSecret;
UIKIT_EXTERN NSString* DefaultsKeyTumblrUsername;
UIKIT_EXTERN NSString* DefaultsKeyTumblrPrimaryBlog;
UIKIT_EXTERN NSString* DefaultsKeyRestoreLocation;
UIKIT_EXTERN NSString* FacebookAppID;
UIKIT_EXTERN NSString* FacebookAccessTokenDefaultsKey;
UIKIT_EXTERN NSString* FacebookExpirationDateDefaultsKey;
UIKIT_EXTERN NSString* FacebookUsernameDefaultsKey;
UIKIT_EXTERN NSString* TumblrConsumerKey;
UIKIT_EXTERN NSString* TumblrConsumerSecret;
UIKIT_EXTERN NSInteger ArtboardTilePaletteScrollViewTag;
UIKIT_EXTERN NSInteger TileEditorSelectedColorAreaTag;
UIKIT_EXTERN NSInteger TileEditorColorPickerTag;

CGPoint gridForTileFrame(CGRect tileFrame);
CGPoint gridForUnitAtPoint(CGPoint point);

@class Tumblr, SoundEffects, Reachability;

@interface eboyAppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) SoundEffects *soundEffects;
@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) NSMutableArray *savedLocation;

- (UIColor*)shadowColor;
- (UIColor*)artboardBackgroundColor;
- (UInt32)colorWithUIColor:(UIColor *)uiColor;

// core data templated stuff
- (NSError*)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end

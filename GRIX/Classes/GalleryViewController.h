//
//  GalleryViewController.h
//  eboy
//
//  Created by Brian Papa on 8/6/11.
//  Copyright 2011 Felt Tip Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ColorPalette.h"
#import "GalleryArtboardFrame.h"

@class Artboard, ViewerViewController;

@interface GalleryViewController : UIViewController <UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet UIScrollView *artboardsScrollView;
@property (strong, nonatomic) IBOutlet UIView *topToolbar;
@property (strong, nonatomic) IBOutlet UIButton *addArtboardButton;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSArray *artboards;
@property (assign, nonatomic) NSInteger renderingStartIndex;
@property (strong, nonatomic) NSLock *renderingDeletedLock;
@property (assign, nonatomic) BOOL artboardWasDeleted;
@property (assign, nonatomic) BOOL isDoubleSegue;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (assign, nonatomic) UInt32 backgroundColor;
@property (assign, nonatomic) UInt32 shadowColor;


// Image view public methods
- (UIView *)artboardFrameViewAtIndex:(NSInteger)index;
- (CGRect)artboardFrameRectForIndex:(NSInteger)index;
- (void)setArtboardImage:(UIImage*)image atIndex:(NSInteger)index;
- (void)addArtboard:(Artboard *)artboard;

// Update for storyboard segues
- (void)setRenderingStartIndexForSelectedIndex:(NSInteger)index;
- (void)deleteArtboardAtIndex:(NSInteger)index;

// Restore Application State
- (void)restoreLevelWithSelectionArray:(NSArray *)selectionArray;

// IBActions
- (IBAction)createNewArtboard:(id)sender;

@end

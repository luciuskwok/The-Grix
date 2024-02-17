//
//  ArtboardViewController.h
//  eboy
//
//  Created by Brian Papa on 8/8/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TileView.h"
#import "ArtboardView.h"

@class TileView, ColorPalettesScrollView, Artboard, ArtboardView, ArtboardTilePalette;

@interface ArtboardViewController : UIViewController
<UIScrollViewDelegate, UIGestureRecognizerDelegate, CAAnimationDelegate>

// Top Level Scroll View
@property (strong, nonatomic) IBOutlet UIScrollView *mainScrollView;
@property (assign) CGFloat previousMainScrollViewContentOffsetY;

// Top Toolbar
@property (strong, nonatomic) IBOutlet UIView *topToolbar;
@property (strong, nonatomic) IBOutlet UIButton *undoButton;
@property (strong, nonatomic) IBOutlet UIButton *redoButton;
@property (strong, nonatomic) IBOutlet UIButton *lockButton;

// Color Palette Picker
@property (strong, nonatomic) NSArray *colorPalettes;
@property (strong, nonatomic) IBOutlet UIScrollView *colorPalettesScrollView;

// Artboard
@property (strong, nonatomic) Artboard *artboard;
@property (strong, nonatomic) IBOutlet ArtboardView *artboardView;
@property (nonatomic, retain) TileView *movingTileView;
@property (assign) BOOL isUndoingOrRedoing;

// Divider
@property (strong, nonatomic) IBOutlet UIView *dividerAndTilePickerContainerView;
@property (strong, nonatomic) IBOutlet UIButton *scrollLeftButton;
@property (strong, nonatomic) IBOutlet UIButton *scrollRightButton;
@property (strong, nonatomic) IBOutlet UIImageView *dividerThumbImageView;

// Tile Picker
@property (readonly) ArtboardTilePalette *currentArtboardTilePalette;
@property (strong, nonatomic) NSMutableArray *tilePaletteViews;
@property (strong, nonatomic) NSOrderedSet *tilePalettes;
@property (strong, nonatomic) IBOutlet UIScrollView *tilesScrollView;
@property (strong, nonatomic) IBOutlet UIView *tileboardView;
@property (strong, nonatomic) TileView *editingTileView;
@property (strong, nonatomic) UIPanGestureRecognizer *tilesScrollViewPanGestureRecognizer;
@property (assign) NSTimeInterval tileScrollViewPreviousDropTime;
@property (assign) CGFloat previousTilePickerContentOffsetX;

// Model
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSUndoManager *artboardViewUndoManager;

// Actions
- (IBAction)back:(id)sender;
- (IBAction)undo:(id)sender;
- (IBAction)redo:(id)sender;
- (IBAction)scrollRight:(id)sender;
- (IBAction)scrollLeft:(id)sender;
- (void)scrollToTilePaletteNumbered:(NSInteger)paletteNumber animated:(BOOL)animated;
- (void)restoreLevelWithSelectionArray:(NSArray *)selectionArray;

@end

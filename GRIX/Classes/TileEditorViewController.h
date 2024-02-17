//
//  TileEditorViewController.h
//  eboy
//
//  Created by Brian Papa on 8/9/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ColorPalette.h"

@class ColorPalette, Tile, TileEditCanvasView, SelectedColorView, ArtboardTile, SoundVoice;
@protocol ColorPaletteDelegate;

@interface TileEditorViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIView *colorPickerView;
@property (strong, nonatomic) IBOutlet TileEditCanvasView *canvasView;
@property (strong, nonatomic) ColorPalette *colorPalette;
@property (strong, nonatomic) ArtboardTile *artboardTile;
@property (assign) NSInteger selectedColorIndex;
@property (strong, nonatomic) IBOutlet UIButton *undoButton;
@property (strong, nonatomic) IBOutlet UIButton *redoButton;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) IBOutlet UIView *topToolbar;
@property (strong, nonatomic) IBOutlet UIView *tileEditorColorPickerContainer;
@property (assign) BOOL currentlyChangingColor;
@property (strong, nonatomic) UIView *selectedColorView;
@property (strong, nonatomic) UIImageView *selectedColorOverlayView;
@property (assign) NSInteger gestureColorIndex;

+ (NSInteger)selectedColorIndexUserDefault;

- (IBAction)back:(id)sender;
- (IBAction)undo:(id)sender;
- (IBAction)redo:(id)sender;
- (void)addColorPickerViews:(UIView*)aColorPickerView;
- (void)layoutColorPickerViews;

- (IBAction)logTileDataForPalettes:(id)sender; // for development only

@end

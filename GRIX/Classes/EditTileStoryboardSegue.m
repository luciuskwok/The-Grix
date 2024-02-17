//
//  EditTileStoryboardSegue.m
//  eboy
//
//  Created by Brian Papa on 9/30/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import "EditTileStoryboardSegue.h"
#import "ArtboardViewController.h"
#import "TileEditorViewController.h"
#import "TileView.h"
#import "eboyAppDelegate.h"
#import "TileEditCanvasView.h"
#import "ArtboardTile.h"
#import "ArtboardTilePalette.h"
#import "Artboard.h"
#import <QuartzCore/QuartzCore.h>

const NSTimeInterval SegueEditTileDuration = 0.5;

@implementation EditTileStoryboardSegue

- (void)perform {
    if ([self.sourceViewController isKindOfClass:[ArtboardViewController class]]) {
		// == Animate from Artboard Editor screen to Tile Editor screen ==
        ArtboardViewController *artboardController = self.sourceViewController;
        TileEditorViewController *tileController = self.destinationViewController;
        
		// Cause Tile Editor view to load.
		[tileController view];
		
		// Color picker slides up from the bottom.
		UIImageView *colorPicker = [self imageViewOfView:tileController.tileEditorColorPickerContainer withTopLevelView:tileController.view];
		CGRect colorPickerEnd = colorPicker.frame;
		colorPickerEnd.origin.y = tileController.view.bounds.size.height - colorPickerEnd.size.height;
		CGRect colorPickerStart = colorPickerEnd;
		colorPickerStart.origin.y = tileController.view.bounds.size.height;
		colorPicker.frame = colorPickerStart;
		[artboardController.view addSubview:colorPicker];
		
		// Tile being edited scales up.
		UIImage *tileImage = [artboardController.editingTileView renderedImage];
		UIImageView *tile = [[UIImageView alloc] initWithImage:tileImage];
		TileView *tileView = artboardController.editingTileView;
		tile.frame = [tileView convertRect:tileView.bounds toView:artboardController.view]; // Start frame.
		tile.layer.magnificationFilter = kCAFilterNearest;
        CGRect tileEnd = CGRectMake(0.0, tileController.topToolbar.frame.size.height, TileUnitGridSize * EditTileUnitSize, TileUnitGridSize * EditTileUnitSize);
        [artboardController.view addSubview:tile];
 		
		// Top toolbar dissolves.
		UIImageView *topToolbar = [self imageViewOfView:tileController.topToolbar withTopLevelView:tileController.view];
		topToolbar.alpha = 0.0;
		topToolbar.userInteractionEnabled = YES; // Intercept any touch events in the toolbar during the transition.
		[artboardController.view addSubview:topToolbar];
		
		// Disable UI interaction during animation.
		artboardController.mainScrollView.userInteractionEnabled = NO;
		
		// == Animation Block ==
        [UIView animateWithDuration:SegueEditTileDuration animations:^{
            tile.frame = tileEnd;
			colorPicker.frame = colorPickerEnd;
			topToolbar.alpha = 1.0;
        } completion:^(BOOL success) {
            [artboardController.navigationController pushViewController:tileController animated:NO];
			[colorPicker removeFromSuperview];
			[tile removeFromSuperview];
			[topToolbar removeFromSuperview];
            artboardController.mainScrollView.userInteractionEnabled = YES;
        }];
		
 		// Sound effects
		[UIAppDelegate.soundEffects playOpenTileEditorSound];
		
    } else {
 		// == Animate from Tile Editor screen to Artboard Editor screen ==
		ArtboardViewController *artboardController = self.destinationViewController;
        TileEditorViewController *tileController = self.sourceViewController;
        
        // load artboard controller if hasn't already been
        [artboardController view];
        
		// Make sure to redraw tile due to edits.
		[artboardController.editingTileView setNeedsDisplay];
		[artboardController.artboardView redrawArtboardImage];
        		
		// Tile being edited will shrink back to normal size. If the editing tile view in the Artboard was set (navigated to), then just use that bounds. If not (app was restored), calculate what the target should be
        CGRect tileEnd;
        if (artboardController.editingTileView) {
            tileEnd = [artboardController.editingTileView convertRect:artboardController.editingTileView.bounds toView:artboardController.view];
        } else {
            ArtboardTilePalette *tilePalette = tileController.artboardTile.tilePalette;
            NSInteger index = [tilePalette.artboardTiles indexOfObject:tileController.artboardTile];
            CGRect targetRect = CGRectMake(((int)index % ArtboardTileGridSize) * ArtboardTileSize, (int)index / ArtboardTileGridSize * ArtboardTileSize, ArtboardTileSize, ArtboardTileSize);
            tileEnd = [artboardController.tilesScrollView convertRect:targetRect toView:artboardController.view];
            
            // also, the tile palette picker needs to be auto-scrolled
            NSInteger artboardIndex = [tilePalette.artboard.tilePalettes indexOfObject:tilePalette];
            [artboardController scrollToTilePaletteNumbered:artboardIndex animated:NO];
        }
        
        // Use snapshot of Artboard Editor as background.
		UIImageView *artboard = [self imageViewOfView:artboardController.view  withTopLevelView:artboardController.view];
		[tileController.view insertSubview:artboard atIndex:0];
		
		// Color picker slides down off screen.
		CGRect colorPickerEnd = tileController.tileEditorColorPickerContainer.frame;
		colorPickerEnd.origin.y = artboardController.view.bounds.size.height;
		
		// Top toolbar dissolves.
		UIImageView *topToolbar = [self imageViewOfView:artboardController.topToolbar withTopLevelView:artboardController.view];
		topToolbar.alpha = 0.0;
		topToolbar.userInteractionEnabled = YES; // Intercept any touch events in the toolbar during the transition.
		[tileController.view addSubview:topToolbar];
        
		// Disable UI interaction during animation.
		tileController.tileEditorColorPickerContainer.userInteractionEnabled = NO;
		tileController.canvasView.userInteractionEnabled = NO;
        
		// == Animation Block ==
		[UIView animateWithDuration:SegueEditTileDuration animations:^{
			tileController.canvasView.frame = tileEnd;
			tileController.tileEditorColorPickerContainer.frame = colorPickerEnd;
			topToolbar.alpha = 1.0;
		} completion:^(BOOL success) {
			[tileController.navigationController popViewControllerAnimated:NO];
			[artboard removeFromSuperview];
			[topToolbar removeFromSuperview];
			tileController.tileEditorColorPickerContainer.userInteractionEnabled = YES;
			tileController.canvasView.userInteractionEnabled = YES;
		}];
        // Sound effects
        [UIAppDelegate.soundEffects playCloseTileEditorSound];
    }
}

@end

//
//  ArtboardViewController.m
//  eboy
//
//  Created by Brian Papa on 8/8/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import "ArtboardViewController.h"
#import "TileView.h"
#import "ColorPalette.h"
#import "ColorPaletteView.h"
#import "TileEditorViewController.h"
#import "Artboard.h"
#import "ArtboardView.h"
#import "eboyAppDelegate.h"
#import "ArtboardTilePalette.h"
#import "EditArtboardStoryboardSegue.h"
#import "ViewerViewController.h"
#import "PlacedTile.h"
#import "ArtboardTile.h"
#import "UIView+Setup.h"
#import "DragGestureRecognizer.h"
#import <QuartzCore/QuartzCore.h>

const CGFloat ArtboardColorPaletteWidth = 62.0;
const CGFloat ArtboardColorPaletteHeight = 71.0;
const CGFloat ArtboardColorPaletteOriginY = 4.0;
const CGFloat ArtboardColorPalettePickerGapSize = 12.0;
const NSTimeInterval ArtboardViewPlaceTileAnimationDuration = 0.25;
const NSTimeInterval ArtboardViewRotateTileAnimationDuration = 0.125;
const NSTimeInterval ArtboardViewMinimumLongPressDuration = 0.1;
const NSTimeInterval ArtboardViewPlaceTileDarkenDuration = 0.25;
const NSInteger ArtboardUndoButtonTag = 82181918;
const NSInteger ArtboardRedoButtonTag = 83847738;
const NSInteger ArtboardTilePaletteTagBase = 10000;

@implementation ArtboardViewController


#pragma mark - Utility methods

- (void)selectColorPaletteAtIndex:(NSInteger)index {
	if (index < 0) 
		index =0;
	if (index > self.colorPalettes.count - 1)
		index = self.colorPalettes.count - 1;
	
	ColorPalette *newSelectedPalette = [self.colorPalettes objectAtIndex:index];
	if (self.artboard.unsavedColorPalette != newSelectedPalette) {
 		// Play sound effect for changing color palette
		[UIAppDelegate.soundEffects playColorPaletteClickSound];
		
		[newSelectedPalette makeSelectedPalette];
				
		// Set selected state of color palette.
		for (id view in self.colorPalettesScrollView.subviews) {
			if ([view respondsToSelector:@selector(setSelected:)]) {
				[view setSelected:([view tag] == index)];
			}
		}
		
		// Update domain object's transient property
		self.artboard.unsavedColorPalette = newSelectedPalette;
		
		// Update subviews
		[self.artboardView redrawArtboardImage];
	}
}

- (void)selectColorPaletteBasedOnContentOffset:(CGFloat)offset {
	CGFloat index = round ((offset + self.colorPalettesScrollView.contentInset.left) / (ArtboardColorPaletteWidth + ArtboardColorPalettePickerGapSize));
	[self selectColorPaletteAtIndex:index];
}

- (void)refreshAllTileColors {
	// Refresh the colors of all tiles.
	for (UIView *tilePalette in self.tilesScrollView.subviews) {
		for (TileView *tileView in tilePalette.subviews)
			[tileView setNeedsDisplay];
	}
}

- (void)updateScrollLeftRightButtons {
	UIScrollView *sv = self.tilesScrollView;
	self.scrollLeftButton.enabled = sv.contentOffset.x > 0.5;
	self.scrollRightButton.enabled = sv.contentOffset.x < sv.contentSize.width - sv.frame.size.width - 0.5;
}

- (void)updateUndoRedoButtons {
    self.undoButton.enabled = [self.managedObjectContext.undoManager canUndo];
    self.redoButton.enabled = [self.managedObjectContext.undoManager canRedo];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (ArtboardTilePalette*)currentArtboardTilePalette {
    CGPoint currentOffset = self.tilesScrollView.contentOffset;
    NSInteger tileIndex = currentOffset.x / self.tilesScrollView.frame.size.width;
    return [self.tilePalettes objectAtIndex:tileIndex];
}

- (void)loadTilePalettesScrollViewWithPage:(NSInteger)page {
    if (page < 0)
        return;
    if (page >= self.tilePalettes.count)
        return;
    
    CGSize tilesScrollViewSize = self.tilesScrollView.frame.size;
    CGRect tilePaletteViewFrame = CGRectMake(tilesScrollViewSize.width * page, 0.0, tilesScrollViewSize.width, tilesScrollViewSize.height);
	
    UIView *currentTilePaletteView = [self.tilePaletteViews objectAtIndex:page];
    if ((NSNull*)currentTilePaletteView == [NSNull null]) {
        currentTilePaletteView = [[UIView alloc] initWithFrame:tilePaletteViewFrame];   
        currentTilePaletteView.tag = ArtboardTilePaletteTagBase + page;
        [self.tilePaletteViews replaceObjectAtIndex:page withObject:currentTilePaletteView];   
	
        ArtboardTilePalette *tilePalette = [self.tilePalettes objectAtIndex:page];
        for (NSInteger i = 0; i < tilePalette.artboardTiles.count; i++) {
            ArtboardTile *tile = [tilePalette.artboardTiles objectAtIndex:i];
            CGRect tileRect = CGRectMake((i % ArtboardTileGridSize) * ArtboardTileSize, i / ArtboardTileGridSize * ArtboardTileSize, ArtboardTileSize, ArtboardTileSize);
            TileView *tileView = [[TileView alloc] initWithFrame:tileRect tile:tile];
            [currentTilePaletteView addSubview:tileView];
        }
    }
    
    // ensure proper frame is set
    currentTilePaletteView.frame = tilePaletteViewFrame;
    
    // add the placeholder view to the scroll view
    [self.tilesScrollView addSubview:currentTilePaletteView];
}

- (void)enableArtboardGestureRecognizers:(BOOL)enabled {
    // undos still depend on undo stack state
    if ([self.managedObjectContext.undoManager canUndo])
        self.undoButton.enabled = enabled;
    else
        self.undoButton.enabled = NO;
    if ([self.managedObjectContext.undoManager canRedo])
        self.redoButton.enabled = enabled;
    else 
        self.redoButton.enabled = NO;
        
    self.tilesScrollViewPanGestureRecognizer.enabled = enabled;
    self.mainScrollView.userInteractionEnabled = enabled;
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set these since we aren't using a standard UIToolbar, and to prevent Artboard edits at the same time that a button is pressed
	[self.topToolbar setupSubviewsToBePixelatedAndExclusiveTouch];
	[self.dividerAndTilePickerContainerView setupSubviewsToBePixelatedAndExclusiveTouch];
    self.artboardView.exclusiveTouch = YES;
    self.tilesScrollView.exclusiveTouch = YES;
    
	// == Main scroll view ==
	BOOL tallScreen = (self.mainScrollView.frame.size.height >= 508.0);
	const CGFloat kContentHeight = tallScreen? 528.0 : 500.0;
    self.mainScrollView.contentSize = CGSizeMake(self.view.frame.size.width, kContentHeight);
    self.mainScrollView.panGestureRecognizer.minimumNumberOfTouches = 1;
    self.mainScrollView.panGestureRecognizer.maximumNumberOfTouches = 2;
	self.mainScrollView.delaysContentTouches = NO;
	
    // Scroll to hide color palette picker.
	self.previousMainScrollViewContentOffsetY = self.colorPalettesScrollView.frame.size.height;
	CGFloat maxContentOffsetY = kContentHeight - self.mainScrollView.frame.size.height;
	if (maxContentOffsetY < 0.0) {
		maxContentOffsetY = 0.0;
	}
	
	// Disable scrolling if screen is larger than scrollable content.
	if (self.mainScrollView.frame.size.height >= kContentHeight) {
		self.dividerThumbImageView.hidden = YES;
		self.mainScrollView.scrollEnabled = NO;
	}
	if (self.previousMainScrollViewContentOffsetY > maxContentOffsetY)
		self.previousMainScrollViewContentOffsetY = maxContentOffsetY;
    [self.mainScrollView setContentOffset:CGPointMake(0.0, self.previousMainScrollViewContentOffsetY)];
	            
    // == Set up Color Palette Picker view ==
    self.colorPalettes = [ColorPalette colorPalettes:self.managedObjectContext];
    
    float colorsContentSizeWidth = (self.colorPalettes.count * ArtboardColorPaletteWidth) + ((self.colorPalettes.count - 1) * ArtboardColorPalettePickerGapSize);
    self.colorPalettesScrollView.contentSize = CGSizeMake(colorsContentSizeWidth, self.colorPalettesScrollView.frame.size.height);
	self.colorPalettesScrollView.backgroundColor = [UIAppDelegate shadowColor];
	
	// Color palette picker scroll view: Insets
	CGFloat paletteInset = (self.colorPalettesScrollView.frame.size.width - ArtboardColorPaletteWidth) * 0.5;
	[self.colorPalettesScrollView setContentInset:UIEdgeInsetsMake(0.0, paletteInset, 0.0, paletteInset)];

	// Color palette picker scroll view: Selected palette
    ColorPalette *selectedPalette = self.artboard.colorPalette;
    if (selectedPalette)
        [selectedPalette makeSelectedPalette]; 
    else
        selectedPalette = [ColorPalette selectedColorPalette:self.managedObjectContext];
    CGFloat indexOfPalette = [self.colorPalettes indexOfObject:selectedPalette];
	CGFloat paletteContentOffsetX = (ArtboardColorPaletteWidth + ArtboardColorPalettePickerGapSize) * indexOfPalette - paletteInset;
    [self.colorPalettesScrollView setContentOffset:CGPointMake(paletteContentOffsetX, 0.0) animated:NO];
    
	// Create and add individual color palette views
	for (NSInteger i = 0; i < self.colorPalettes.count; i++) {
        CGFloat colorOriginX = (ArtboardColorPaletteWidth * i) + (ArtboardColorPalettePickerGapSize * i);
        CGRect frame = CGRectMake(colorOriginX, ArtboardColorPaletteOriginY, ArtboardColorPaletteWidth, ArtboardColorPaletteHeight);
        ColorPalette *palette = [self.colorPalettes objectAtIndex:i];
        ColorPaletteView *paletteView = [[ColorPaletteView alloc] initWithFrame:frame colorPalette:palette];
		paletteView.tag = i;
		[paletteView setSelected:(i == indexOfPalette)];
        [self.colorPalettesScrollView addSubview:paletteView];
		
		// Recognize tap gesture on palette view for selecting a color palette.
		UITapGestureRecognizer *paletteTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectColorPalette:)];
		paletteTapGestureRecognizer.numberOfTapsRequired = 1;
		[paletteView addGestureRecognizer:paletteTapGestureRecognizer];
    }
    
    // == Set up Artboard ==
    self.artboardView.artboard = self.artboard;
    self.artboardView.showGrid = YES;
	
	// Add tile tap and tile drag handlers
	__weak ArtboardViewController *weakSelf = self;
	self.artboardView.tileTapHandler = ^(UITouch *aTouch) {
		[weakSelf rotateTileWithTouch:aTouch];
	};
	self.artboardView.tileDragHandler = ^(UITouch *aTouch, UIGestureRecognizerState state) {
		[weakSelf moveTileWithTouch:aTouch state:state];
	};
	self.artboardView.touchPhaseChangedHandler = ^(UITouchPhase phase) {
		// Turn off scrolling while the main artboard is handling touches.
		if (phase == UITouchPhaseBegan) {
			weakSelf.mainScrollView.scrollEnabled = NO;
		} else if (phase == UITouchPhaseEnded || phase == UITouchPhaseCancelled) {
			if (weakSelf.mainScrollView.frame.size.height < weakSelf.mainScrollView.contentSize.height) {
				weakSelf.mainScrollView.scrollEnabled = YES;
			}
		}
	};
 
	// == Set up Tile Palette ==
	    
	// set up Tiles scroll view
    self.tilePalettes = self.artboard.tilePalettes;
    CGSize tilesScrollViewSize = self.tilesScrollView.frame.size;
    self.tilesScrollView.contentSize = CGSizeMake(self.tilePalettes.count * tilesScrollViewSize.width, tilesScrollViewSize.height);
	self.tilesScrollView.delaysContentTouches = NO;
	//self.tilesScrollView.scrollEnabled = NO;
	
	// Adjust for tall screen. 
	if (tallScreen) {
		CGRect tileAreaRect = self.dividerAndTilePickerContainerView.frame;
		tileAreaRect.size.height += 8;
		self.dividerAndTilePickerContainerView.frame = tileAreaRect;
	}
    
    // the tile palette views will be lazily loaded as the user scrolls. Start by loading only the first two palettes
    self.tilePaletteViews = [NSMutableArray array];
    for (unsigned i = 0; i < self.tilePalettes.count; i++) {
		[self.tilePaletteViews addObject:[NSNull null]];
    }
    [self loadTilePalettesScrollViewWithPage:0];
    [self loadTilePalettesScrollViewWithPage:1];
    	
	// Set up scroll buttons for tile picker area.
	[self updateScrollLeftRightButtons];
	
    // Set up Palette Gesture Recognizers - this is an additional pan gesture recognizer on the scroll view, which (apparently) already has a gesture recognizer to enable scrolling
    self.tilesScrollViewPanGestureRecognizer = [[DragGestureRecognizer alloc] initWithTarget:self action:@selector(handleTilesScrollViewPanGestureRecognizer:)];
	self.tilesScrollViewPanGestureRecognizer.maximumNumberOfTouches = 1;
	self.tilesScrollViewPanGestureRecognizer.minimumNumberOfTouches = 1;
    self.tilesScrollViewPanGestureRecognizer.delegate = self;
    [self.tilesScrollView addGestureRecognizer:self.tilesScrollViewPanGestureRecognizer];
        
    // change the default scroll view behaivor to 2 fingers
    self.tilesScrollView.panGestureRecognizer.minimumNumberOfTouches = 2;
    self.tilesScrollView.panGestureRecognizer.maximumNumberOfTouches = 2;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
        
    // redraw edit tile and set back to nil
    [self.editingTileView setNeedsDisplay];
    self.editingTileView = nil;
    
    // redraw the artboard view for when navigating back from edit
    [self.artboardView setNeedsDisplay];
    
    // Flash scroll indicators.
	[self.tilesScrollView flashScrollIndicators];

    // add undo managers
    NSUndoManager *undoManager = [[NSUndoManager alloc] init];
    self.managedObjectContext.undoManager = undoManager;
    [self updateUndoRedoButtons];
    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
	[dnc addObserver:self selector:@selector(managedObjectContextUndoManagerDidUndo:) name:NSUndoManagerDidUndoChangeNotification object:undoManager];
	[dnc addObserver:self selector:@selector(managedObjectContextUndoManagerDidRedo:) name:NSUndoManagerDidRedoChangeNotification object:undoManager];
    
    self.artboardViewUndoManager = [[NSUndoManager alloc] init];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // clear the saved location
    [UIAppDelegate.savedLocation replaceObjectAtIndex:2 withObject:@(-1)];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // save the color palette by assigning the unsaved property to the persisted property
    self.artboard.colorPalette = self.artboard.unsavedColorPalette;
    
    [UIAppDelegate saveContext];
    
	NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
    [dnc postNotificationName:ArtboardEditedNotification object:self.artboard.objectID];
	[dnc removeObserver:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showTileEditor"]) {
        TileEditorViewController *tileEditorViewController = segue.destinationViewController;
        
        // pass along this View Controller's MOC
        tileEditorViewController.managedObjectContext = self.managedObjectContext;
        
        // set the artboard tile to edit
        tileEditorViewController.artboardTile = self.editingTileView.artboardTile;
        
        // save this to the saved location array
        ArtboardTilePalette *currentPalette = self.currentArtboardTilePalette;
        NSInteger paletteIndex = [self.tilePalettes indexOfObject:currentPalette];
        NSInteger tileIndex = [currentPalette.artboardTiles indexOfObject:self.editingTileView.artboardTile];
        NSArray *tileIndexes = @[@(paletteIndex), @(tileIndex)];
        [UIAppDelegate.savedLocation replaceObjectAtIndex:2 withObject:tileIndexes];
    }
}

#pragma mark -
#pragma mark Restore Application State
- (void)restoreLevelWithSelectionArray:(NSArray *)selectionArray {
	if ([[selectionArray objectAtIndex:0] isKindOfClass:[NSArray class]]) {
        // move in tile editor and restore its content (not animated since the user should not see the restore process)
        TileEditorViewController *tileEditor = [self.storyboard instantiateViewControllerWithIdentifier:@"TileEditor"];
        tileEditor.managedObjectContext = self.managedObjectContext;
        NSArray *editingTileArray = [selectionArray objectAtIndex:0];
        NSInteger tilePaletteIndex = [[editingTileArray objectAtIndex:0] integerValue];
        NSInteger tileIndex = [[editingTileArray objectAtIndex:1] integerValue];
                
        // ignore invalid state values
        if (tilePaletteIndex < self.artboard.tilePalettes.count) {
            ArtboardTilePalette *artboardTilePalette = [self.artboard.tilePalettes objectAtIndex:tilePaletteIndex];            
            if (tileIndex < artboardTilePalette.artboardTiles.count) {
                ArtboardTile *artboardTile = [artboardTilePalette.artboardTiles objectAtIndex:tileIndex];
                tileEditor.artboardTile = artboardTile;
                                
                [self.navigationController pushViewController:tileEditor animated:NO];	
            }
        }
    }
}


#pragma mark - Actions

- (IBAction)back:(id)sender {	
    UIViewController *previousViewController = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count - 2];
    if ([previousViewController isKindOfClass:[ViewerViewController class]]) {
        EditArtboardStoryboardSegue *segue = [[EditArtboardStoryboardSegue alloc] initWithIdentifier:@"edit" source:self destination:previousViewController];
        [segue perform];
    }
}

- (IBAction)undo:(id)sender {
    // disable undo/redo buttons, to be enabled when the UI is done performing the action
    self.undoButton.enabled = NO;
    self.redoButton.enabled = NO;
    
    [self.managedObjectContext undo];    
}

- (IBAction)redo:(id)sender {
    // disable undo/redo buttons, to be enabled when the UI is done performing the action
    self.undoButton.enabled = NO;
    self.redoButton.enabled = NO;

    [self.managedObjectContext redo];
}

- (IBAction)scrollRight:(id)sender {
    // ignore action if not at page start
    if (fmodf(self.tilesScrollView.contentOffset.x, self.tilesScrollView.frame.size.width) == 0) {   
        CGFloat pageWidth = self.tilesScrollView.frame.size.width;
        CGPoint newOffset = self.tilesScrollView.contentOffset;
        newOffset.x += pageWidth;
        CGFloat limit = self.tilesScrollView.contentSize.width - pageWidth;
        if (newOffset.x > limit)
            newOffset.x = limit;
        [self.tilesScrollView setContentOffset:newOffset animated:YES];
    }
}

- (IBAction)scrollLeft:(id)sender {
    // ignore action if not at page start
    if (fmodf(self.tilesScrollView.contentOffset.x, self.tilesScrollView.frame.size.width) == 0) {    
        CGFloat pageWidth = self.tilesScrollView.frame.size.width;
        CGPoint newOffset = self.tilesScrollView.contentOffset;
        newOffset.x -= pageWidth;
        if (newOffset.x < 0.0)
            newOffset.x = 0.0;
        [self.tilesScrollView setContentOffset:newOffset animated:YES];
    }
}

- (void)scrollToTilePaletteNumbered:(NSInteger)paletteNumber animated:(BOOL)animated {
    CGFloat pageWidth = self.tilesScrollView.frame.size.width;
    CGPoint newOffset = CGPointMake(pageWidth * paletteNumber,0.0);
    [self.tilesScrollView setContentOffset:newOffset animated:animated];
}

#pragma mark - Artboard actions

- (void)rotateTileWithTouch:(UITouch*)touch {
	// temporarily create tile views
	CGPoint tappedPointInArtboard = [touch locationInView:self.artboardView];
	NSDictionary *temporaryTileViews = [self.artboardView tileViewsForRotationAtPoint:tappedPointInArtboard];
	TileView *tileViewToRotate = [temporaryTileViews objectForKey:ArtboardTileViewToRotateKey];
	NSArray *neighborTileViews = [temporaryTileViews objectForKey:ArtboardNeighborTileViewsKey];
	
	// adjust tile view frames for artboard view
	tileViewToRotate.frame = [self.mainScrollView convertRect:tileViewToRotate.frame fromView:self.artboardView];
	for (TileView *tileView in neighborTileViews) {
		tileView.frame = [self.mainScrollView convertRect:tileView.frame fromView:self.artboardView];
	}
	
	if (tileViewToRotate) {
		// disable gesture recognizers until animation completes
		[self enableArtboardGestureRecognizers:NO];
		
		// register the undo
		NSMutableDictionary *undoDictionary = [NSMutableDictionary dictionaryWithObject:@(1) forKey:@"rotations"];
		[undoDictionary addEntriesFromDictionary:temporaryTileViews];
		[self.artboardViewUndoManager registerUndoWithTarget:self selector:@selector(undoTileRotate:) object:undoDictionary];
		
		[self rotateWithTileViews:temporaryTileViews direction:1];
	}
}

- (void)rotateWithTileViews:(NSDictionary*)temporaryTileViews direction:(int)direction {
	// update artboard view so that an empty area is shown underneath the tile view as it rotates
	[self.artboardView redrawArtboardImage];
	
	TileView *tileViewToRotate = [temporaryTileViews objectForKey:ArtboardTileViewToRotateKey];
	NSArray *neighborTileViews = [temporaryTileViews objectForKey:ArtboardNeighborTileViewsKey];
	
	// add the tile views temporarily - mark as setNeedsDisplay so that any change to the selected color palette since the tile views creation is applied
	[self.mainScrollView insertSubview:tileViewToRotate belowSubview:self.tileboardView];
	[tileViewToRotate setNeedsDisplay];
	for (TileView *tileView in neighborTileViews) {
		[self.mainScrollView insertSubview:tileView belowSubview:self.tileboardView];
		[tileView setNeedsDisplay];
	}
	
	// Sound
	[UIAppDelegate.soundEffects playTileRotationStartedSoundWithTapCount:1];
	
	// if rotated via user interaction, placed tile orientation is starting orientation. If via undo/redo, the placed tile orientation is the target orientation
	PlacedTileOrientation shadowStartingOrientation = tileViewToRotate.placedTile.orientation;
	if (self.isUndoingOrRedoing) {
		shadowStartingOrientation = [PlacedTile orientation:tileViewToRotate.placedTile.orientation withRotations:-direction];
	}
	
	// create seperate animations for the shadow and tile. The tile's layer is rotated, while the shadow is moved so that it appears natural
	CABasicAnimation *shadowAnimation = [CABasicAnimation animationWithKeyPath:@"shadowOffset"];
	shadowAnimation.toValue = [self shadowOffsetForOrientation:shadowStartingOrientation rotations:direction tileSize:tileViewToRotate.frame.size];
	
	CABasicAnimation *tileAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
	tileAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DRotate(tileViewToRotate.layer.transform, direction * M_PI_2, 0, 0, 1)];
	
	CAAnimationGroup *theGroup = [CAAnimationGroup animation];
	theGroup.animations = @[shadowAnimation, tileAnimation];
	theGroup.delegate = self;
	theGroup.removedOnCompletion = NO;
	theGroup.fillMode = kCAFillModeForwards;
	theGroup.duration = ArtboardViewRotateTileAnimationDuration;
	[tileViewToRotate.layer addAnimation:theGroup forKey:@"animateRotation"];
}

- (void)moveTileWithTouch:(UITouch*)touch state:(UIGestureRecognizerState)state {
	if (state == UIGestureRecognizerStateBegan) {
		// create a temporary Tile View corresponding to the tapped point on the artboard
		CGPoint pressPointInArtboard = [touch locationInView:self.artboardView];
		self.movingTileView = [self.artboardView tileViewForMovingAtPoint:pressPointInArtboard];
		if (self.movingTileView) {
			self.movingTileView.center = [self.view convertPoint:self.movingTileView.center fromView:self.artboardView];
			[self.view addSubview:self.movingTileView];
			
			[self.movingTileView grab];
		}
	} else if (state == UIGestureRecognizerStateChanged) {
		if (self.movingTileView) {
			CGPoint pressPointInArtboard = [touch locationInView:self.artboardView];
			self.movingTileView.center = [self.view convertPoint:pressPointInArtboard fromView:self.artboardView];
		}
	} else if ((state == UIGestureRecognizerStateEnded) || (state == UIGestureRecognizerStateCancelled)) {
		
		if (self.movingTileView) {
			// the model object for the tile, which holds the grid information for the original location
			PlacedTile *existingTile = self.movingTileView.placedTile;
			
			// move or delete depending on where gesture ended
			CGPoint centerInScrollView = [touch locationInView:self.mainScrollView];
			if (CGRectContainsPoint(self.artboardView.frame, centerInScrollView)) {
				// disable this gesture recognizer until the placement completes
				[self enableArtboardGestureRecognizers:NO];
				
				TileView *tileViewToPlace = self.movingTileView;
				self.movingTileView = nil;
				[self placeTile:tileViewToPlace atPoint:[touch locationInView:self.artboardView]];
			} else {
				// Sound effect
				[UIAppDelegate.soundEffects playTileDroppedSound];
				
				// register the undo
				NSDictionary *undoDictionary = @{@"tileViewToRestore":self.movingTileView, @"gridX":@(existingTile.gridX), @"gridY":@(existingTile.gridY)};
				[self.artboardViewUndoManager registerUndoWithTarget:self selector:@selector(undoTileDelete:) object:undoDictionary];
				
				[self.artboard deleteTileFromX:existingTile.gridX y:existingTile.gridY];
				
				[self.movingTileView removeFromSuperview];
				self.movingTileView = nil;
				self.artboardView.currentlyMovingTile = nil;
				[self.artboardView redrawArtboardImage];
				
				[self updateUndoRedoButtons];
			}
		}
	}
}


#pragma mark - Gesture Recognizers

- (void)selectColorPalette:(UITapGestureRecognizer*)sender
{
	NSInteger index = sender.view.tag;
	CGFloat x = index * (ArtboardColorPaletteWidth + ArtboardColorPalettePickerGapSize) - self.colorPalettesScrollView.contentInset.left;

	[self.colorPalettesScrollView setContentOffset:CGPointMake(x, 0.0) animated:YES];
}

- (NSValue*)shadowOffsetForOrientation:(PlacedTileOrientation)orientation rotations:(int)rotations tileSize:(CGSize)tileSize {
    
    CGSize shadowOffsetRightsideUp = CGSizeMake(tileSize.width / TileViewShadowSizeFactor,  tileSize.height / TileViewShadowSizeFactor);
    CGSize shadowOffsetOnRightside = CGSizeMake(tileSize.width / TileViewShadowSizeFactor, -tileSize.height / TileViewShadowSizeFactor);
    CGSize shadowOffsetUpsideDown = CGSizeMake(-tileSize.width / TileViewShadowSizeFactor, -tileSize.height / TileViewShadowSizeFactor);
    CGSize shadowOffsetOnLeftside = CGSizeMake(-tileSize.width / TileViewShadowSizeFactor, tileSize.height / TileViewShadowSizeFactor);
    
    CGSize tileShadowOffset;
        
    if (orientation == PlacedTileOnLeftSide) {
        if (rotations == 1 || rotations == -3)
            tileShadowOffset = shadowOffsetRightsideUp;
        else if (rotations == 2 || rotations == -2)
            tileShadowOffset = shadowOffsetOnRightside;
        else
            tileShadowOffset = shadowOffsetUpsideDown;
    } else if (orientation == PlacedTileRightSideUp) {
        if (rotations == 1 || rotations == -3)
            tileShadowOffset = shadowOffsetOnRightside;
        else if (rotations == 2 || rotations == -2)
            tileShadowOffset = shadowOffsetUpsideDown;
        else
            tileShadowOffset = shadowOffsetOnLeftside;
    } else if (orientation == PlacedTileOnRightSide) {
        if (rotations == 1 || rotations == -3)
            tileShadowOffset = shadowOffsetUpsideDown;
        else if (rotations == 2 || rotations == -2)
            tileShadowOffset = shadowOffsetOnLeftside;
        else
            tileShadowOffset = shadowOffsetRightsideUp;
    } else {
        if (rotations == 1 || rotations == -3)
            tileShadowOffset = shadowOffsetOnLeftside;
        else if (rotations == 2 || rotations == -2)
            tileShadowOffset = shadowOffsetRightsideUp;
        else
            tileShadowOffset = shadowOffsetOnRightside;
    }

    return [NSValue valueWithCGSize:tileShadowOffset];
}

- (void)placeTile:(TileView*)tileView atPoint:(CGPoint)artboardPoint {
    // the model object for the tile, which holds the grid information for the original location if this is a moved tile. If it's a new tile, then there is no existing tile yet as it will be created by the domain
    PlacedTile *existingTile = tileView.placedTile;
    
    int destinationGridX = artboardPoint.x / ArtboardTileSize;
    int destinationGridY = artboardPoint.y / ArtboardTileSize;
    CGPoint destinationCenterInArtboard = [self.artboardView centerForGridX:destinationGridX gridY:destinationGridY];
    CGPoint destinationCenter = [self.view convertPoint:destinationCenterInArtboard fromView:self.artboardView];
    [UIView animateWithDuration:ArtboardViewPlaceTileAnimationDuration animations:^{
        tileView.center = destinationCenter;
        tileView.transform = CGAffineTransformMakeRotation(-existingTile.rotationAngle);
    } completion:^(BOOL finished) {
 		// Play sound effect for placing tile
		[UIAppDelegate.soundEffects playTilePlaceSoundAtX:destinationGridX y:destinationGridY];
		
       // domain and undo depends on if this was a tile addition, a moved tile to a new spot, or a moved tile to the same spot in which case nothing happens
        if (!existingTile) {
            // register the undo
			NSDictionary *undoDictionary = @{ @"gridX":@(destinationGridX),  @"gridY":@(destinationGridY) };
            [self.artboardViewUndoManager registerUndoWithTarget:self selector:@selector(undoTileAdd:) object:undoDictionary];
            
            [self.artboard addTile:tileView.artboardTile gridX:(int)destinationGridX gridY:(int)destinationGridY];
        } else if (existingTile.gridX != destinationGridX || existingTile.gridY != destinationGridY) {
            // dictionary for undo
            NSMutableDictionary *undoDictionary = [NSMutableDictionary dictionaryWithCapacity:8];
			[undoDictionary addEntriesFromDictionary:@{@"tileView":tileView, @"gridX":@(existingTile.gridX), @"gridY":@(existingTile.gridY)}];
            
            // get any tile that already exists at this position, which will be displayed in case the user does a redo. Use the Artboard Tile since at the time we need to use this, the PlacedTile will have been deleted from persistence and thus no longer associated with an Artboard
            PlacedTile *replacedTile = [self.artboard tileAtGridX:destinationGridX gridY:destinationGridY];
            if (replacedTile) {
                [undoDictionary setObject:replacedTile.tile forKey:@"replacedTile"];
                [undoDictionary setObject:@(replacedTile.orientation) forKey:@"tileToBeCoveredOrientation"];
            }
            
            [self.artboardViewUndoManager registerUndoWithTarget:self selector:@selector(undoTileMove:) object:undoDictionary];
            
            [self.artboard moveTileFromX:existingTile.gridX fromY:existingTile.gridY toX:destinationGridX toY:destinationGridY];            
        }
        
        [self updateUndoRedoButtons];
        
        [tileView removeFromSuperview];
		self.artboardView.currentlyMovingTile = nil;
		[self.artboardView redrawArtboardImage];

		// Add an animation of a black UIView that fades in and out to add an effect that eBoy asked for: "When dropping a tile on the Matrix, could you make it darker for a short moment and then lighten it up to its default state? It would be a subtle animation suggesting a tile needs time to fit in when dropped."
		UIView *blackView = [[UIView alloc] initWithFrame:tileView.frame];
		blackView.backgroundColor = [UIColor blackColor];
		blackView.alpha = 0.0;
		blackView.opaque = YES;
		blackView.userInteractionEnabled = NO;
		[self.view addSubview:blackView];
		[UIView animateWithDuration:ArtboardViewPlaceTileDarkenDuration * 0.25 animations:^{
			blackView.alpha = 0.5;
		} completion:^(BOOL finished) {
			[UIView animateWithDuration:ArtboardViewPlaceTileDarkenDuration * 0.75 animations:^{
				blackView.alpha = 0.0;
			} completion:^(BOOL finished) {
				[blackView removeFromSuperview];
			}];
		}];
        
        // it is now safe to reenable the artboard gesture recognizers
        [self enableArtboardGestureRecognizers:YES];
    }];
}

- (IBAction)handleTilesScrollViewPanGestureRecognizer:(UIPanGestureRecognizer*)sender {    

    if (sender.state == UIGestureRecognizerStateBegan) {
        // get the tile view at the touch location
		CGPoint pointInScrollView = [sender locationInView:self.tilesScrollView];
        UIView *currentTilePalette = nil;
		for (UIView *aView in self.tilesScrollView.subviews) {
			if (CGRectContainsPoint(aView.frame, pointInScrollView)) {
				currentTilePalette = aView;
			}
		}
		
        CGPoint pointInTilePaletteView = [sender locationInView:currentTilePalette];
        if (currentTilePalette != nil && CGRectContainsPoint(currentTilePalette.bounds, pointInTilePaletteView)) {   
			TileView *pickedTileView = nil;
            for (TileView *tileView in currentTilePalette.subviews) {
                if (CGRectContainsPoint(tileView.frame, pointInTilePaletteView)) {
                    pickedTileView = tileView;
				}
            }
            
			if (pickedTileView != nil) {
				// Copy the tile and set up properties.
				TileView *newTileView = [[TileView alloc] initWithFrame:pickedTileView.frame tile:pickedTileView.artboardTile];
				newTileView.initialCenter = pickedTileView.center;
				newTileView.center = [sender locationInView:self.view];
				newTileView.transform = pickedTileView.transform;
				[self.view addSubview:newTileView];
				self.movingTileView = newTileView;
				[self.movingTileView grab];
			}

			// Picked tile is potentially the tile to edit if this is a double-tap
			self.editingTileView = pickedTileView;
		}
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        // move tile
		self.movingTileView.center = [sender locationInView:self.view];
    } else if ((sender.state == UIGestureRecognizerStateCancelled) || (sender.state == UIGestureRecognizerStateEnded)) {
        // End or cancel gesture.
        if (self.movingTileView) {            
            CGPoint centerInScrollView = [sender locationInView:self.mainScrollView];
			if (CGRectContainsPoint(self.artboardView.frame, centerInScrollView)) {
                // disable other gestures until animation completes
                [self enableArtboardGestureRecognizers:NO];
                
                TileView *tileViewToPlace = self.movingTileView;
                self.movingTileView = nil;
                [self placeTile:tileViewToPlace atPoint:[sender locationInView:self.artboardView]];
            } else {
				// Tile dropped and not placed.
				// Sound effect
				[UIAppDelegate.soundEffects playTileDroppedSound];
				
				// Detect double-taps
				NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
				if (now - self.tileScrollViewPreviousDropTime < 0.5 && self.editingTileView) {
					[self performSegueWithIdentifier:@"showTileEditor" sender:self.movingTileView];
				}
				self.tileScrollViewPreviousDropTime = now;
			}
            [self.movingTileView removeFromSuperview];
            [self updateUndoRedoButtons];
        }
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
	if (gestureRecognizer == self.tilesScrollViewPanGestureRecognizer) {
		return !self.artboardView.isDraggingTile;
	}
    return YES;
}

#pragma mark - CAAnimation delegate methods

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {
    CAAnimationGroup *theGroup = (CAAnimationGroup*)theAnimation;
    
    // get the rotated tile view and remove the neighbors
    TileView *rotatedTileView;
    for (UIView *subview in self.mainScrollView.subviews) {
        if ([subview isKindOfClass:[TileView class]]) {
            if (subview.tag == ArtboardTileViewToRotateTag) 
                rotatedTileView = (TileView*)subview;
            else
                [subview removeFromSuperview];
        }
    }
        
    // need to update the layer transform and shadow after animation has completed
    CAAnimation *shadowAnimation = [theGroup.animations objectAtIndex:0];
    CAAnimation *transformAnimation = [theGroup.animations objectAtIndex:1];
    if ([shadowAnimation isKindOfClass:[CABasicAnimation class]]) {
        rotatedTileView.layer.shadowOffset = [((CABasicAnimation*)shadowAnimation).toValue CGSizeValue];
        rotatedTileView.layer.transform = [((CABasicAnimation*)transformAnimation).toValue CATransform3DValue];
    } else {
        rotatedTileView.layer.shadowOffset = [[((CAKeyframeAnimation*)shadowAnimation).values lastObject] CGSizeValue];
        rotatedTileView.layer.transform = [[((CAKeyframeAnimation*)transformAnimation).values lastObject] CATransform3DValue];
    }
    
    // only update the domain model if not in the process of undoing, in which case the model was already updated by Core Data's undo manager
    if (!self.isUndoingOrRedoing)
        [rotatedTileView.placedTile rotate:1];
    
	// Redraw artboard
	self.artboardView.currentlyMovingTile = nil;
	[self.artboardView redrawArtboardImage];
    [self updateUndoRedoButtons];
    [rotatedTileView removeFromSuperview];
    
    self.isUndoingOrRedoing = NO;    
    
    // rennable gesture recognizers
    [self enableArtboardGestureRecognizers:YES];
}

#pragma mark - Scroll View delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if (scrollView == self.mainScrollView) {
		CGFloat middleY = (scrollView.contentSize.height - scrollView.bounds.size.height) * 0.5;
		if (scrollView.contentOffset.y < middleY) {
			if (self.previousMainScrollViewContentOffsetY >= middleY) {
				[self.colorPalettesScrollView flashScrollIndicators];
				[UIAppDelegate.soundEffects playDrawerOpenCloseSound];
			}
		} else {
			if (self.previousMainScrollViewContentOffsetY < middleY) {
				[self.tilesScrollView flashScrollIndicators];
				[UIAppDelegate.soundEffects playDrawerOpenCloseSound];
			}
		}
		self.previousMainScrollViewContentOffsetY = scrollView.contentOffset.y;
		
		// Change the alpha of the left/right scroll buttons based on the origin.y of the scroll view.
		CGFloat alpha = scrollView.contentOffset.y / (scrollView.contentSize.height - scrollView.frame.size.height);
		self.scrollLeftButton.alpha = alpha;
		self.scrollRightButton.alpha = alpha;
		self.scrollLeftButton.userInteractionEnabled = (alpha > 0.5);
		self.scrollRightButton.userInteractionEnabled = (alpha > 0.5);
	} else if (scrollView == self.colorPalettesScrollView) {
		[self selectColorPaletteBasedOnContentOffset:scrollView.contentOffset.x];
	} else if (scrollView == self.tilesScrollView) {
		[self updateScrollLeftRightButtons];
		
		// Click 4 times for every page.
		CGFloat pageWidth = scrollView.frame.size.width;
		CGFloat oldSection = round (self.previousTilePickerContentOffsetX / pageWidth * 4.0);
		CGFloat newSection = round (scrollView.contentOffset.x / pageWidth * 4.0);
		if (oldSection != newSection) {
			[UIAppDelegate.soundEffects playTilePaletteClickSound];
		}
		
		// When crossing the boundaries between tile sets, play a sound and load the following page so that it will be drawn before the next scroll
		CGFloat oldPage = round(self.previousTilePickerContentOffsetX / pageWidth);
		CGFloat newPage = round(scrollView.contentOffset.x / pageWidth);
		if (oldPage != newPage) {
            [self loadTilePalettesScrollViewWithPage:newPage - 1];
            [self loadTilePalettesScrollViewWithPage:newPage];
            [self loadTilePalettesScrollViewWithPage:newPage + 1];
		}
		self.previousTilePickerContentOffsetX = scrollView.contentOffset.x;
	}
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (scrollView == self.mainScrollView) {
        CGFloat maxY = scrollView.contentSize.height - scrollView.bounds.size.height;
		if (targetContentOffset->y < maxY * 0.5) 
			targetContentOffset->y = 0.0;
		else
			targetContentOffset->y = maxY;
    } if (scrollView == self.colorPalettesScrollView) {
		CGFloat step = (ArtboardColorPaletteWidth + ArtboardColorPalettePickerGapSize);
		CGFloat index = round ((targetContentOffset->x + scrollView.contentInset.left + ArtboardColorPalettePickerGapSize * 0.5) / step);
		if (index < 0) 
			index =0;
		if (index > self.colorPalettes.count - 1)
			index = self.colorPalettes.count - 1;
		targetContentOffset->x = index * step - scrollView.contentInset.left;
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView == self.colorPalettesScrollView) {
		[self selectColorPaletteBasedOnContentOffset:scrollView.contentOffset.x];
		[self refreshAllTileColors];
	} else if (scrollView == self.tilesScrollView) {
		[self updateScrollLeftRightButtons];
	}
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (scrollView == self.colorPalettesScrollView) {
		[self selectColorPaletteBasedOnContentOffset:scrollView.contentOffset.x];
		[self refreshAllTileColors];
	} else if (scrollView == self.tilesScrollView) {
		[self updateScrollLeftRightButtons];
	}
}


#pragma mark -
#pragma mark Undo/Redo notifications
- (void)managedObjectContextUndoManagerDidUndo:(NSNotification *)notification {
    // only accept notifications from the MOC's undo managed
    if (notification.object == self.managedObjectContext.undoManager)
        [self.artboardViewUndoManager undo];
}

- (void)managedObjectContextUndoManagerDidRedo:(NSNotification *)notification {
    // only accept notifications from the MOC's undo managed
    if (notification.object == self.managedObjectContext.undoManager)
        [self.artboardViewUndoManager redo];
}

#pragma mark -
#pragma mark Undo methods
- (void)undoTileRotate:(NSDictionary*)undoRotateDictionary {
    // disable gesture recognizers until animation completes
    [self enableArtboardGestureRecognizers:NO];
    
    // normally we could query the Undo Manager itself to see if it is undoing or redoing, but in our case we want to know in another thread (in a CAAnimation delegate method), so there needs to be another flag that is unset later
    self.isUndoingOrRedoing = YES;
    
    // mark the tile as moving so that Artboard View does not redraw it
    TileView *rotatingTile = [undoRotateDictionary objectForKey:ArtboardTileViewToRotateKey];
    self.artboardView.currentlyMovingTile = rotatingTile.placedTile;
    
    // reverse direction
	int direction = -[[undoRotateDictionary objectForKey:@"rotations"] intValue];
	
    // register the redo
    NSMutableDictionary *redoRotateDictionary = [NSMutableDictionary dictionaryWithDictionary:undoRotateDictionary];
    [redoRotateDictionary setObject:@(direction) forKey:@"rotations"];
    [self.artboardViewUndoManager registerUndoWithTarget:self selector:@selector(undoTileRotate:) object:redoRotateDictionary];
    
    // do the rotation
    [self rotateWithTileViews:undoRotateDictionary direction:direction];
}

- (void)undoTileMove:(NSDictionary*)undoMoveDictionary {
    // disable gesture recognizers until animation completes
    [self enableArtboardGestureRecognizers:NO];
        
    int destinationGridX = [[undoMoveDictionary objectForKey:@"gridX"] intValue];
    int destinationGridY = [[undoMoveDictionary objectForKey:@"gridY"] intValue];
    
    // if this is a redo, temporarily put a tile view over the Artboard for in place of the tile that will be covered. This is to cover the "hole" that would be shown momentarily after the Artboard is redrawn w/o the tile about to be covered in place 
    ArtboardTile *tileToBeCovered = [undoMoveDictionary objectForKey:@"tileToBeCovered"];
    NSNumber *orientation = [undoMoveDictionary objectForKey:@"tileToBeCoveredOrientation"];
    TileView *tileViewToBeCovered;
    if (tileToBeCovered) {
        tileViewToBeCovered = [self.artboardView tileViewForArtboardTile:tileToBeCovered toBeCoveredAtGridPoint:CGPointMake(destinationGridX, destinationGridY) withOrientation:[orientation intValue]];
        CGPoint centerInSuperView = [self.view convertPoint:tileViewToBeCovered.center fromView:self.artboardView];
        tileViewToBeCovered.center = centerInSuperView;
        
        [self.view addSubview:tileViewToBeCovered];
    }
    
    // mark as moving so that it's not redrawn
    TileView *tileView = [undoMoveDictionary objectForKey:@"tileView"];
    self.artboardView.currentlyMovingTile = tileView.placedTile;
	[self.artboardView redrawArtboardImage];
    
    // mark as setNeedsDisplay in case color palette had been changed
    [tileView setNeedsDisplay];
    
    // add back to view
    [self.view addSubview:tileView];
    
    // register the redo  
    CGPoint tileViewCenterInArtboard = [self.artboardView convertPoint:tileView.center fromView:self.view];
    int gridX = tileViewCenterInArtboard.x / ArtboardTileSize;
    int gridY = tileViewCenterInArtboard.y / ArtboardTileSize;
    NSMutableDictionary *redoDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:tileView, @"tileView", @(gridX), @"gridX", @(gridY), @"gridY", nil];
        
    // switch the values for replacedTile (which is more or less ignored during an undo) with tileToBeCovered (needed to make a redo look correct)
    if (tileToBeCovered) {
        [redoDictionary setObject:tileToBeCovered forKey:@"replacedTile"];
    } 
    id replacedTile = [undoMoveDictionary objectForKey:@"replacedTile"];
    if (replacedTile) {
        [redoDictionary setObject:replacedTile forKey:@"tileToBeCovered"];
    }
    
    // copy orientation if present, only will be used on redos
    if (orientation) {
        [redoDictionary setObject:orientation forKey:@"tileToBeCoveredOrientation"];
    }
    
    [self.artboardViewUndoManager registerUndoWithTarget:self selector:@selector(undoTileMove:) object:redoDictionary];
    
    // animate move back to original location
    CGPoint destinationInArtboard = [self.artboardView centerForGridX:destinationGridX gridY:destinationGridY];
    CGPoint destination = [self.view convertPoint:destinationInArtboard fromView:self.artboardView];
    [UIView animateWithDuration:ArtboardViewPlaceTileAnimationDuration animations:^{
        tileView.center = destination;
    } completion:^(BOOL finished) {        
 		// Play sound effect
		[UIAppDelegate.soundEffects playTilePlaceSoundAtX:destinationGridX y:destinationGridY];
		
		[tileView removeFromSuperview];
		self.artboardView.currentlyMovingTile = nil;
		[self.artboardView redrawArtboardImage];
        
        if (tileViewToBeCovered)
            [tileViewToBeCovered removeFromSuperview];
                
        [self enableArtboardGestureRecognizers:YES];
    }];    
}

- (void)undoTileAdd:(NSDictionary*)addDictionary {
 	// Sound effect
    int gridX = [[addDictionary objectForKey:@"gridX"] intValue];
    int gridY = [[addDictionary objectForKey:@"gridY"] intValue];
	[UIAppDelegate.soundEffects playTilePlaceSoundAtX:gridX y:gridY];
	
   // redraw for now
	[self.artboardView redrawArtboardImage];
        
    // register redo
    [self.artboardViewUndoManager registerUndoWithTarget:self selector:@selector(undoTileAdd:) object:addDictionary];
    
    [self updateUndoRedoButtons];
}

- (void)undoTileDelete:(NSDictionary*)deleteDictionary {
	// Sound effect
    int gridX = [[deleteDictionary objectForKey:@"gridX"] intValue];
    int gridY = [[deleteDictionary objectForKey:@"gridY"] intValue];
	[UIAppDelegate.soundEffects playTilePlaceSoundAtX:gridX y:gridY];

    // just redraw for now
	[self.artboardView redrawArtboardImage];
    
    // register redo
    [self.artboardViewUndoManager registerUndoWithTarget:self selector:@selector(undoTileDelete:) object:deleteDictionary];
    
    [self updateUndoRedoButtons];
}

@end

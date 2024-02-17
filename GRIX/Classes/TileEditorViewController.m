//
//  TileEditorViewController.m
//  eboy
//
//  Created by Brian Papa on 8/9/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import "TileEditorViewController.h"
#import "SelectedColorView.h"
#import "ColorPalette.h"
#import "TileEditCanvasView.h"
#import "ArtboardTile.h"
#import "eboyAppDelegate.h"
#import "UIView+Setup.h"
#import "EditTileStoryboardSegue.h"

const NSTimeInterval TileEditorColorSwitchDuration = 0.25;
const NSTimeInterval TileEditorTapSelectedColorDisplayDuration = 0.250;
const NSTimeInterval TileEditorSelectedColorAnimationDuration = 2.0;

@implementation TileEditorViewController

#pragma mark - Class methods

+ (NSInteger)selectedColorIndexUserDefault {
	// default selected color to first
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults objectForKey:@"selectedColorIndex"]) {
		return [defaults integerForKey:@"selectedColorIndex"];
	}
	return 1;
}

+ (BOOL)enableEraseModeUserDefault {
	// default selected color to first
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults objectForKey:@"enableEraseMode"]) {
		return [defaults integerForKey:@"enableEraseMode"];
	}
	return NO;
}

+ (BOOL)enableLargeColorSelectorUserDefault {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults objectForKey:@"enableLargeColorSelector"]) {
		return [defaults integerForKey:@"enableLargeColorSelector"];
	}
	return YES;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	// set these since we aren't using a standard UIToolbar, and to prevent Tile edits at the same time that a button is pressed
	[self.topToolbar setupSubviewsToBePixelatedAndExclusiveTouch];
	self.canvasView.exclusiveTouch = YES;
	[self.colorPickerView setupSubviewsToBePixelatedAndExclusiveTouch];
	
	// set up canvas view
	self.canvasView.artboardTile = self.artboardTile;
	UIPanGestureRecognizer *canvasPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleCanvasPanGestureRecognizer:)];
	canvasPanGestureRecognizer.maximumNumberOfTouches = 1;
	UITapGestureRecognizer *canvasTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleCanvasTapGestureRecognizer:)];
	[self.canvasView addGestureRecognizer:canvasPanGestureRecognizer];
	[self.canvasView addGestureRecognizer:canvasTapGestureRecognizer];
	
	// add undo manager to managed object context, remove when view is unloaded
	NSUndoManager *undoManager = [[NSUndoManager alloc] init];
	self.managedObjectContext.undoManager = undoManager;
	[self updateUndoRedoButtons];
	
	// Color picker area
	[self addColorPickerViews:self.colorPickerView];
	for (UIView *colorView in self.colorPickerView.subviews) {
		UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapColorRecognizer:)];
		[colorView addGestureRecognizer:tapGestureRecognizer];
	}
	
	UILongPressGestureRecognizer *colorPickerLongPressGesturerRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleColorPickerLongPressGestureRecognizer:)];
	colorPickerLongPressGesturerRecognizer.allowableMovement = CGFLOAT_MAX;
	colorPickerLongPressGesturerRecognizer.minimumPressDuration = 0.2;
	[self.colorPickerView addGestureRecognizer:colorPickerLongPressGesturerRecognizer];
	
	self.selectedColorIndex = [TileEditorViewController selectedColorIndexUserDefault];
	
	// Selected color overlay animated images
	NSMutableArray *animation = [NSMutableArray arrayWithCapacity:30];
	int i;
	for (i = 0; i <= 15; i++) {
		[animation addObject:[UIImage imageNamed:[NSString stringWithFormat:@"color-selector-%d", i]]];
	}
	for (i = 14; i >= 1; i--) {
		[animation addObject:[UIImage imageNamed:[NSString stringWithFormat:@"color-selector-%d", i]]];
	}
	self.selectedColorOverlayView = [[UIImageView alloc] initWithImage:[UIImage animatedImageWithImages:animation duration:TileEditorSelectedColorAnimationDuration]];
	UIView *selectedView = [self.colorPickerView.subviews objectAtIndex:self.selectedColorIndex];
	self.selectedColorOverlayView.frame = selectedView.frame;
	self.selectedColorOverlayView.alpha = 0.875;
	[self.colorPickerView addSubview:self.selectedColorOverlayView];
	
	[self layoutColorPickerViews];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	self.colorPalette = [ColorPalette selectedColorPalette:self.managedObjectContext];
	[self layoutColorPickerViews];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:self.selectedColorIndex forKey:@"selectedColorIndex"];
	
	[UIAppDelegate saveContext];
}

#pragma mark -  Actions

- (IBAction)back:(id)sender {
    UIViewController *previousViewController = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count - 2];
    EditTileStoryboardSegue *segue = [[EditTileStoryboardSegue alloc] initWithIdentifier:@"showTileEditor" source:self destination:previousViewController];
    [segue perform];
}

- (IBAction)undo:(id)sender {
	[self.managedObjectContext undo];
    [self updateUndoRedoButtons];
    [self.canvasView setNeedsDisplay];
	[UIAppDelegate.soundEffects playPaintSoundAtX:0 y:0];
}

- (IBAction)redo:(id)sender {
	[self.managedObjectContext redo];
    [self updateUndoRedoButtons];
    [self.canvasView setNeedsDisplay];
	[UIAppDelegate.soundEffects playPaintSoundAtX:0 y:0];
}

- (void)updateUndoRedoButtons {
	self.undoButton.enabled = [self.managedObjectContext.undoManager canUndo];
	self.redoButton.enabled = [self.managedObjectContext.undoManager canRedo];
}

- (void)addColorPickerViews:(UIView*)aColorPickerView {
	NSArray *paletteColorIndex = [ColorPalette selectedColorPalette:self.managedObjectContext].colorIndex;
	
	// set up picker views with colors
	for (int i = 0; i < aColorPickerView.subviews.count; i++) {
		UIView *colorView = [aColorPickerView.subviews objectAtIndex:i];
		UIColor *backgroundColor = [paletteColorIndex objectAtIndex:i];
		colorView.backgroundColor = backgroundColor;
	}
}

- (void)layoutColorPickerViews {
	// Adjust the size of the color palette squares.
	CGFloat top = 0.0;
	CGFloat bottom = self.colorPickerView.bounds.size.height;
	CGFloat middle = (top + bottom) / 2.0;
	CGFloat height = middle;
	NSInteger index = 0;
	
	for (UIView *colorView in self.colorPickerView.subviews) {
		CGRect box = colorView.frame;
		if (index < 8) {
			box.origin.y = top;
			box.size.height = height;
		} else {
			box.origin.y = middle;
			box.size.height = height;
		}
		colorView.frame = box;
		index++;
	}
}

- (SelectedColorView*)selectedColorViewForIndex:(NSInteger)index {
	const CGFloat kIndicatorWidth = 80.0;
	const CGFloat kIndicatorHeight = 90.0;
	const CGFloat kIndicatorOverlap = 10.0;
	const CGFloat kIndicatorShadowOffset = 10.0;
    UIView *tappedView = [self.colorPickerView.subviews objectAtIndex:index];
    
    // determine the style for the selected color view based on which view this is
    SelectedColorViewStyle style;
    CGFloat frameOriginX;
    if (index == 0 || index == 8) {
        style = SelectedColorViewStyleLeftEdge;
        frameOriginX = -kIndicatorShadowOffset;
    } else if (index == 7 || index == 15) {
        style = SelectedColorViewStyleRightEdge;
        frameOriginX = self.view.frame.size.width - kIndicatorWidth + kIndicatorShadowOffset;
    } else {
        style = SelectedColorViewStyleCentered;
        frameOriginX = tappedView.frame.origin.x - ((kIndicatorWidth - tappedView.frame.size.width) / 2);
    }
    
    // create the selected color view
    CGRect selectedColorFrame = CGRectMake(frameOriginX, tappedView.frame.origin.y - kIndicatorHeight + kIndicatorOverlap, kIndicatorWidth, kIndicatorHeight);
    SelectedColorView *aSelectedColorView = [[SelectedColorView alloc] initWithFrame:selectedColorFrame color:tappedView.backgroundColor style:style];
    return aSelectedColorView;
}

- (void)selectColorAtIndex:(NSInteger)index {
	// == Common code for changing the selected color ==
	
	// Update domain.
	self.selectedColorIndex = index;
	// Move selected color overlay view
    UIView *selectedView = [self.colorPickerView.subviews objectAtIndex:self.selectedColorIndex];
	self.selectedColorOverlayView.frame = selectedView.frame;
}

- (UIView*)viewForSelectedColorViewForIndex:(NSInteger)index {
    // this may be a selectedcolorview or a plain uiview depending on user color picker preference
    UIView *aColorView;
    if (![TileEditorViewController enableLargeColorSelectorUserDefault]) {
        aColorView = [self selectedColorViewForIndex:index];
    } else {
        aColorView = [[UIView alloc] initWithFrame:self.colorPickerView.bounds];
        UIView *tappedView = [self.colorPickerView.subviews objectAtIndex:index];
        aColorView.backgroundColor = tappedView.backgroundColor;
    }
    
    return aColorView;
}

- (IBAction)handleTapColorRecognizer:(UITapGestureRecognizer*)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        
        // determine which view was tapped and update
        UIView *tappedView = sender.view;
        NSInteger index = [self.colorPickerView.subviews indexOfObject:tappedView];
    
        // create the selected color view depending on user setting
        UIView *aSelectedColorView = [self viewForSelectedColorViewForIndex:index];
        [self.colorPickerView addSubview:aSelectedColorView];    
                
        // remove it after a short delay
		[aSelectedColorView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:TileEditorTapSelectedColorDisplayDuration];
		
		[self selectColorAtIndex:index];

		// Sound
		[UIAppDelegate.soundEffects playSelectColorSound];
	}
}

- (IBAction)handleColorPickerLongPressGestureRecognizer:(UIPanGestureRecognizer*)sender {
    CGPoint pressLocation = [sender locationInView:self.colorPickerView];
    if (!CGRectContainsPoint(self.colorPickerView.frame, pressLocation))
        sender.cancelsTouchesInView = YES;
    else {
        int pressLocationY = pressLocation.y / (self.colorPickerView.frame.size.height / 2);
        int pressLocationX = pressLocation.x / (self.colorPickerView.frame.size.width / 8);
		if (pressLocationY < 0) pressLocationY = 0;
		if (pressLocationY > 1) pressLocationY = 1;
		if (pressLocationX < 0) pressLocationX = 0;
		if (pressLocationX > 7) pressLocationX = 7;
        int pressIndex = (pressLocationY * 8) + pressLocationX;
        
        if (sender.state == UIGestureRecognizerStateBegan) {
            // remove the old selected color and add new one
            [self.selectedColorView removeFromSuperview];
            self.selectedColorView = [self viewForSelectedColorViewForIndex:pressIndex];
            [self.colorPickerView addSubview:self.selectedColorView];
            
			[self selectColorAtIndex:pressIndex];
 
			// Sound
			[UIAppDelegate.soundEffects playSelectColorSound];
		} else if (sender.state == UIGestureRecognizerStateChanged) {
            // change the existing color view as needed
            if (self.selectedColorIndex != pressIndex) {                
				// remove the old selected color and add new one
                [self.selectedColorView removeFromSuperview];
                self.selectedColorView = [self viewForSelectedColorViewForIndex:pressIndex];
                [self.colorPickerView addSubview:self.selectedColorView];
                            
				[self selectColorAtIndex:pressIndex];
				
				// Sound
				[UIAppDelegate.soundEffects playChangeColorSound];
            }
        } 
    }
    
    if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled) {
        [self.selectedColorView removeFromSuperview];
        self.selectedColorView = nil;
    }
}

- (void)setColor:(NSInteger)colorValue x:(int)x y:(int)y {
	// Do not remove this code that checks whether the new color is different from the old color. --Lucius
	int oldColor = [self.artboardTile pixelValueAtRow:y col:x];
	if (colorValue != oldColor) {
		[self.artboardTile setPixelValue:(int)colorValue atRow:y col:x];
		[self.canvasView setNeedsDisplay];
		[self updateUndoRedoButtons];
		[UIAppDelegate.soundEffects playPaintSoundAtX:x y:y];
	}
}

- (NSInteger)colorForStartingPaintingAtX:(int)x y:(int)y {
	NSInteger color = self.selectedColorIndex;
	if ([TileEditorViewController enableEraseModeUserDefault]) {
		// Determine which color to use for the current gesture, whether to use the selected color or the erase color.
		int oldColor = [self.artboardTile pixelValueAtRow:y col:x];
		if (color == oldColor)
			color = 0;
	}
	return color;
}

- (CGRect)canvasBounds {
	return CGRectMake(0.0, 0.0, 319.0, 319.0);
}

- (void)colorPaletteDidCycle:(ColorPalette*)palette {
	// Empty
}

#pragma mark - Gesture recognizer

- (IBAction)handleCanvasTapGestureRecognizer:(UIGestureRecognizer*)sender {
	CGPoint pressLocation = [sender locationInView:self.canvasView];
	if (CGRectContainsPoint([self canvasBounds], pressLocation)) {
		// change the color depending on current canvas color, either currently selected or "erase" to black
		CGPoint grid = gridForUnitAtPoint(pressLocation);
		NSInteger newColor = [self colorForStartingPaintingAtX:grid.x y:grid.y];
		[self setColor:newColor x:grid.x y:grid.y];
	}
}

- (IBAction)handleCanvasPanGestureRecognizer:(UIGestureRecognizer*)sender {
	CGPoint pressLocation = [sender locationInView:self.canvasView];
	CGPoint grid = gridForUnitAtPoint(pressLocation);
	if (CGRectContainsPoint([self canvasBounds], pressLocation)) {
		if (sender.state == UIGestureRecognizerStateBegan) {
			// mostly the same as tap, but currently panned unit and whether or not it is in "erase" mode need to be recorded
			CGPoint grid = gridForUnitAtPoint(pressLocation);
			self.gestureColorIndex = [self colorForStartingPaintingAtX:grid.x y:grid.y];
			[self setColor:self.gestureColorIndex x:grid.x y:grid.y];
			
		} else if (sender.state == UIGestureRecognizerStateChanged) {
			[self setColor:self.gestureColorIndex x:grid.x y:grid.y];
		}
	}
	if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled) {
		// Do nothing.
	}
}

#pragma mark - For Development Only

- (IBAction)logTileDataForPalettes:(id)sender {
	// Print out a string of hexadecimal values which encode the pixel values in the tile.
	
	NSArray *pixels = self.artboardTile.colorsIndex;
	if (pixels != nil) {
		if (pixels.count == 64) {
			NSMutableString *s = [[NSMutableString alloc] initWithCapacity:64];
			for (NSNumber *n in pixels) {
				[s appendFormat:@"%x", [n intValue]];
			}
			NSLog(@"Tile data: %@", s);
		} else {
			NSLog(@"tile.colorsIndex.count is not 64.");
		}
	} else {
		NSLog (@"No tile.");
	}
}

@end

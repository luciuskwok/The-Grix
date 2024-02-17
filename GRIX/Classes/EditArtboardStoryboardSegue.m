//
//  EditArtboardStoryboardSegue.m
//  eboy
//
//  Created by Brian Papa on 9/27/11.
//  Copyright (c) 2011 Felt Tip Inc. All rights reserved.
//

#import "EditArtboardStoryboardSegue.h"
#import "ArtboardViewController.h"
#import "ViewerViewController.h"
#import "Artboard.h"
#import "ArtboardTilePalette.h"
#import "eboyAppDelegate.h"
#import <QuartzCore/QuartzCore.h>

const NSTimeInterval SegueEditArtboardDuration = 0.5;
const CGFloat SegueEditArtboardLockAnimationFactor = 1.1;

@implementation EditArtboardStoryboardSegue

- (NSArray*)lockImagesArray {
	NSMutableArray *array = [NSMutableArray array];
	int i;
	for (i=0; i<=30; i+=2) {
		[array addObject:[UIImage imageNamed:[NSString stringWithFormat:@"lock%d", i]]];
	}
	return array;
}

- (void)transitionFromViewer:(ViewerViewController *)viewer toEditor:(ArtboardViewController *)editor {
	// == Animate from Viewer to Editor ==
	
	// Cause editor view to load. 
	// ==== Critical timing area: initial load 0.227s, subsequent 0.112s to 0.181s. ==== 
	[editor view];
	// ==== End critical timing area ====
	
	// Adjust for iPhone 5 screen.
	BOOL tallScreen = viewer.view.bounds.size.height > 480.0;

	// Hide the existing lock buttons.
	viewer.lockButton.hidden = YES;
	editor.lockButton.hidden = YES;
	
	// Animate position of artboard for tall screen.
	CGRect artboardOldFrame = viewer.artboardsScrollView.frame;
	CGRect artboardEnd = viewer.artboardsScrollView.frame;
	if (tallScreen) {
		artboardEnd.origin.y += 80;
	}
	
	// Editor's top toolbar dissolves in. Timing: 0.006s to 0.009s.
	UIImageView *topToolbar = [self imageViewOfView:editor.topToolbar withTopLevelView:editor.view];
	topToolbar.alpha = 0.0;
	[viewer.view addSubview:topToolbar];
	
	// While viewer's top toolbar slides up.
	CGRect topToolbarStart = viewer.topToolbar.frame;
	CGRect topToolbarEnd = viewer.topToolbar.frame;
	if (tallScreen) {
		topToolbarEnd.origin.y -= 80;
	}
	
	// In a tall screen, the color picker needs to be visible in this transition.
	UIImageView *colorPicker = nil;
	CGRect colorPickerEnd = CGRectZero;
	if (tallScreen) {
		colorPicker = [self imageViewOfView:editor.colorPalettesScrollView withTopLevelView:editor.view];
		[viewer.view insertSubview:colorPicker belowSubview:viewer.topToolbar];
		colorPickerEnd = colorPicker.frame;
		CGRect colorPickerStart = colorPicker.frame;
		colorPickerStart.origin.y -= 80;
		colorPicker.frame = colorPickerStart;
	}
	
	// Add an animated UIImageView to unlock the lock.
	// ==== Critical timing area: inital 0.160s, subsequent 0.006s. ==== 
	UIImageView *unlockImage = [[UIImageView alloc] initWithFrame:CGRectMake(287.0, 1.0, 35.0, 30.0)];
	unlockImage.layer.magnificationFilter = kCAFilterNearest;
	unlockImage.image = [UIImage imageNamed:@"lock30"];
	unlockImage.animationImages = [self lockImagesArray];
	unlockImage.animationRepeatCount = 1;
	// make it a little faster than the tileboard animation to ensure it finishes before changing
	unlockImage.animationDuration = SegueEditArtboardDuration / SegueEditArtboardLockAnimationFactor;
	[viewer.view addSubview:unlockImage];
	[unlockImage startAnimating];
	// ==== End critical timing area ====
	
	// Bottom toolbar slides away.
	CGRect bottomToolbarStart = viewer.bottomToolbarContainer.frame;
	CGRect bottomToolbarEnd = viewer.bottomToolbarContainer.frame;
	bottomToolbarEnd.origin.y = viewer.view.bounds.size.height;
	
	// And reveals the existing tile picker. 
	// ==== Critical timing area: initial 0.390s, subsequent 0.203s to 0.345s. ==== 
	//			With changes to draw the tile as a UIImage: all are 0.268s to 0.271s.
	UIImageView *tilePicker = [self imageViewOfView:editor.tileboardView withTopLevelView:editor.view];
	CGRect tilePickerStart = tilePicker.frame;
	tilePickerStart.origin.y = viewer.bottomToolbarContainer.frame.origin.y;
	tilePicker.frame = tilePickerStart;
	CGRect tilePickerEnd = tilePickerStart;
	if (tallScreen)
		tilePickerEnd.origin.y += 80;
	[viewer.view insertSubview:tilePicker belowSubview:viewer.bottomToolbarContainer];
	// ==== End critical timing area ====
	
	// Disable UI interaction during animation.
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	// == Animation Block ==
	// Timing: Consistently 0.003s. 
	[UIView animateWithDuration:SegueEditArtboardDuration animations:^{
		viewer.bottomToolbarContainer.frame = bottomToolbarEnd;
		topToolbar.alpha = 1.0;
		viewer.topToolbar.frame = topToolbarEnd;
		if (tallScreen) {
			viewer.artboardsScrollView.frame = artboardEnd;
			colorPicker.frame = colorPickerEnd;
			tilePicker.frame = tilePickerEnd;
		}
	} completion:^(BOOL finished) {
		[viewer.navigationController pushViewController:editor animated:NO];
		[topToolbar removeFromSuperview];
		[tilePicker removeFromSuperview];
		[unlockImage removeFromSuperview];
		[colorPicker removeFromSuperview];
		viewer.lockButton.hidden = NO;
		editor.lockButton.hidden = NO;
		viewer.bottomToolbarContainer.frame = bottomToolbarStart;
		viewer.topToolbar.frame = topToolbarStart;
		viewer.artboardsScrollView.frame = artboardOldFrame;
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
	}];
	
	// Play sound effect for lock
	[UIAppDelegate.soundEffects playUnlockSound];
	
}

- (void)transitionFromEditor:(ArtboardViewController *)editor toViewer:(ViewerViewController *)viewer {
	// == Animate from Editor to Viewer ==
	
	// Cause viewer view to load.
	[viewer view];
	
	// Adjust for iPhone 5 screen.
	BOOL tallScreen = viewer.view.bounds.size.height > 480.0;
	
	// Hide the existing lock buttons.
	viewer.lockButton.hidden = YES;
	editor.lockButton.hidden = YES;
	
	CGRect artboardEnd = viewer.artboardsScrollView.frame;

	// Top toolbar slides in from top, except for lock image.
	UIImageView *topToolbar = [self imageViewOfView:viewer.topToolbar withTopLevelView:viewer.view];
	topToolbar.contentMode = UIViewContentModeLeft;
	CGRect topToolbarEnd = viewer.topToolbar.frame;
	if (tallScreen) {
		CGRect topToolbarStart = viewer.topToolbar.frame;
		topToolbarStart.origin.y -= 80.0;
		topToolbar.frame = topToolbarStart;
	} else {
		topToolbar.alpha = 0.0;
	}
	[editor.view addSubview:topToolbar];
	
	// animate the locking of the lock
	UIImageView *lockImage = [[UIImageView alloc] initWithFrame:CGRectMake(287.0, 1.0, 35.0, 30.0)];
	lockImage.layer.magnificationFilter = kCAFilterNearest;
	lockImage.image = [UIImage imageNamed:@"lock0"];
	lockImage.animationImages = [[[self lockImagesArray] reverseObjectEnumerator] allObjects];
	lockImage.animationRepeatCount = 1;
	lockImage.animationDuration = SegueEditArtboardDuration / SegueEditArtboardLockAnimationFactor;
	[lockImage startAnimating];
	[editor.view addSubview:lockImage];
	
	// Create a snapshot of the bottom toolbar
	UIImageView *bottomToolbar = [self imageViewOfView:viewer.bottomToolbarContainer withTopLevelView:viewer.view];
	CGFloat top = viewer.artboardsScrollView.frame.origin.y + viewer.artboardsScrollView.frame.size.height;
	CGRect bottomToolbarStart = bottomToolbar.frame;
	bottomToolbarStart.origin.y = editor.view.frame.size.height;
	bottomToolbarStart.size.height = viewer.view.bounds.size.height - top;
	CGRect bottomToolbarEnd = bottomToolbarStart;
	bottomToolbarEnd.origin.y -= bottomToolbarEnd.size.height;
	bottomToolbar.frame = bottomToolbarStart;
	[editor.view addSubview:bottomToolbar];
	
	// Disable UI interaction during animation.
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	// == Animation Block ==
	[UIView animateWithDuration:SegueEditArtboardDuration animations:^ {
		editor.mainScrollView.contentOffset = CGPointMake(0.0, 80.0);
		bottomToolbar.frame = bottomToolbarEnd;
		topToolbar.frame = topToolbarEnd;
		topToolbar.alpha = 1.0;
		viewer.artboardsScrollView.frame = artboardEnd;
	} completion:^(BOOL success) {
		[editor.navigationController popViewControllerAnimated:NO];
		[bottomToolbar removeFromSuperview];
		[topToolbar removeFromSuperview];
		[lockImage removeFromSuperview];
		viewer.lockButton.hidden = NO;
		editor.lockButton.hidden = NO;
		viewer.galleryButton.alpha = 1.0;
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
	}];
	
	// Play sound effect for lock
	[UIAppDelegate.soundEffects playLockSound];
	
}

- (void)perform {
    if ([self.sourceViewController isKindOfClass:[ViewerViewController class]] && [self.destinationViewController isKindOfClass:[ArtboardViewController class]]) {
		[self transitionFromViewer:self.sourceViewController toEditor:self.destinationViewController];
    } else if ([self.sourceViewController isKindOfClass:[ArtboardViewController class]] && [self.destinationViewController isKindOfClass:[ViewerViewController class]]) {
		[self transitionFromEditor:self.sourceViewController toViewer:self.destinationViewController];
   }
}

@end
